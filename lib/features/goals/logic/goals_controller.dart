import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

sealed class GoalsViewState {
  const GoalsViewState();
}

class GoalsLoading extends GoalsViewState {
  const GoalsLoading();
}

class GoalsReady extends GoalsViewState {
  const GoalsReady({
    required this.goals,
    required this.stepsByGoal,
    required this.routines,
    required this.courses,
    required this.engineOutput,
  });

  final List<Goal> goals;
  final Map<String, List<GoalStep>> stepsByGoal;
  final List<RoutineRef> routines;
  final List<Course> courses;
  final GoalsEngineOutput engineOutput;
}

class GoalsEmpty extends GoalsViewState {
  const GoalsEmpty();
}

class GoalsFailed extends GoalsViewState {
  const GoalsFailed(this.error);
  final Object error;
}

class GoalsController extends ChangeNotifier {
  GoalsViewState _state = const GoalsLoading();
  GoalsViewState get state => _state;

  StreamSubscription<RitmoEvent>? _busSub;
  Timer? _debounceTimer;
  final GoalsEngine _engine = GoalsEngine();

  bool _showTreeView = true;
  bool get showTreeView => _showTreeView;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  Set<String> _expandedNodeIds = {};
  Set<String> get expandedNodeIds => _expandedNodeIds;

  void init() {
    _busSub = RitmoEventBus().onEvents.listen(_handleEvent);
    _loadPrefs();
    reload();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _busSub?.cancel();
    super.dispose();
  }

  void _handleEvent(RitmoEvent event) {
    if (event.type == 'RoutineCompleted') {
      final payload = event.payload;
      final rId = payload['routineId'] as String?;
      final dateStr = payload['date'] as String? ?? payload['completionDate'] as String? ?? DateTime.now().toIso8601String().substring(0, 10);
      final resType = payload['resultType'] as String? ?? 'DONE';
      if (rId != null && rId.isNotEmpty) {
        unawaited(GoalsRepository.instance.onRoutineCompleted(
          routineId: rId,
          dateIso: dateStr,
          resultType: resType,
        ));
      }
    }

    switch (event.type) {
      case 'GoalChanged':
      case 'GoalStepToggled':
      case 'RoutineCompleted':
      case 'RoutineSkipped':
      case 'CourseSessionCompleted':
      case 'AgendaItemToggled':
        _scheduleReload();
        break;
    }
  }

  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _engine.invalidate();
      reload(silent: true);
    });
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTreeView = prefs.getBool('goals_view_mode') ?? true;
      _selectedTabIndex = prefs.getInt('goals_last_tab') ?? 0;
      final expandedJson = prefs.getString('goals_expanded_ids');
      if (expandedJson != null && expandedJson.isNotEmpty) {
        final list = jsonDecode(expandedJson) as List<dynamic>;
        _expandedNodeIds = list.cast<String>().toSet();
      }
    } catch (e) {
      debugPrint('[GoalsController] Error loading prefs: $e');
    }
    notifyListeners();
  }

  Future<void> toggleViewMode(bool treeView) async {
    _showTreeView = treeView;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('goals_view_mode', treeView);
    } catch (_) {}
  }

  Future<void> setTabIndex(int index) async {
    _selectedTabIndex = index;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('goals_last_tab', index);
    } catch (_) {}
  }

  Future<void> toggleNodeExpanded(String nodeGoalId) async {
    if (_expandedNodeIds.contains(nodeGoalId)) {
      _expandedNodeIds.remove(nodeGoalId);
    } else {
      _expandedNodeIds.add(nodeGoalId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('goals_expanded_ids', jsonEncode(_expandedNodeIds.toList()));
    } catch (_) {}
  }

  Future<void> reload({bool silent = false, bool force = false}) async {
    if (force) {
      _engine.invalidate();
    }

    if (!silent && _state is! GoalsReady) {
      _state = const GoalsLoading();
      notifyListeners();
    }

    try {
      final repo = GoalsRepository.instance;
      final db = await DatabaseHelper.instance.database;
      final settingsRows = await db.query('app_settings');
      final settings = {for (final row in settingsRows) row['key']! as String: row['value']! as String};

      final coursesEnabled = (settings['module_courses_enabled'] ?? 'true') == 'true';
      final konkurEnabled = (settings['module_study_enabled'] ?? 'true') == 'true';

      // Wave 1: Parallel loading of gated non-dependent resources (T20 / Fixes ه-10)
      final results = await Future.wait([
        repo.getGoals(),
        repo.getGoalSteps(),
        repo.getRoutines(),
        coursesEnabled ? repo.getCourses() : Future.value(<Course>[]),
        coursesEnabled ? repo.getCourseSessions() : Future.value(<CourseSession>[]),
        konkurEnabled ? repo.getKonkurSubjects() : Future.value(<KonkurSubject>[]),
        konkurEnabled ? repo.getKonkurTopics() : Future.value(<KonkurTopic>[]),
        konkurEnabled ? repo.getKonkurPlanItems() : Future.value(<KonkurPlanItem>[]),
      ]);

      final goals = results[0] as List<Goal>;
      final stepsMap = results[1] as Map<String, List<GoalStep>>;
      final routines = results[2] as List<RoutineRef>;
      final courses = results[3] as List<Course>;
      final courseSessions = results[4] as List<CourseSession>;
      final konkurSubjects = results[5] as List<KonkurSubject>;
      final konkurTopics = results[6] as List<KonkurTopic>;
      final konkurPlanItems = results[7] as List<KonkurPlanItem>;

      if (goals.isEmpty) {
        _state = const GoalsEmpty();
        notifyListeners();
        return;
      }

      // Wave 2: Dependent query for routine completions
      final activeGoalIds = goals.where((g) => g.status == 'ACTIVE').map((g) => g.id).toSet();
      final linkedIds = <String>[];
      for (final entry in stepsMap.entries) {
        if (activeGoalIds.contains(entry.key)) {
          for (final step in entry.value) {
            if (step.linkedRoutineId != null && step.linkedRoutineId!.isNotEmpty) {
              linkedIds.add(step.linkedRoutineId!);
            }
          }
        }
      }

      final today = DateTime.now();
      final sinceDateIso = today.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10);
      final completions = await repo.getRoutineCompletions(
        routineIds: linkedIds,
        sinceDateIso: sinceDateIso,
      );

      final input = GoalsEngineInput(
        goals: goals,
        stepsByGoal: stepsMap,
        courses: courses,
        courseSessions: courseSessions,
        konkurSubjects: konkurSubjects,
        konkurTopics: konkurTopics,
        konkurPlanItems: konkurPlanItems,
        routineCompletions: completions,
        today: today,
      );

      final output = await _engine.calculate(input);

      _state = GoalsReady(
        goals: goals,
        stepsByGoal: stepsMap,
        routines: routines,
        courses: courses,
        engineOutput: output,
      );
      notifyListeners();
    } catch (e, st) {
      debugPrint('[GoalsController] Error during reload: $e\n$st');
      _state = GoalsFailed(e);
      notifyListeners();
    }
  }
}
