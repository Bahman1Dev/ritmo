import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';
import 'package:ritmo/features/sports/domain/repositories/sports_repository.dart';
import 'package:ritmo/features/sports/data/datasources/sports_local_datasource.dart';

class SportsRepositoryImpl implements SportsRepository {

  SportsRepositoryImpl(this._localDataSource, this._db);
  final SportsLocalDataSource _localDataSource;
  final Database _db;

  @override
  Future<List<Exercise>> getAllExercises() async {
    final rows = await _localDataSource.getAllExercises();
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByMuscle(MuscleGroup muscle) async {
    final rows = await _localDataSource.getExercisesByMuscle(muscle.code);
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByEquipment(Equipment equipment) async {
    final rows = await _localDataSource.getExercisesByEquipment(equipment.code);
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final rows = await _localDataSource.searchExercises(query);
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    final row = await _localDataSource.getExerciseById(id);
    return row != null ? _mapExercise(row) : null;
  }

  @override
  Future<SaveResult<Exercise>> saveExercise(Exercise exercise) async {
    try {
      final map = _exerciseToMap(exercise);
      if (exercise.isUserCreated || exercise.usageCount == 0) {
        await _localDataSource.insertExercise(map);
      } else {
        await _localDataSource.updateExercise(map);
      }
      return SaveResult.success(exercise);
    } catch (e) {
      return SaveResult.failure('Failed to save exercise: $e');
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    await _localDataSource.deleteExercise(id);
  }

  @override
  Future<void> seedDefaultExercises() async {
    await _localDataSource.seedDefaultExercises();
  }

  // ──────────────────────────────────────────────────────────────
  // Workout Plans
  // ──────────────────────────────────────────────────────────────

  @override
  Future<WorkoutPlan?> getActivePlan() async {
    final row = await _localDataSource.getActivePlan();
    return row != null ? _mapWorkoutPlan(row) : null;
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final rows = await _localDataSource.getAllPlans();
    return rows.map(_mapWorkoutPlan).toList();
  }

  @override
  Future<SaveResult<WorkoutPlan>> savePlan(WorkoutPlan plan) async {
    try {
      await _localDataSource.insertPlan(_planToMap(plan));
      return SaveResult.success(plan);
    } catch (e) {
      return SaveResult.failure('Failed to save plan: $e');
    }
  }

  @override
  Future<void> setActivePlan(String planId) async {
    // Deactivate all, activate one
    final plans = await getAllPlans();
    for (final p in plans) {
      final updated = p.copyWith(
        isActive: p.id == planId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await savePlan(updated);
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    await _localDataSource.deletePlan(id);
  }

  // ──────────────────────────────────────────────────────────────
  // Split Days
  // ──────────────────────────────────────────────────────────────

  @override
  Future<WorkoutSplitDay?> getSplitDay(String splitId, int weekday, int week) async {
    final row = await _localDataSource.getSplitDay(splitId, weekday, week);
    return row != null ? _mapSplitDay(row) : null;
  }

  @override
  Future<List<WorkoutSplitDay>> getSplitDays(String splitId, {int? week}) async {
    final rows = await _localDataSource.getSplitDays(splitId, week: week);
    return rows.map(_mapSplitDay).toList();
  }

  @override
  Future<SaveResult<WorkoutSplitDay>> saveSplitDay(WorkoutSplitDay day) async {
    try {
      await _localDataSource.insertSplitDay(_splitDayToMap(day));
      return SaveResult.success(day);
    } catch (e) {
      return SaveResult.failure('Failed to save split day: $e');
    }
  }

  @override
  Future<void> deleteSplitDay(String id) async {
    await _localDataSource.deleteSplitDay(id);
  }

  // ──────────────────────────────────────────────────────────────
  // Split Exercises
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<SplitExercise>> getSplitExercises(String splitDayId) async {
    final rows = await _localDataSource.getSplitExercises(splitDayId);
    return rows.map(_mapSplitExercise).toList();
  }

  @override
  Future<SaveResult<SplitExercise>> saveSplitExercise(SplitExercise exercise) async {
    try {
      await _localDataSource.insertSplitExercise(_splitExerciseToMap(exercise));
      return SaveResult.success(exercise);
    } catch (e) {
      return SaveResult.failure('Failed to save split exercise: $e');
    }
  }

  @override
  Future<void> deleteSplitExercise(String id) async {
    await _localDataSource.deleteSplitExercise(id);
  }

  @override
  Future<void> reorderExercises(String splitDayId, List<String> exerciseIds) async {
    await _localDataSource.reorderExercises(splitDayId, exerciseIds);
  }

  // ──────────────────────────────────────────────────────────────
  // Today's Plan
  // ──────────────────────────────────────────────────────────────

  @override
  Future<TodayWorkoutPlan?> getTodaysPlan() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await _localDataSource.getTodaysSplitDay();
    if (row == null) {
      return TodayWorkoutPlan(
        splitDay: WorkoutSplitDay(
          id: '',
          splitId: '',
          weekday: DateTime.now().weekday,
          isRest: true,
          targetMuscles: [],
          createdAt: now,
          updatedAt: now,
        ),
        exercises: [],
        suggestedTier: WorkoutTier.light,
        tierReason: 'No plan configured',
        isRestDay: true,
        hasNoPlan: true,
      );
    }

    final splitDay = _mapSplitDay(row);
    final exercises = await getSplitExercises(splitDay.id);
    final suggestedTier = await _localDataSource.getSuggestedTierForToday(_db);

    return TodayWorkoutPlan(
      splitDay: splitDay,
      exercises: exercises,
      suggestedTier: suggestedTier,
      tierReason: 'Standard workout',
      isRestDay: splitDay.isRest,
      hasNoPlan: false,
    );
  }

  @override
  Future<WorkoutTier> getSuggestedTierForToday() async {
    return _localDataSource.getSuggestedTierForToday(_db);
  }

  // ──────────────────────────────────────────────────────────────
  // Workout Sessions
  // ──────────────────────────────────────────────────────────────

  @override
  Future<WorkoutSession?> getSessionById(String id) async {
    final row = await _localDataSource.getSessionById(id);
    return row != null ? _mapSession(row) : null;
  }

  @override
  Future<WorkoutSession?> getTodaysSession() async {
    final row = await _localDataSource.getTodaysSession();
    return row != null ? _mapSession(row) : null;
  }

  @override
  Future<List<WorkoutSession>> getSessions({
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    final rows = await _localDataSource.getSessions(
      fromMs: from?.millisecondsSinceEpoch,
      toMs: to?.millisecondsSinceEpoch,
      limit: limit,
    );
    return rows.map(_mapSession).toList();
  }

  @override
  Future<SaveResult<WorkoutSession>> startSession(WorkoutSession session) async {
    try {
      await _localDataSource.insertSession(_sessionToMap(session));
      return SaveResult.success(session);
    } catch (e) {
      return SaveResult.failure('Failed to start session: $e');
    }
  }

  @override
  Future<SaveResult<WorkoutSession>> completeSession(WorkoutSession session) async {
    try {
      await _localDataSource.updateSession(_sessionToMap(session));
      return SaveResult.success(session);
    } catch (e) {
      return SaveResult.failure('Failed to complete session: $e');
    }
  }

  @override
  Future<SaveResult<WorkoutSession>> updateSession(WorkoutSession session) async {
    try {
      await _localDataSource.updateSession(_sessionToMap(session));
      return SaveResult.success(session);
    } catch (e) {
      return SaveResult.failure('Failed to update session: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Performed Exercises & Sets
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<PerformedExercise>> getPerformedExercises(String sessionId) async {
    final rows = await _localDataSource.getPerformedExercises(sessionId);
    return rows.map(_mapPerformedExercise).toList();
  }

  @override
  Future<SaveResult<PerformedExercise>> savePerformedExercise(PerformedExercise exercise) async {
    try {
      await _localDataSource.insertPerformedExercise(_performedExerciseToMap(exercise));
      return SaveResult.success(exercise);
    } catch (e) {
      return SaveResult.failure('Failed to save performed exercise: $e');
    }
  }

  @override
  Future<void> deletePerformedExercise(String id) async {
    await _localDataSource.deletePerformedExercise(id);
  }

  @override
  Future<List<PerformedSet>> getPerformedSets(String performedExerciseId) async {
    final rows = await _localDataSource.getPerformedSets(performedExerciseId);
    return rows.map(_mapPerformedSet).toList();
  }

  @override
  Future<SaveResult<PerformedSet>> savePerformedSet(PerformedSet set) async {
    try {
      await _localDataSource.insertPerformedSet(_performedSetToMap(set));
      return SaveResult.success(set);
    } catch (e) {
      return SaveResult.failure('Failed to save set: $e');
    }
  }

  @override
  Future<void> deletePerformedSet(String id) async {
    await _localDataSource.deletePerformedSet(id);
  }

  // ──────────────────────────────────────────────────────────────
  // Progression Records
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<ProgressionRecord>> getProgressionRecords({
    String? exerciseId,
    MuscleGroup? muscleGroup,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _localDataSource.getProgressionRecords(
      exerciseId: exerciseId,
      muscleGroupCode: muscleGroup?.code,
      fromMs: from?.millisecondsSinceEpoch,
      toMs: to?.millisecondsSinceEpoch,
    );
    return rows.map(_mapProgressionRecord).toList();
  }

  @override
  Future<SaveResult<ProgressionRecord>> saveProgressionRecord(ProgressionRecord record) async {
    try {
      await _localDataSource.insertProgressionRecord(_progressionRecordToMap(record));
      return SaveResult.success(record);
    } catch (e) {
      return SaveResult.failure('Failed to save progression record: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Readiness Scores
  // ──────────────────────────────────────────────────────────────

  @override
  Future<ReadinessScore?> getTodaysReadiness() async {
    final today = _dateKey(DateTime.now());
    return getReadinessForDate(today);
  }

  @override
  Future<ReadinessScore?> getReadinessForDate(String date) async {
    final row = await _localDataSource.getReadinessForDate(date);
    return row != null ? _mapReadinessScore(row) : null;
  }

  @override
  Future<List<ReadinessScore>> getReadinessHistory({int limit = 30}) async {
    final rows = await _localDataSource.getReadinessHistory(limit: limit);
    return rows.map(_mapReadinessScore).toList();
  }

  @override
  Future<SaveResult<ReadinessScore>> saveReadinessScore(ReadinessScore score) async {
    try {
      await _localDataSource.insertReadinessScore(_readinessScoreToMap(score));
      return SaveResult.success(score);
    } catch (e) {
      return SaveResult.failure('Failed to save readiness score: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Analytics
  // ──────────────────────────────────────────────────────────────

  @override
  Future<WeeklyVolumeReport> getWeeklyVolumeReport(DateTime weekStart) async {
    final data = await _localDataSource.getWeeklyVolumeData(weekStart);
    return WeeklyVolumeReport(
      volumePerMuscle: {for (final e in data.volumePerMuscle.entries) MuscleGroup.fromCode(e.key): e.value},
      setsPerMuscle: {for (final e in data.setsPerMuscle.entries) MuscleGroup.fromCode(e.key): e.value},
      sessionsPerMuscle: {for (final e in data.sessionsPerMuscle.entries) MuscleGroup.fromCode(e.key): e.value},
      totalVolumeKg: data.totalVolumeKg,
      totalSets: data.totalSets,
      totalSessions: data.totalSessions,
      weekStartDate: data.weekStartDate,
    );
  }

  @override
  Future<Map<MuscleGroup, double>> getVolumeTrends(int weeks) async {
    final trends = await _localDataSource.getVolumeTrends(weeks);
    return {for (final e in trends.entries) MuscleGroup.fromCode(e.key): e.value};
  }

  @override
  Future<List<ProgressionRecord>> getRecentPrs({int limit = 10}) async {
    final rows = await _localDataSource.getRecentPrs(limit: limit);
    return rows.map(_mapProgressionRecord).toList();
  }

  @override
  Future<Map<MuscleGroup, double>> getFrequencyPerMuscle(int weeks) async {
    final freq = await _localDataSource.getFrequencyPerMuscle(weeks);
    return {for (final e in freq.entries) MuscleGroup.fromCode(e.key): e.value.toDouble()};
  }

  // ──────────────────────────────────────────────────────────────
  // Settings
  // ──────────────────────────────────────────────────────────────

  @override
  Future<SportsLocation> getLocation() async {
    return _localDataSource.getLocation();
  }

  @override
  Future<void> setLocation(SportsLocation location) async {
    await _localDataSource.setLocation(location);
  }

  @override
  Future<WorkoutGoal> getGoalFocus() async {
    return _localDataSource.getGoalFocus();
  }

  @override
  Future<void> setGoalFocus(WorkoutGoal goal) async {
    await _localDataSource.setGoalFocus(goal);
  }

  @override
  Future<bool> isSetupDone() async {
    return _localDataSource.isSetupDone();
  }

  @override
  Future<void> markSetupDone() async {
    await _localDataSource.markSetupDone();
  }

  @override
  Future<void> resetSetup() async {
    await _localDataSource.resetSetup();
  }

  // ──────────────────────────────────────────────────────────────
  // Legacy Migration
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> migrateLegacyWorkoutLogs() async {
    await _localDataSource.migrateLegacyLogs(_db);
  }

  // ──────────────────────────────────────────────────────────────
  // Mapping Helpers
  // ──────────────────────────────────────────────────────────────

  Exercise _mapExercise(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      nameFa: map['name_fa'] as String? ?? map['name'] as String,
      primaryMuscle: MuscleGroup.fromCode(map['primary_muscle'] as String? ?? 'OTHER'),
      secondaryMuscles: (map['secondary_muscles'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(MuscleGroup.fromCode)
          .toList(),
      category: ExerciseCategory.fromCode(map['category'] as String? ?? 'COMPOUND'),
      equipment: (map['equipment'] as String? ?? 'BODYWEIGHT')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(Equipment.fromCode)
          .toList(),
      difficulty: DifficultyLevel.fromCode(map['difficulty'] as String? ?? 'BEGINNER'),
      description: map['description'] as String?,
      videoUrl: map['video_url'] as String?,
      imageUrl: map['image_url'] as String?,
      cues: (map['cues'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      isCompound: (map['is_compound'] as int? ?? 1) == 1,
      isUserCreated: (map['is_user_created'] as int? ?? 0) == 1,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> _exerciseToMap(Exercise e) => {
    'id': e.id,
    'name': e.name,
    'name_fa': e.nameFa,
    'primary_muscle': e.primaryMuscle.code,
    'secondary_muscles': e.secondaryMuscles.map((m) => m.code).join(','),
    'category': e.category.code,
    'equipment': e.equipment.map((e) => e.code).join(','),
    'difficulty': e.difficulty.code,
    'description': e.description,
    'video_url': e.videoUrl,
    'image_url': e.imageUrl,
    'cues': e.cues.join(','),
    'is_compound': e.isCompound ? 1 : 0,
    'is_user_created': e.isUserCreated ? 1 : 0,
    'usage_count': e.usageCount,
    'created_at': e.createdAt,
    'updated_at': e.updatedAt,
  };

  WorkoutPlan _mapWorkoutPlan(Map<String, dynamic> map) => WorkoutPlan(
    id: map['id'] as String,
    name: map['name'] as String,
    goal: WorkoutGoal.fromCode(map['goal'] as String? ?? 'HYPERTROPHY'),
    frequency: map['frequency'] as int? ?? 3,
    mesocycleLengthWeeks: map['mesocycle_length_weeks'] as int? ?? 6,
    currentWeek: map['current_week'] as int? ?? 1,
    progressionType: ProgressionType.fromCode(map['progression_type'] as String? ?? 'DOUBLE_PROGRESSION'),
    deloadFrequencyWeeks: map['deload_frequency_weeks'] as int? ?? 4,
    isActive: (map['is_active'] as int? ?? 0) == 1,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _planToMap(WorkoutPlan p) => {
    'id': p.id,
    'name': p.name,
    'goal': p.goal.code,
    'frequency': p.frequency,
    'mesocycle_length_weeks': p.mesocycleLengthWeeks,
    'current_week': p.currentWeek,
    'progression_type': p.progressionType.code,
    'deload_frequency_weeks': p.deloadFrequencyWeeks,
    'is_active': p.isActive ? 1 : 0,
    'created_at': p.createdAt,
    'updated_at': p.updatedAt,
  };

  WorkoutSplitDay _mapSplitDay(Map<String, dynamic> map) => WorkoutSplitDay(
    id: map['id'] as String,
    splitId: map['split_id'] as String,
    weekday: map['weekday'] as int? ?? 1,
    weekInMesocycle: map['week_in_mesocycle'] as int? ?? 1,
    dayName: map['day_name'] as String?,
    isRest: (map['is_rest'] as int? ?? 0) == 1,
    targetMuscles: (map['target_muscles'] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(MuscleGroup.fromCode)
        .toList(),
    notes: map['notes'] as String?,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _splitDayToMap(WorkoutSplitDay d) => {
    'id': d.id,
    'split_id': d.splitId,
    'weekday': d.weekday,
    'week_in_mesocycle': d.weekInMesocycle,
    'day_name': d.dayName,
    'is_rest': d.isRest ? 1 : 0,
    'target_muscles': d.targetMuscles.map((m) => m.code).join(','),
    'notes': d.notes,
    'created_at': d.createdAt,
    'updated_at': d.updatedAt,
  };

  SplitExercise _mapSplitExercise(Map<String, dynamic> map) => SplitExercise(
    id: map['id'] as String,
    splitDayId: map['split_day_id'] as String,
    exerciseId: map['exercise_id'] as String,
    exerciseOrder: map['exercise_order'] as int? ?? 0,
    targetSets: map['target_sets'] as int? ?? 3,
    targetRepsMin: map['target_reps_min'] as int? ?? 8,
    targetRepsMax: map['target_reps_max'] as int? ?? 12,
    targetRpe: (map['target_rpe'] as num?)?.toDouble(),
    restSeconds: map['rest_seconds'] as int? ?? 120,
    isSuperset: (map['is_superset'] as int? ?? 0) == 1,
    supersetGroupId: map['superset_group_id'] as String?,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _splitExerciseToMap(SplitExercise e) => {
    'id': e.id,
    'split_day_id': e.splitDayId,
    'exercise_id': e.exerciseId,
    'exercise_order': e.exerciseOrder,
    'target_sets': e.targetSets,
    'target_reps_min': e.targetRepsMin,
    'target_reps_max': e.targetRepsMax,
    'target_rpe': e.targetRpe,
    'rest_seconds': e.restSeconds,
    'is_superset': e.isSuperset ? 1 : 0,
    'superset_group_id': e.supersetGroupId,
    'created_at': e.createdAt,
    'updated_at': e.updatedAt,
  };

  WorkoutSession _mapSession(Map<String, dynamic> map) => WorkoutSession(
    id: map['id'] as String,
    startedAt: map['started_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    completedAt: map['completed_at'] as int?,
    splitDayId: map['split_day_id'] as String?,
    plannedTier: WorkoutTier.fromCode(map['planned_tier'] as String? ?? 'FULL'),
    completedTier: WorkoutTier.fromCode(map['completed_tier'] as String? ?? 'FULL'),
    totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
    totalSets: map['total_sets'] as int? ?? 0,
    totalReps: map['total_reps'] as int? ?? 0,
    actualDurationSeconds: map['actual_duration_seconds'] as int? ?? 0,
    sessionRpe: (map['session_rpe'] as num?)?.toDouble(),
    notes: map['notes'] as String?,
    wasAutoAdjusted: (map['was_auto_adjusted'] as int? ?? 0) == 1,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _sessionToMap(WorkoutSession s) => {
    'id': s.id,
    'started_at': s.startedAt,
    'completed_at': s.completedAt,
    'split_day_id': s.splitDayId,
    'planned_tier': s.plannedTier.code,
    'completed_tier': s.completedTier.code,
    'total_volume_kg': s.totalVolumeKg,
    'total_sets': s.totalSets,
    'total_reps': s.totalReps,
    'actual_duration_seconds': s.actualDurationSeconds,
    'session_rpe': s.sessionRpe,
    'notes': s.notes,
    'was_auto_adjusted': s.wasAutoAdjusted ? 1 : 0,
    'created_at': s.createdAt,
    'updated_at': s.updatedAt,
  };

  PerformedExercise _mapPerformedExercise(Map<String, dynamic> map) => PerformedExercise(
    id: map['id'] as String,
    sessionId: map['session_id'] as String,
    exerciseId: map['exercise_id'] as String,
    exerciseName: map['exercise_name'] as String,
    primaryMuscle: MuscleGroup.fromCode(map['primary_muscle'] as String? ?? 'OTHER'),
    setOrder: map['set_order'] as int? ?? 0,
    totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
    previousBestWeight: (map['previous_best_weight'] as num?)?.toDouble(),
    previousBestReps: map['previous_best_reps'] as int?,
    isPr: (map['is_pr'] as int? ?? 0) == 1,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _performedExerciseToMap(PerformedExercise e) => {
    'id': e.id,
    'session_id': e.sessionId,
    'exercise_id': e.exerciseId,
    'exercise_name': e.exerciseName,
    'primary_muscle': e.primaryMuscle.code,
    'set_order': e.setOrder,
    'total_volume_kg': e.totalVolumeKg,
    'previous_best_weight': e.previousBestWeight,
    'previous_best_reps': e.previousBestReps,
    'is_pr': e.isPr ? 1 : 0,
    'created_at': e.createdAt,
  };

  PerformedSet _mapPerformedSet(Map<String, dynamic> map) => PerformedSet(
    id: map['id'] as String,
    performedExerciseId: map['performed_exercise_id'] as String,
    setNumber: map['set_number'] as int? ?? 1,
    weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
    reps: map['reps'] as int? ?? 0,
    rpe: (map['rpe'] as num?)?.toDouble() ?? 8.0,
    isWarmup: (map['is_warmup'] as int? ?? 0) == 1,
    isDropSet: (map['is_drop_set'] as int? ?? 0) == 1,
    isCompleted: (map['is_completed'] as int? ?? 1) == 1,
    restSecondsTaken: map['rest_seconds_taken'] as int?,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _performedSetToMap(PerformedSet s) => {
    'id': s.id,
    'performed_exercise_id': s.performedExerciseId,
    'set_number': s.setNumber,
    'weight_kg': s.weightKg,
    'reps': s.reps,
    'rpe': s.rpe,
    'is_warmup': s.isWarmup ? 1 : 0,
    'is_drop_set': s.isDropSet ? 1 : 0,
    'is_completed': s.isCompleted ? 1 : 0,
    'rest_seconds_taken': s.restSecondsTaken,
    'created_at': s.createdAt,
  };

  ProgressionRecord _mapProgressionRecord(Map<String, dynamic> map) => ProgressionRecord(
    id: map['id'] as String,
    exerciseId: map['exercise_id'] as String,
    exerciseName: map['exercise_name'] as String,
    muscleGroup: MuscleGroup.fromCode(map['muscle_group'] as String? ?? 'OTHER'),
    weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
    reps: map['reps'] as int? ?? 0,
    setCount: map['set_count'] as int? ?? 0,
    achievedAt: map['achieved_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    progressionType: map['progression_type'] as String? ?? 'weight_increase',
    previousBestWeight: (map['previous_best_weight'] as num?)?.toDouble(),
    previousBestReps: map['previous_best_reps'] as int?,
  );

  Map<String, dynamic> _progressionRecordToMap(ProgressionRecord r) => {
    'id': r.id,
    'exercise_id': r.exerciseId,
    'exercise_name': r.exerciseName,
    'muscle_group': r.muscleGroup.code,
    'weight_kg': r.weightKg,
    'reps': r.reps,
    'set_count': r.setCount,
    'achieved_at': r.achievedAt,
    'progression_type': r.progressionType,
    'previous_best_weight': r.previousBestWeight,
    'previous_best_reps': r.previousBestReps,
  };

  ReadinessScore _mapReadinessScore(Map<String, dynamic> map) => ReadinessScore(
    date: map['date'] as String,
    score: map['score'] as int? ?? 0,
    sleepMinutes: map['sleep_minutes'] as int?,
    sleepQuality: map['sleep_quality'] as int?,
    hrvRmssd: map['hrv_rmssd'] as int?,
    restingHr: map['resting_hr'] as int?,
    sorenessScore: map['soreness_score'] as int?,
    fatigueScore: map['fatigue_score'] as int?,
    moodScore: map['mood_score'] as int?,
    isMenstrualPhase: (map['is_menstrual_phase'] as int? ?? 0) == 1,
    suggestedTier: WorkoutTier.fromCode(map['suggested_tier'] as String? ?? 'LIGHT'),
    reason: map['reason'] as String? ?? '',
    factorsJson: map['factors_json'] != null ? Map<String, int>.from(jsonDecode(map['factors_json'] as String) as Map) : null,
    createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> _readinessScoreToMap(ReadinessScore r) => {
    'date': r.date,
    'score': r.score,
    'sleep_minutes': r.sleepMinutes,
    'sleep_quality': r.sleepQuality,
    'hrv_rmssd': r.hrvRmssd,
    'resting_hr': r.restingHr,
    'soreness_score': r.sorenessScore,
    'fatigue_score': r.fatigueScore,
    'mood_score': r.moodScore,
    'is_menstrual_phase': r.isMenstrualPhase ? 1 : 0,
    'suggested_tier': r.suggestedTier.code,
    'reason': r.reason,
    'factors_json': r.factorsJson,
    'created_at': r.createdAt,
  };

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}