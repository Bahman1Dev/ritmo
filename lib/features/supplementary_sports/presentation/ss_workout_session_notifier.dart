import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_exercise_model.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_audio_cue_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

enum SSWorkoutSessionStatus {
  preparing,
  countdown,
  exercising,
  changeSides,
  resting,
  completed
}

class SSTtsService {
  SSTtsService._();
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _initialized = false;

  static Future<void> speak(String text) async {
    try {
      if (!_initialized) {
        await _flutterTts.setLanguage('fa-IR');
        await _flutterTts.setPitch(1);
        await _flutterTts.setSpeechRate(0.55);
        _initialized = true;
      }
      await _flutterTts.speak(text);
    } catch (_) {}
  }
}

class SSWorkoutState {

  SSWorkoutState({
    required this.sessionId,
    required this.planId,
    required this.dayName,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.isLoading,
    required this.startedAt,
    required this.isResting,
    required this.isTimerPaused,
    required this.restTotalSeconds,
    required this.restRemainingSeconds,
    required this.restTargetTimestamp,
    required this.elapsedSeconds,
    required this.isShowingFeelingSheet,
    required this.handsFreeMode,
    required this.status,
    required this.timerTargetTimestamp,
    required this.timerTotalSeconds,
    required this.timerRemainingSeconds,
    required this.currentSide,
  });

  factory SSWorkoutState.initial(String planId, String dayName) {
    return SSWorkoutState(
      sessionId: '',
      planId: planId,
      dayName: dayName,
      exercises: const [],
      currentExerciseIndex: 0,
      isLoading: true,
      startedAt: 0,
      isResting: false,
      isTimerPaused: false,
      restTotalSeconds: 90,
      restRemainingSeconds: 90,
      restTargetTimestamp: 0,
      elapsedSeconds: 0,
      isShowingFeelingSheet: false,
      handsFreeMode: false,
      status: SSWorkoutSessionStatus.preparing,
      timerTargetTimestamp: 0,
      timerTotalSeconds: 5,
      timerRemainingSeconds: 5,
      currentSide: 'right',
    );
  }
  final String sessionId;
  final String planId;
  final String dayName;
  final List<SSExerciseChecklistEntry> exercises;
  final int currentExerciseIndex;
  final bool isLoading;
  final int startedAt;
  final bool isResting;
  final bool isTimerPaused;
  final int restTotalSeconds;
  final int restRemainingSeconds;
  final int restTargetTimestamp;
  final int elapsedSeconds;
  final bool isShowingFeelingSheet;
  final bool handsFreeMode;

  // New State Machine properties
  final SSWorkoutSessionStatus status;
  final int timerTargetTimestamp;
  final int timerTotalSeconds;
  final int timerRemainingSeconds;
  final String currentSide;

  SSWorkoutState copyWith({
    String? sessionId,
    String? planId,
    String? dayName,
    List<SSExerciseChecklistEntry>? exercises,
    int? currentExerciseIndex,
    bool? isLoading,
    int? startedAt,
    bool? isResting,
    bool? isTimerPaused,
    int? restTotalSeconds,
    int? restRemainingSeconds,
    int? restTargetTimestamp,
    int? elapsedSeconds,
    bool? isShowingFeelingSheet,
    bool? handsFreeMode,
    SSWorkoutSessionStatus? status,
    int? timerTargetTimestamp,
    int? timerTotalSeconds,
    int? timerRemainingSeconds,
    String? currentSide,
  }) {
    return SSWorkoutState(
      sessionId: sessionId ?? this.sessionId,
      planId: planId ?? this.planId,
      dayName: dayName ?? this.dayName,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isLoading: isLoading ?? this.isLoading,
      startedAt: startedAt ?? this.startedAt,
      isResting: isResting ?? this.isResting,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      restTotalSeconds: restTotalSeconds ?? this.restTotalSeconds,
      restRemainingSeconds: restRemainingSeconds ?? this.restRemainingSeconds,
      restTargetTimestamp: restTargetTimestamp ?? this.restTargetTimestamp,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isShowingFeelingSheet: isShowingFeelingSheet ?? this.isShowingFeelingSheet,
      handsFreeMode: handsFreeMode ?? this.handsFreeMode,
      status: status ?? this.status,
      timerTargetTimestamp: timerTargetTimestamp ?? this.timerTargetTimestamp,
      timerTotalSeconds: timerTotalSeconds ?? this.timerTotalSeconds,
      timerRemainingSeconds: timerRemainingSeconds ?? this.timerRemainingSeconds,
      currentSide: currentSide ?? this.currentSide,
    );
  }
}

