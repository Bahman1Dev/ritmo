import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/logic/goal_progress_calculator.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

class GoalsEngineInput {

  GoalsEngineInput({
    required this.goals,
    required this.stepsByGoal,
    required this.courses,
    required this.courseSessions,
    required this.konkurSubjects,
    required this.konkurTopics,
    required this.konkurPlanItems,
    required this.routineCompletions,
    required this.today,
    this.horizonDays = 14,
  });
  final List<Goal> goals;
  final Map<String, List<GoalStep>> stepsByGoal;
  final List<Course> courses;
  final List<CourseSession> courseSessions;
  final List<KonkurSubject> konkurSubjects;
  final List<KonkurTopic> konkurTopics;
  final List<KonkurPlanItem> konkurPlanItems;
  final List<Map<String, dynamic>> routineCompletions;
  final DateTime today;
  final int horizonDays;
}

class LinkedRoutineStatus {

  LinkedRoutineStatus({required this.doneCount, required this.streak});
  final int doneCount;
  final int streak;
}

class GoalsEngineOutput {

  GoalsEngineOutput({
    required this.goalProgress,
    required this.todaySteps,
    required this.upcomingTimeline,
    required this.overdueSteps,
    required this.linkedRoutineStatus,
    required this.activeGoalsCount,
    required this.completedGoalsCount,
  });
  final Map<String, double> goalProgress;
  final List<GoalStep> todaySteps;
  final List<TimelineItem> upcomingTimeline;
  final List<GoalStep> overdueSteps;
  final Map<String, LinkedRoutineStatus> linkedRoutineStatus;
  final int activeGoalsCount;
  final int completedGoalsCount;
}

class GoalsEngine implements CachedEngine<GoalsEngineInput, GoalsEngineOutput> {
  GoalsEngineOutput? _cachedOutput;
  String? _cacheKey;

  String _buildCacheKey(GoalsEngineInput input) {
    final todayStr = input.today.toIso8601String().substring(0, 10);
    final goalsHash = input.goals.fold<int>(0, (acc, g) => acc ^ g.id.hashCode ^ g.updatedAt.hashCode ^ g.status.hashCode);
    final stepsCount = input.stepsByGoal.values.fold<int>(0, (acc, list) => acc + list.length);
    return '$todayStr|${input.goals.length}|$stepsCount|${input.horizonDays}|$goalsHash';
  }

  @override
  void invalidate() {
    _cachedOutput = null;
    _cacheKey = null;
  }

  @override
  bool canRun(GoalsEngineInput input) {
    return _cachedOutput == null || _buildCacheKey(input) != _cacheKey;
  }

  @override
  List<Type> dependencies() => [];

  @override
  Future<GoalsEngineOutput> calculate(GoalsEngineInput input) async {
    final currentKey = _buildCacheKey(input);
    if (_cachedOutput != null && _cacheKey == currentKey) {
      return _cachedOutput!;
    }

    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);
    final endStr = _formatDateIso(cleanToday.add(Duration(days: input.horizonDays)));

    final activeGoals = input.goals.where((g) => g.status == 'ACTIVE').toList();
    final activeGoalIds = activeGoals.map((g) => g.id).toSet();

    // 1. Calculate progress for all goals
    final progressMap = <String, double>{};
    for (final goal in input.goals) {
      progressMap[goal.id] = goalProgress(goal.id, input.goals, input.stepsByGoal);
    }

    // 2. todaySteps
    final todayS = <GoalStep>[];
    for (final entry in input.stepsByGoal.entries) {
      if (activeGoalIds.contains(entry.key)) {
        for (final step in entry.value) {
          if (step.scheduledDate == todayStr) {
            todayS.add(step);
          }
        }
      }
    }

    // 3. overdueSteps
    final overdueS = <GoalStep>[];
    for (final entry in input.stepsByGoal.entries) {
      if (activeGoalIds.contains(entry.key)) {
        for (final step in entry.value) {
          if (!step.isCompleted &&
              step.scheduledDate != null &&
              step.scheduledDate!.isNotEmpty &&
              step.scheduledDate!.compareTo(todayStr) < 0) {
            overdueS.add(step);
          }
        }
      }
    }

    // 4. upcomingTimeline (three sources in the horizon days)
    final timeline = <TimelineItem>[];

    // Source 1: GoalSteps
    for (final entry in input.stepsByGoal.entries) {
      if (activeGoalIds.contains(entry.key)) {
        final goal = activeGoals.firstWhere((g) => g.id == entry.key);
        for (final step in entry.value) {
          final date = step.scheduledDate;
          if (date != null && date.isNotEmpty && date.compareTo(todayStr) >= 0 && date.compareTo(endStr) <= 0) {
            timeline.add(TimelineItem(
              dateIso: date,
              title: step.title,
              source: TimelineSource.goalStep,
              sourceId: step.id,
              isDone: step.isCompleted,
              subtitle: goal.title,
            ));
          }
        }
      }
    }

