// lib/features/sports/domain/repositories/sports_repository.dart

import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

abstract class SportsRepository {
  // ──────────────────────────────────────────────────────────────
  // Exercise Library
  // ──────────────────────────────────────────────────────────────

  Future<List<Exercise>> getAllExercises();
  Future<List<Exercise>> getExercisesByMuscle(MuscleGroup muscle);
  Future<List<Exercise>> getExercisesByEquipment(Equipment equipment);
  Future<List<Exercise>> searchExercises(String query);
  Future<Exercise?> getExerciseById(String id);
  Future<SaveResult<Exercise>> saveExercise(Exercise exercise);
  Future<void> deleteExercise(String id);
  Future<void> seedDefaultExercises();

  // ──────────────────────────────────────────────────────────────
  // Workout Plans (Mesocycles)
  // ──────────────────────────────────────────────────────────────

  Future<WorkoutPlan?> getActivePlan();
  Future<List<WorkoutPlan>> getAllPlans();
  Future<SaveResult<WorkoutPlan>> savePlan(WorkoutPlan plan);
  Future<void> setActivePlan(String planId);
  Future<void> deletePlan(String planId);

  // ──────────────────────────────────────────────────────────────
  // Split Days
  // ──────────────────────────────────────────────────────────────

  Future<WorkoutSplitDay?> getSplitDay(String splitId, int weekday, int weekInMesocycle);
  Future<List<WorkoutSplitDay>> getSplitDays(String splitId, {int? week});
  Future<SaveResult<WorkoutSplitDay>> saveSplitDay(WorkoutSplitDay day);
  Future<void> deleteSplitDay(String id);

  // ──────────────────────────────────────────────────────────────
  // Split Exercises
  // ──────────────────────────────────────────────────────────────

  Future<List<SplitExercise>> getSplitExercises(String splitDayId);
  Future<SaveResult<SplitExercise>> saveSplitExercise(SplitExercise exercise);
  Future<void> deleteSplitExercise(String id);
  Future<void> reorderExercises(String splitDayId, List<String> exerciseIds);

  // ──────────────────────────────────────────────────────────────
  // Today's Workout Plan
  // ──────────────────────────────────────────────────────────────

  Future<TodayWorkoutPlan?> getTodaysPlan();
  Future<WorkoutTier> getSuggestedTierForToday();

  // ──────────────────────────────────────────────────────────────
  // Workout Sessions
  // ──────────────────────────────────────────────────────────────

  Future<WorkoutSession?> getSessionById(String id);
  Future<WorkoutSession?> getTodaysSession();
  Future<List<WorkoutSession>> getSessions({
    DateTime? from,
    DateTime? to,
    int limit = 50,
  });
  Future<SaveResult<WorkoutSession>> startSession(WorkoutSession session);
  Future<SaveResult<WorkoutSession>> completeSession(WorkoutSession session);
  Future<SaveResult<WorkoutSession>> updateSession(WorkoutSession session);

  // ──────────────────────────────────────────────────────────────
  // Performed Exercises & Sets
  // ──────────────────────────────────────────────────────────────

  Future<List<PerformedExercise>> getPerformedExercises(String sessionId);
  Future<SaveResult<PerformedExercise>> savePerformedExercise(PerformedExercise exercise);
  Future<void> deletePerformedExercise(String id);

  Future<List<PerformedSet>> getPerformedSets(String performedExerciseId);
  Future<SaveResult<PerformedSet>> savePerformedSet(PerformedSet set);
  Future<void> deletePerformedSet(String id);

  // ──────────────────────────────────────────────────────────────
  // Progression / PR Records
  // ──────────────────────────────────────────────────────────────

  Future<List<ProgressionRecord>> getProgressionRecords({
    String? exerciseId,
    MuscleGroup? muscleGroup,
    DateTime? from,
    DateTime? to,
  });
  Future<SaveResult<ProgressionRecord>> saveProgressionRecord(ProgressionRecord record);

  // ──────────────────────────────────────────────────────────────
  // Readiness Scores
  // ──────────────────────────────────────────────────────────────

  Future<ReadinessScore?> getTodaysReadiness();
  Future<ReadinessScore?> getReadinessForDate(String date);
  Future<List<ReadinessScore>> getReadinessHistory({int limit = 30});
  Future<SaveResult<ReadinessScore>> saveReadinessScore(ReadinessScore score);

  // ──────────────────────────────────────────────────────────────
  // Analytics / Reports
  // ──────────────────────────────────────────────────────────────

  Future<WeeklyVolumeReport> getWeeklyVolumeReport(DateTime weekStart);
  Future<Map<MuscleGroup, double>> getVolumeTrends(int weeks);
  Future<List<ProgressionRecord>> getRecentPrs({int limit = 10});
  Future<Map<MuscleGroup, double>> getFrequencyPerMuscle(int weeks);

  // ──────────────────────────────────────────────────────────────
  // User Settings / Profile
  // ──────────────────────────────────────────────────────────────

  Future<SportsLocation> getLocation();
  Future<void> setLocation(SportsLocation location);
  Future<WorkoutGoal> getGoalFocus();
  Future<void> setGoalFocus(WorkoutGoal goal);
  Future<bool> isSetupDone();
  Future<void> markSetupDone();
  Future<void> resetSetup();

  // ──────────────────────────────────────────────────────────────
  // Legacy Migration Helpers
  // ──────────────────────────────────────────────────────────────

  Future<void> migrateLegacyWorkoutLogs();
}