class SSWorkoutNotifier extends Notifier<SSWorkoutState> {
  SSWorkoutNotifier(this.key);
  final SSWorkoutPlanKey key;

  Timer? _sessionTimer;
  Timer? _autoDismissFeelingTimer;

  @override
  SSWorkoutState build() {
    ref.onDispose(() {
      _sessionTimer?.cancel();
      _autoDismissFeelingTimer?.cancel();
    });
    return SSWorkoutState.initial(key.planId, key.dayName);
  }

  Future<void> init() async {
    await _initOrRestoreSession();
    _startSessionTimer();
  }

  void dispatch(SSWorkoutIntent intent) {
    switch (intent) {
      case CompleteCurrentSet():
        _completeCurrentSet();
      case SelectFeeling(feeling: final f):
        _selectFeeling(f);
      case DismissFeelingSheet():
        _dismissFeelingSheet();
      case SwapExerciseIntent(newExerciseId: final nId, newExerciseName: final nName):
        unawaited(_swapExercise(nId, nName));
      case SkipRestTimer():
        _skipCurrentTimer();
      case PauseResumeTimer():
        _togglePauseTimer();
      case AddNoteToExercise(note: final note):
        _addNote(note);
      case GoToPreviousExercise():
        _goToPrevious();
      case GoToNextExercise():
        _goToNext();
      case UpdateSetWeightAndReps(setIndex: final idx, weight: final w, reps: final r, rir: final rir):
        _updateSetWeightAndReps(idx, w, r, rir: rir);
      case FinishSession():
        break;
    }
  }

  void toggleHandsFreeMode() {
    state = state.copyWith(handsFreeMode: !state.handsFreeMode);
  }

