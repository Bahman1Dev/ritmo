import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';
import 'package:sqflite/sqflite.dart';

part 'sports_local_datasource.freezed.dart';
part 'sports_local_datasource.g.dart';

abstract class SportsLocalDataSource {
  Future<void> seedDefaultExercises();

  // Exercise Library
  Future<List<Map<String, dynamic>>> getAllExercises();
  Future<List<Map<String, dynamic>>> getExercisesByMuscle(String muscleCode);
  Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipmentCode);
  Future<List<Map<String, dynamic>>> searchExercises(String query);
  Future<Map<String, dynamic>?> getExerciseById(String id);
  Future<int> insertExercise(Map<String, dynamic> exercise);
  Future<int> updateExercise(Map<String, dynamic> exercise);
  Future<int> deleteExercise(String id);

  // Workout Plans
  Future<Map<String, dynamic>?> getActivePlan();
  Future<List<Map<String, dynamic>>> getAllPlans();
  Future<int> insertPlan(Map<String, dynamic> plan);
  Future<int> updatePlan(Map<String, dynamic> plan);
  Future<int> deletePlan(String id);

  // Split Days
  Future<Map<String, dynamic>?> getSplitDay(String splitId, int weekday, int week);
  Future<List<Map<String, dynamic>>> getSplitDays(String splitId, {int? week});
  Future<int> insertSplitDay(Map<String, dynamic> day);
  Future<int> updateSplitDay(Map<String, dynamic> day);
  Future<int> deleteSplitDay(String id);

  // Split Exercises
  Future<List<Map<String, dynamic>>> getSplitExercises(String splitDayId);
  Future<int> insertSplitExercise(Map<String, dynamic> exercise);
  Future<int> updateSplitExercise(Map<String, dynamic> exercise);
  Future<int> deleteSplitExercise(String id);
  Future<int> reorderExercises(String splitDayId, List<String> orderedIds);

  // Today's Plan
  Future<Map<String, dynamic>?> getTodaysSplitDay();
  Future<WorkoutTier> getSuggestedTierForToday(Database db);

  // Workout Sessions
  Future<Map<String, dynamic>?> getSessionById(String id);
  Future<Map<String, dynamic>?> getTodaysSession();
  Future<List<Map<String, dynamic>>> getSessions({
    int? fromMs,
    int? toMs,
    int limit = 50,
  });
  Future<int> insertSession(Map<String, dynamic> session);
  Future<int> updateSession(Map<String, dynamic> session);

  // Performed Exercises
  Future<List<Map<String, dynamic>>> getPerformedExercises(String sessionId);
  Future<int> insertPerformedExercise(Map<String, dynamic> exercise);
  Future<int> updatePerformedExercise(Map<String, dynamic> exercise);
  Future<int> deletePerformedExercise(String id);

  // Performed Sets
  Future<List<Map<String, dynamic>>> getPerformedSets(String performedExerciseId);
  Future<int> insertPerformedSet(Map<String, dynamic> set);
  Future<int> updatePerformedSet(Map<String, dynamic> set);
  Future<int> deletePerformedSet(String id);

  // Progression Records
  Future<List<Map<String, dynamic>>> getProgressionRecords({
    String? exerciseId,
    String? muscleGroupCode,
    int? fromMs,
    int? toMs,
  });
  Future<int> insertProgressionRecord(Map<String, dynamic> record);

  // Readiness Scores
  Future<Map<String, dynamic>?> getTodaysReadiness();
  Future<Map<String, dynamic>?> getReadinessForDate(String date);
  Future<List<Map<String, dynamic>>> getReadinessHistory({int limit = 30});
  Future<int> insertReadinessScore(Map<String, dynamic> score);
  Future<int> updateReadinessScore(Map<String, dynamic> score);

  // Analytics
  Future<WeeklyVolumeReportData> getWeeklyVolumeData(DateTime weekStart);
  Future<Map<String, double>> getVolumeTrends(int weeks);
  Future<List<Map<String, dynamic>>> getRecentPrs({int limit = 10});
  Future<Map<String, int>> getFrequencyPerMuscle(int weeks);

  // Settings
  Future<SportsLocation> getLocation();
  Future<int> setLocation(SportsLocation location);
  Future<WorkoutGoal> getGoalFocus();
  Future<int> setGoalFocus(WorkoutGoal goal);
  Future<bool> isSetupDone();
  Future<int> markSetupDone();
  Future<int> resetSetup();

  // Legacy
  Future<void> migrateLegacyLogs(Database db);
}

@freezed
abstract class WeeklyVolumeReportData with _$WeeklyVolumeReportData {
  const factory WeeklyVolumeReportData({
    required Map<String, double> volumePerMuscle,
    required Map<String, int> setsPerMuscle,
    required Map<String, int> sessionsPerMuscle,
    required double totalVolumeKg,
    required int totalSets,
    required int totalSessions,
    required int weekStartDate,
  }) = _WeeklyVolumeReportData;

  factory WeeklyVolumeReportData.fromJson(Map<String, dynamic> json) =>
      _$WeeklyVolumeReportDataFromJson(json);
}