    // Source 2: CourseSessions
    final activeCourses = input.courses.where((c) => c.status == CourseStatus.active && !c.isArchived).toList();
    final activeCourseIds = activeCourses.map((c) => c.id).toSet();
    for (final session in input.courseSessions) {
      if (activeCourseIds.contains(session.courseId)) {
        final date = session.plannedDate;
        if (date != null && date.isNotEmpty && date.compareTo(todayStr) >= 0 && date.compareTo(endStr) <= 0) {
          final course = activeCourses.firstWhere((c) => c.id == session.courseId);
          timeline.add(TimelineItem(
            dateIso: date,
            title: session.sessionTitle ?? 'جلسه ${session.sessionNumber}',
            source: TimelineSource.courseSession,
            sourceId: session.id,
            isDone: session.isCompleted,
            subtitle: course.title,
          ));
        }
      }
    }

    // Source 3: KonkurPlanItems
    for (final item in input.konkurPlanItems) {
      final date = item.dateIso;
      if (date.compareTo(todayStr) >= 0 && date.compareTo(endStr) <= 0) {
        final topic = input.konkurTopics.firstWhere(
          (t) => t.id == item.topicId,
          orElse: () => KonkurTopic(
            id: '',
            subjectId: '',
            name: 'مبحث نامشخص',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
        final subject = input.konkurSubjects.firstWhere(
          (s) => s.id == item.subjectId,
          orElse: () => KonkurSubject(
            id: '',
            name: 'درس نامشخص',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
        timeline.add(TimelineItem(
          dateIso: date,
          title: topic.name.isNotEmpty ? topic.name : 'مطالعه برنامه ریزی شده',
          source: TimelineSource.konkurPlan,
          sourceId: item.id,
          isDone: item.status == 'DONE',
          subtitle: subject.name,
        ));
      }
    }

    // Sort timeline by dateIso ascending
    timeline.sort((a, b) => a.dateIso.compareTo(b.dateIso));

    // 5. linkedRoutineStatus
    // Pre-group completions by routineId for O(1) lookups (T17 optimization)
    final byRoutineDates = <String, List<String>>{};
    for (final c in input.routineCompletions) {
      final rId = c['routineId'] as String?;
      final rType = c['resultType'] as String?;
      final dateStr = c['completionDate'] as String?;
      if (rId != null && dateStr != null && !['SNOOZED', 'CANNOT_NOW', 'SKIPPED'].contains(rType)) {
        byRoutineDates.putIfAbsent(rId, () => []).add(dateStr);
      }
    }

    final routineStatusMap = <String, LinkedRoutineStatus>{};
    for (final entry in input.stepsByGoal.entries) {
      // T19 Guard: only compute linked routine status for ACTIVE goals
      if (!activeGoalIds.contains(entry.key)) continue;

      for (final step in entry.value) {
        final routineId = step.linkedRoutineId;
        if (routineId != null && routineId.isNotEmpty) {
          final dates = byRoutineDates[routineId] ?? [];
          final streak = _calculateStreak(dates, cleanToday);

          routineStatusMap[step.id] = LinkedRoutineStatus(
            doneCount: dates.length,
            streak: streak,
          );
        }
      }
    }

    final activeGoalsCount = activeGoals.length;
    final completedGoalsCount = input.goals.where((g) => g.status == 'COMPLETED').length;

    final output = GoalsEngineOutput(
      goalProgress: progressMap,
      todaySteps: todayS,
      upcomingTimeline: timeline,
      overdueSteps: overdueS,
      linkedRoutineStatus: routineStatusMap,
      activeGoalsCount: activeGoalsCount,
      completedGoalsCount: completedGoalsCount,
    );

    _cachedOutput = output;
    _cacheKey = currentKey;
    return output;
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _calculateStreak(List<String> dates, DateTime today) {
    if (dates.isEmpty) return 0;
    final uniqueDates = dates.toSet();

    final todayStr = _formatDateIso(today);
    final yesterdayStr = _formatDateIso(today.subtract(const Duration(days: 1)));

    if (!uniqueDates.contains(todayStr) && !uniqueDates.contains(yesterdayStr)) {
      return 0;
    }

    var streak = 0;
    var check = uniqueDates.contains(todayStr) ? today : today.subtract(const Duration(days: 1));

    while (uniqueDates.contains(_formatDateIso(check))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