  void triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  // ─── Main Session Timer (1 tick per second) ───
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isLoading) return;

      // 1. Tick overall elapsed seconds
      if (!state.isTimerPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }

      // 2. Tick active status timer
      if (state.timerTargetTimestamp > 0 && !state.isTimerPaused) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = state.timerTargetTimestamp - now;
        final remaining = (diff / 1000).ceil();

        if (remaining <= 0) {
          state = state.copyWith(timerRemainingSeconds: 0);
          _handleTimerExpiry();
        } else {
          state = state.copyWith(
            timerRemainingSeconds: remaining,
            restRemainingSeconds: state.status == SSWorkoutSessionStatus.resting ? remaining : state.restRemainingSeconds,
          );

          // Tick sound cues
          if (state.status == SSWorkoutSessionStatus.resting && remaining == 3) {
            SsAudioCuePlayer.instance.playCountdownToRest();
          } else if (state.status == SSWorkoutSessionStatus.countdown ||
              (state.status == SSWorkoutSessionStatus.preparing && remaining <= 3)) {
            SsAudioCuePlayer.instance.playTick();
          } else if (state.status == SSWorkoutSessionStatus.exercising) {
            // Check for change sides midpoint
            final entry = state.exercises[state.currentExerciseIndex];
            if (entry.exercise.changeSides == true && state.timerTotalSeconds > 0) {
              final midpoint = (state.timerTotalSeconds / 2).round();
              if (remaining == midpoint && state.currentSide == 'right') {
                state = state.copyWith(currentSide: 'left');
                _triggerChangeSides();
              }
            }
          }
        }
      }
    });
  }

  void _triggerChangeSides() {
    final prevStatus = state.status;
    state = state.copyWith(status: SSWorkoutSessionStatus.changeSides);
    SsAudioCuePlayer.instance.playChangeSides();
    
    // Hold changeSides overlay for 2 seconds, then resume exercising
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == SSWorkoutSessionStatus.changeSides) {
        state = state.copyWith(status: prevStatus);
      }
    });
  }

  void _handleTimerExpiry() {
    switch (state.status) {
      case SSWorkoutSessionStatus.preparing:
        _startCountdown();
      case SSWorkoutSessionStatus.countdown:
        _startExercising();
      case SSWorkoutSessionStatus.exercising:
        _completeCurrentSet();
      case SSWorkoutSessionStatus.resting:
        _startPreparing();
      default:
        break;
    }
  }

  void _skipCurrentTimer() {
    _handleTimerExpiry();
  }

  void _startPreparing() {
    state = state.copyWith(
      status: SSWorkoutSessionStatus.preparing,
      isResting: false,
      timerTotalSeconds: 5,
      timerRemainingSeconds: 5,
      timerTargetTimestamp: DateTime.now().millisecondsSinceEpoch + 5000,
    );
    _saveSessionToPreferences();
  }

  void _startCountdown() {
    state = state.copyWith(
      status: SSWorkoutSessionStatus.countdown,
      timerTotalSeconds: 3,
      timerRemainingSeconds: 3,
      timerTargetTimestamp: DateTime.now().millisecondsSinceEpoch + 3000,
    );
    _saveSessionToPreferences();
  }

  void _startExercising() {
    final entry = state.exercises[state.currentExerciseIndex];
    SsAudioCuePlayer.instance.playGo();
    SSTtsService.speak(entry.exercise.name);

    final isTimed = entry.exercise.durationSeconds > 0;
    if (isTimed) {
      final dur = entry.exercise.durationSeconds;
      state = state.copyWith(
        status: SSWorkoutSessionStatus.exercising,
        currentSide: 'right',
        timerTotalSeconds: dur,
        timerRemainingSeconds: dur,
        timerTargetTimestamp: DateTime.now().millisecondsSinceEpoch + (dur * 1000),
      );
    } else {
      state = state.copyWith(
        status: SSWorkoutSessionStatus.exercising,
        currentSide: 'right',
        timerTotalSeconds: 0,
        timerRemainingSeconds: 0,
        timerTargetTimestamp: 0,
      );
    }
    _saveSessionToPreferences();
  }

  void _startRest(int seconds) {
    final target = DateTime.now().millisecondsSinceEpoch + (seconds * 1000);
    state = state.copyWith(
      status: SSWorkoutSessionStatus.resting,
      isResting: true,
      isTimerPaused: false,
      restTotalSeconds: seconds,
      restRemainingSeconds: seconds,
      restTargetTimestamp: target,
      timerTotalSeconds: seconds,
      timerRemainingSeconds: seconds,
      timerTargetTimestamp: target,
    );
    _saveSessionToPreferences();
  }

  void _togglePauseTimer() {
    if (state.isTimerPaused) {
      final target = DateTime.now().millisecondsSinceEpoch + (state.timerRemainingSeconds * 1000);
      state = state.copyWith(
        isTimerPaused: false,
        timerTargetTimestamp: target,
        restTargetTimestamp: target,
      );
    } else {
      state = state.copyWith(
        isTimerPaused: true,
      );
    }
    _saveSessionToPreferences();
  }

  // ─── Set Completion ───
  void _completeCurrentSet() {
    final entry = state.exercises[state.currentExerciseIndex];
    final curSetIdx = entry.currentSetIndex;
    if (curSetIdx == -1) return;

    final updatedSetRows = List<SetRow>.from(entry.setRows);
    updatedSetRows[curSetIdx] = updatedSetRows[curSetIdx].copyWith(status: SetStatus.done);

    final nextIdx = curSetIdx + 1;
    if (nextIdx < updatedSetRows.length) {
      updatedSetRows[nextIdx] = updatedSetRows[nextIdx].copyWith(status: SetStatus.current);
      final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
      updatedExercises[state.currentExerciseIndex] = entry.copyWith(setRows: updatedSetRows);
      
      state = state.copyWith(exercises: updatedExercises);
      _startRest(updatedSetRows[curSetIdx].restSeconds);
    } else {
      // All sets done for this exercise
      final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
      updatedExercises[state.currentExerciseIndex] = entry.copyWith(
        setRows: updatedSetRows,
        status: ExerciseStatus.done,
      );
      
      state = state.copyWith(
        exercises: updatedExercises,
        isShowingFeelingSheet: true,
      );
      
      _startAutoDismissFeelingTimer();
    }

    _saveSessionToPreferences();
    HapticFeedback.mediumImpact();
  }

  void _startAutoDismissFeelingTimer() {
    _autoDismissFeelingTimer?.cancel();
    _autoDismissFeelingTimer = Timer(const Duration(seconds: 5), () {
      dispatch(const DismissFeelingSheet());
    });
  }

  void _selectFeeling(Feeling feeling) {
    _autoDismissFeelingTimer?.cancel();
    
    final entry = state.exercises[state.currentExerciseIndex];
    final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
    
    updatedExercises[state.currentExerciseIndex] = entry.copyWith(feeling: feeling);

    var nextExIndex = state.currentExerciseIndex;
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      nextExIndex++;
      final nextEntry = updatedExercises[nextExIndex];
      updatedExercises[nextExIndex] = nextEntry.copyWith(status: ExerciseStatus.current);
      state = state.copyWith(
        exercises: updatedExercises,
        currentExerciseIndex: nextExIndex,
        isShowingFeelingSheet: false,
      );
      _startRest(90);
    } else {
      // Session fully finished
      state = state.copyWith(
        exercises: updatedExercises,
        status: SSWorkoutSessionStatus.completed,
        isShowingFeelingSheet: false,
      );
      SsAudioCuePlayer.instance.playWorkoutCompleted();
    }

    _saveSessionToPreferences();
  }

  void _dismissFeelingSheet() {
    _autoDismissFeelingTimer?.cancel();
    
    final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
    var nextExIndex = state.currentExerciseIndex;
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      nextExIndex++;
      final nextEntry = updatedExercises[nextExIndex];
      updatedExercises[nextExIndex] = nextEntry.copyWith(status: ExerciseStatus.current);
      state = state.copyWith(
        currentExerciseIndex: nextExIndex,
        isShowingFeelingSheet: false,
      );
      _startRest(90);
    } else {
      state = state.copyWith(
        status: SSWorkoutSessionStatus.completed,
        isShowingFeelingSheet: false,
      );
      SsAudioCuePlayer.instance.playWorkoutCompleted();
    }
    _saveSessionToPreferences();
  }

  Future<void> _swapExercise(String newExerciseId, String newExerciseName) async {
    final current = state.exercises[state.currentExerciseIndex];
    final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
    
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('ss_exercise', where: 'id = ?', whereArgs: [newExerciseId], limit: 1);
      if (results.isNotEmpty) {
        final row = results.first;
        updatedExercises[state.currentExerciseIndex] = SSExerciseChecklistEntry(
          exercise: SsExerciseModel(
            id: newExerciseId,
            name: newExerciseName,
            category: row['category']?.toString() ?? current.exercise.category,
            equipment: row['equipment']?.toString() ?? current.exercise.equipment,
            instructions: row['instructions']?.toString() ?? current.exercise.instructions,
            changeSides: (row['changeSides'] as int? ?? 0) == 1,
            repsDouble: (row['repsDouble'] as int? ?? 0) == 1,
            repsHint: row['repsHint']?.toString(),
            impact: row['impact'] is num ? (row['impact']! as num).toInt() : 0,
            noisy: row['noisy'] is num ? (row['noisy']! as num).toInt() : 0,
          ),
          referenceSets: current.referenceSets,
          referenceReps: current.referenceReps,
          referenceWeight: current.referenceWeight,
          status: ExerciseStatus.current,
          feeling: current.feeling,
          optionalNote: current.optionalNote,
        );
        state = state.copyWith(exercises: updatedExercises);
        _saveSessionToPreferences();
        
        // Start preparation for the swapped exercise
        _startPreparing();
      }
    } catch (e) {
      debugPrint('Error swapping exercise in notifier: $e');
    }
  }

  void _addNote(String note) {
    final current = state.exercises[state.currentExerciseIndex];
    final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
    updatedExercises[state.currentExerciseIndex] = current.copyWith(optionalNote: note);
    state = state.copyWith(exercises: updatedExercises);
    _saveSessionToPreferences();
  }

  void _goToPrevious() {
    if (state.currentExerciseIndex > 0) {
      final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
      final prevIdx = state.currentExerciseIndex - 1;
      updatedExercises[prevIdx] = updatedExercises[prevIdx].copyWith(status: ExerciseStatus.current);
      state = state.copyWith(
        currentExerciseIndex: prevIdx,
        exercises: updatedExercises,
      );
      _saveSessionToPreferences();
      _startPreparing();
    }
  }

  void _goToNext() {
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
      final nextIdx = state.currentExerciseIndex + 1;
      updatedExercises[nextIdx] = updatedExercises[nextIdx].copyWith(status: ExerciseStatus.current);
      state = state.copyWith(
        currentExerciseIndex: nextIdx,
        exercises: updatedExercises,
      );
      _saveSessionToPreferences();
      _startPreparing();
    }
  }

  // Handle Lifecycle resume to sync timestamps
  void handleLifecycleResumed() {
    if (state.isTimerPaused || state.timerTargetTimestamp == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = state.timerTargetTimestamp - now;
    if (diff <= 0) {
      state = state.copyWith(timerRemainingSeconds: 0);
      _handleTimerExpiry();
    } else {
      state = state.copyWith(
        timerRemainingSeconds: (diff / 1000).ceil(),
        restRemainingSeconds: state.status == SSWorkoutSessionStatus.resting ? (diff / 1000).ceil() : state.restRemainingSeconds,
      );
      _startSessionTimer();
    }
  }

  // Database persistence & restore helper
  Future<void> _initOrRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSessionId = prefs.getString('ss_active_session_id');

      if (activeSessionId != null && prefs.getString('ss_active_plan_id') == state.planId) {
        final savedJson = prefs.getString('ss_active_session_exercises');
        if (savedJson != null) {
          final decoded = jsonDecode(savedJson) as List<dynamic>;
          final restoredList = decoded.map((item) =>
              SSExerciseChecklistEntry.fromMap(Map<String, dynamic>.from(item as Map))).toList();
          
          final savedStatusIdx = prefs.getInt('ss_active_session_status') ?? 0;
          final targetTimestamp = prefs.getInt('ss_active_session_target_timestamp') ?? 0;
          final elapsed = prefs.getInt('ss_active_session_elapsed') ?? 0;
          final isPaused = prefs.getBool('ss_active_session_paused') ?? false;

          state = state.copyWith(
            sessionId: activeSessionId,
            exercises: restoredList,
            currentExerciseIndex: prefs.getInt('ss_active_session_index') ?? 0,
            startedAt: prefs.getInt('ss_active_session_started_at') ?? DateTime.now().millisecondsSinceEpoch,
            status: SSWorkoutSessionStatus.values[savedStatusIdx],
            timerTargetTimestamp: targetTimestamp,
            isTimerPaused: isPaused,
            elapsedSeconds: elapsed,
            isLoading: false,
          );
          return;
        }
      }

      // Initialize New session
      final now = DateTime.now().millisecondsSinceEpoch;
      final newSessionId = 'session_${state.planId}_$now';

      final db = await DatabaseHelper.instance.database;
      final crossRefs = await db.rawQuery('''
        SELECT c.*, e.name, e.category, e.equipment, e.instructions, e.changeSides, e.repsDouble, e.repsHint, e.impact, e.noisy, e.durationSeconds
        FROM ss_workout_exercise_crossref c
        JOIN ss_exercise e ON c.exerciseId = e.id
        WHERE c.planId = ?
        ORDER BY c.orderIndex ASC
      ''', [state.planId]);

      final restOverride = prefs.getInt('ss_tired_rest_override');

      // Fetch the last logged sets for all exercises in this plan to use as default values
      final exerciseIds = crossRefs.map((row) => row['exerciseId'].toString()).toList();
      final lastSetsMap = await _getLastLoggedSetsForExercises(exerciseIds, db);

      final list = <SSExerciseChecklistEntry>[];
      for (var i = 0; i < crossRefs.length; i++) {
        final row = crossRefs[i];
        final exerciseId = row['exerciseId'].toString();
        final refSets = row['targetSets'] as int? ?? 3;
        final refReps = row['targetReps'] as int? ?? 10;
        final refWeight = (row['targetWeight'] as num?)?.toDouble() ?? 0.0;

        final lastLoggedSets = lastSetsMap[exerciseId] ?? [];
        
        final setRows = List.generate(
          refSets,
          (idx) {
            var setWeight = refWeight;
            var setReps = refReps;
            if (idx < lastLoggedSets.length) {
              setWeight = (lastLoggedSets[idx]['weight'] as num).toDouble();
              setReps = (lastLoggedSets[idx]['reps'] as num).toInt();
            } else if (lastLoggedSets.isNotEmpty) {
              setWeight = (lastLoggedSets.last['weight'] as num).toDouble();
              setReps = (lastLoggedSets.last['reps'] as num).toInt();
            }
            return SetRow(
              setNumber: idx + 1,
              weight: setWeight,
              reps: setReps,
              rir: 2,
              restSeconds: restOverride ?? 90,
              status: idx == 0 ? SetStatus.current : SetStatus.pending,
            );
          },
        );

        list.add(SSExerciseChecklistEntry(
          exercise: SsExerciseModel(
            id: row['exerciseId'].toString(),
            name: row['name'].toString(),
            category: row['category'].toString(),
            equipment: row['equipment']?.toString(),
            instructions: row['instructions']?.toString(),
            changeSides: (row['changeSides'] as int? ?? 0) == 1,
            repsDouble: (row['repsDouble'] as int? ?? 0) == 1,
            repsHint: row['repsHint']?.toString(),
            impact: row['impact'] is num ? (row['impact']! as num).toInt() : 0,
            noisy: row['noisy'] is num ? (row['noisy']! as num).toInt() : 0,
            durationSeconds: row['durationSeconds'] as int? ?? 0,
          ),
          referenceSets: refSets,
          referenceReps: refReps,
          referenceWeight: refWeight,
          status: i == 0 ? ExerciseStatus.current : ExerciseStatus.upcoming,
          setRows: setRows,
        ));
      }

      state = state.copyWith(
        sessionId: newSessionId,
        exercises: list,
        startedAt: now,
        status: SSWorkoutSessionStatus.preparing,
        timerTotalSeconds: 5,
        timerRemainingSeconds: 5,
        timerTargetTimestamp: now + 5000,
        isLoading: false,
      );
      await _saveSessionToPreferences();
    } catch (e) {
      debugPrint('Error restoring session: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveSessionToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ss_active_session_id', state.sessionId);
      await prefs.setString('ss_active_plan_id', state.planId);
      await prefs.setInt('ss_active_session_index', state.currentExerciseIndex);
      await prefs.setInt('ss_active_session_started_at', state.startedAt);
      await prefs.setInt('ss_active_session_status', state.status.index);
      await prefs.setInt('ss_active_session_target_timestamp', state.timerTargetTimestamp);
      await prefs.setInt('ss_active_session_elapsed', state.elapsedSeconds);
      await prefs.setBool('ss_active_session_paused', state.isTimerPaused);
      await prefs.setString(
        'ss_active_session_exercises',
        jsonEncode(state.exercises.map((e) => e.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> clearSessionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ss_active_session_id');
    await prefs.remove('ss_active_plan_id');
    await prefs.remove('ss_active_session_exercises');
    await prefs.remove('ss_active_session_index');
    await prefs.remove('ss_active_session_started_at');
    await prefs.remove('ss_active_session_status');
    await prefs.remove('ss_active_session_target_timestamp');
    await prefs.remove('ss_active_session_elapsed');
    await prefs.remove('ss_active_session_paused');
    await prefs.remove('ss_tired_rest_override');
  }

  // Database persistence on session completion
  Future<Map<String, dynamic>> finishAndLogWorkout() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseHelper.instance.database;
      final finishedAt = DateTime.now().millisecondsSinceEpoch;
      final durationSec = ((finishedAt - state.startedAt) / 1000).round();
      final completedCount = state.exercises.where((e) => e.status == ExerciseStatus.done).length;
      final feelingsList = state.exercises.where((e) => e.feeling != null).map((e) => e.feeling!).toList();
      
      Feeling? overallFeeling;
      if (feelingsList.isNotEmpty) {
        final counts = <Feeling, int>{};
        for (final f in feelingsList) { counts[f] = (counts[f] ?? 0) + 1; }
        overallFeeling = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      await db.transaction((txn) async {
        await txn.insert('ss_workout_session_log', {
          'id': state.sessionId,
          'planId': state.planId,
          'startedAt': state.startedAt,
          'finishedAt': finishedAt,
          'durationSeconds': durationSec,
          'completedExercisesCount': completedCount,
          'totalExercisesCount': state.exercises.length,
          'overallFeeling': overallFeeling != null ? _feelingStr(overallFeeling) : null,
        });
        
        for (final entry in state.exercises) {
          if (entry.feeling != null) {
            await txn.insert('ss_exercise_feeling_log', {
              'id': 'feel_${state.sessionId}_${entry.exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
              'sessionLogId': state.sessionId,
              'exerciseId': entry.exercise.id,
              'feeling': _feelingStr(entry.feeling!),
              'loggedAt': DateTime.now().millisecondsSinceEpoch,
            });
          }

          var setIdx = 1;
          for (final setRow in entry.setRows) {
            final setId = 'set_${state.sessionId}_${entry.exercise.id}_$setIdx';
            await txn.insert('ss_workout_set_log', {
              'id': setId,
              'session_id': state.sessionId,
              'exercise_id': entry.exercise.id,
              'set_index': setIdx,
              'weight': setRow.weight,
              'reps': setRow.reps,
              'feeling': entry.feeling != null ? _feelingStr(entry.feeling!) : null,
            });
            setIdx++;
          }
        }
      });

      await clearSessionPreferences();
      state = state.copyWith(isLoading: false);
      return {
        'sessionId': state.sessionId,
        'completedCount': completedCount,
        'totalCount': state.exercises.length,
        'durationSeconds': durationSec,
        'overallFeeling': overallFeeling,
      };
    } catch (e) {
      debugPrint('Error finishing workout: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> abandonSession() async {
    _sessionTimer?.cancel();
    _autoDismissFeelingTimer?.cancel();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'ss_workout_session_log',
        where: 'id = ?',
        whereArgs: [state.sessionId],
      );
    } catch (e) {
      debugPrint('Error abandoning session from database: $e');
    }
    await clearSessionPreferences();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getLastLoggedSetsForExercises(List<String> exerciseIds, Database db) async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final exerciseId in exerciseIds) {
      final lastSessionIdQuery = await db.rawQuery('''
        SELECT session_id
        FROM ss_workout_set_log
        WHERE exercise_id = ?
        ORDER BY id DESC
        LIMIT 1
      ''', [exerciseId]);
      
      if (lastSessionIdQuery.isNotEmpty) {
        final lastSessionId = lastSessionIdQuery.first['session_id']! as String;
        final sets = await db.rawQuery('''
          SELECT weight, reps, feeling, set_index
          FROM ss_workout_set_log
          WHERE exercise_id = ? AND session_id = ?
          ORDER BY set_index ASC
        ''', [exerciseId, lastSessionId]);
        result[exerciseId] = sets;
      }
    }
    return result;
  }

  Future<Map<String, dynamic>?> getLastLoggedSetForExercise(String exerciseId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.rawQuery('''
        SELECT weight, reps, feeling, session_id, set_index
        FROM ss_workout_set_log
        WHERE exercise_id = ?
        ORDER BY id DESC
        LIMIT 1
      ''', [exerciseId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('Error querying last logged set: $e');
      return null;
    }
  }

  void _updateSetWeightAndReps(int setIndex, double? weight, int? reps, {int? rir}) {
    final entry = state.exercises[state.currentExerciseIndex];
    final updatedSetRows = List<SetRow>.from(entry.setRows);
    final row = updatedSetRows[setIndex];
    
    updatedSetRows[setIndex] = row.copyWith(
      weight: weight ?? row.weight,
      reps: reps ?? row.reps,
      rir: rir ?? row.rir,
    );

    final updatedExercises = List<SSExerciseChecklistEntry>.from(state.exercises);
    updatedExercises[state.currentExerciseIndex] = entry.copyWith(setRows: updatedSetRows);
    
    state = state.copyWith(exercises: updatedExercises);
    _saveSessionToPreferences();
  }

  String _feelingStr(Feeling f) {
    switch (f) {
      case Feeling.easy: return 'EASY';
      case Feeling.good: return 'GOOD';
      case Feeling.hard: return 'HARD';
    }
  }
}

class SSWorkoutPlanKey {

  const SSWorkoutPlanKey({required this.planId, required this.dayName});
  final String planId;
  final String dayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SSWorkoutPlanKey &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          dayName == other.dayName;

  @override
  int get hashCode => planId.hashCode ^ dayName.hashCode;
}

final ssWorkoutProvider = NotifierProvider.autoDispose.family<SSWorkoutNotifier, SSWorkoutState, SSWorkoutPlanKey>(
  SSWorkoutNotifier.new,
);
