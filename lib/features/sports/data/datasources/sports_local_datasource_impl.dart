import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/features/sports/data/datasources/sports_local_datasource.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

class SportsLocalDataSourceImpl implements SportsLocalDataSource {

  SportsLocalDataSourceImpl(this._db);
  final Database _db;

  @override
  Future<void> seedDefaultExercises() async {}

  // ──────────────────────────────────────────────────────────────
  // Exercise Library
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getAllExercises() async {
    return _db.query(
      'exercises_library',
      orderBy: 'usage_count DESC, name ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExercisesByMuscle(String muscleCode) async {
    return _db.query(
      'exercises_library',
      where: 'primary_muscle = ? OR secondary_muscles LIKE ?',
      whereArgs: [muscleCode, '%$muscleCode%'],
      orderBy: 'usage_count DESC, name ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipmentCode) async {
    return _db.query(
      'exercises_library',
      where: 'equipment LIKE ?',
      whereArgs: ['%$equipmentCode%'],
      orderBy: 'usage_count DESC, name ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    final q = '%${query.toLowerCase()}%';
    return _db.query(
      'exercises_library',
      where: 'LOWER(name_fa) LIKE ? OR LOWER(name) LIKE ?',
      whereArgs: [q, q],
      orderBy: 'usage_count DESC, name ASC',
    );
  }

  @override
  Future<Map<String, dynamic>?> getExerciseById(String id) async {
    final result = await _db.query(
      'exercises_library',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<int> insertExercise(Map<String, dynamic> exercise) async {
    return _db.insert(
      'exercises_library',
      exercise,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateExercise(Map<String, dynamic> exercise) async {
    return _db.update(
      'exercises_library',
      exercise,
      where: 'id = ?',
      whereArgs: [exercise['id']],
    );
  }

  @override
  Future<int> deleteExercise(String id) async {
    return _db.delete(
      'exercises_library',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Workout Plans
  // ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getActivePlan() async {
    final result = await _db.query(
      'workout_splits',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    return _db.query(
      'workout_splits',
      orderBy: 'updated_at DESC',
    );
  }

  @override
  Future<int> insertPlan(Map<String, dynamic> plan) async {
    return _db.insert(
      'workout_splits',
      plan,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updatePlan(Map<String, dynamic> plan) async {
    return _db.update(
      'workout_splits',
      plan,
      where: 'id = ?',
      whereArgs: [plan['id']],
    );
  }

  @override
  Future<int> deletePlan(String id) async {
    await _db.delete('workout_split_days', where: 'split_id = ?', whereArgs: [id]);
    await _db.delete('workout_split_exercises', where: 'split_day_id IN (SELECT id FROM workout_split_days WHERE split_id = ?)', whereArgs: [id]);
    return _db.delete('workout_splits', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────────────────────────────
  // Split Days
  // ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getSplitDay(String splitId, int weekday, int week) async {
    final result = await _db.query(
      'workout_split_days',
      where: 'split_id = ? AND weekday = ? AND week_in_mesocycle = ?',
      whereArgs: [splitId, weekday, week],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getSplitDays(String splitId, {int? week}) async {
    var where = 'split_id = ?';
    final args = <dynamic>[splitId];
    if (week != null) {
      where += ' AND week_in_mesocycle = ?';
      args.add(week);
    }
    return _db.query(
      'workout_split_days',
      where: where,
      whereArgs: args,
      orderBy: 'week_in_mesocycle, weekday',
    );
  }

  @override
  Future<int> insertSplitDay(Map<String, dynamic> day) async {
    return _db.insert(
      'workout_split_days',
      day,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateSplitDay(Map<String, dynamic> day) async {
    return _db.update(
      'workout_split_days',
      day,
      where: 'id = ?',
      whereArgs: [day['id']],
    );
  }

  @override
  Future<int> deleteSplitDay(String id) async {
    await _db.delete('workout_split_exercises', where: 'split_day_id = ?', whereArgs: [id]);
    return _db.delete('workout_split_days', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────────────────────────────
  // Split Exercises
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSplitExercises(String splitDayId) async {
    return _db.query(
      'workout_split_exercises',
      where: 'split_day_id = ?',
      whereArgs: [splitDayId],
      orderBy: 'exercise_order',
    );
  }

  @override
  Future<int> insertSplitExercise(Map<String, dynamic> exercise) async {
    return _db.insert(
      'workout_split_exercises',
      exercise,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateSplitExercise(Map<String, dynamic> exercise) async {
    return _db.update(
      'workout_split_exercises',
      exercise,
      where: 'id = ?',
      whereArgs: [exercise['id']],
    );
  }

  @override
  Future<int> deleteSplitExercise(String id) async {
    return _db.delete(
      'workout_split_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> reorderExercises(String splitDayId, List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'workout_split_exercises',
        {'exercise_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
    return orderedIds.length;
  }

  // ──────────────────────────────────────────────────────────────
  // Today's Plan
  // ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getTodaysSplitDay() async {
    final activePlan = await getActivePlan();
    if (activePlan == null) return null;

    final weekday = DateTime.now().weekday; // 1=Mon ... 7=Sun
    return getSplitDay(activePlan['id'] as String, weekday, 1);
  }

  @override
  Future<WorkoutTier> getSuggestedTierForToday(Database db) async {
    // This will be handled by ReadinessCalculator service
    // Default fallback
    return WorkoutTier.full;
  }

  // ──────────────────────────────────────────────────────────────
  // Workout Sessions
  // ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getSessionById(String id) async {
    final result = await _db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getTodaysSession() async {
    final today = DateTime.now();
    final startMs = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final endMs = DateTime(today.year, today.month, today.day, 23, 59, 59).millisecondsSinceEpoch;

    final result = await _db.query(
      'workout_sessions',
      where: 'started_at >= ? AND started_at <= ?',
      whereArgs: [startMs, endMs],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions({
    int? fromMs,
    int? toMs,
    int limit = 50,
  }) async {
    var where = '1=1';
    final args = <dynamic>[];

    if (fromMs != null) {
      where += ' AND started_at >= ?';
      args.add(fromMs);
    }
    if (toMs != null) {
      where += ' AND started_at <= ?';
      args.add(toMs);
    }

    return _db.query(
      'workout_sessions',
      where: where,
      whereArgs: args,
      orderBy: 'started_at DESC',
      limit: limit,
    );
  }

  @override
  Future<int> insertSession(Map<String, dynamic> session) async {
    return _db.insert(
      'workout_sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateSession(Map<String, dynamic> session) async {
    return _db.update(
      'workout_sessions',
      session,
      where: 'id = ?',
      whereArgs: [session['id']],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Performed Exercises
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getPerformedExercises(String sessionId) async {
    return _db.query(
      'performed_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'set_order',
    );
  }

  @override
  Future<int> insertPerformedExercise(Map<String, dynamic> exercise) async {
    return _db.insert(
      'performed_exercises',
      exercise,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updatePerformedExercise(Map<String, dynamic> exercise) async {
    return _db.update(
      'performed_exercises',
      exercise,
      where: 'id = ?',
      whereArgs: [exercise['id']],
    );
  }

  @override
  Future<int> deletePerformedExercise(String id) async {
    await _db.delete('performed_sets', where: 'performed_exercise_id = ?', whereArgs: [id]);
    return _db.delete('performed_exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────────────────────────────
  // Performed Sets
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getPerformedSets(String performedExerciseId) async {
    return _db.query(
      'performed_sets',
      where: 'performed_exercise_id = ?',
      whereArgs: [performedExerciseId],
      orderBy: 'set_number',
    );
  }

  @override
  Future<int> insertPerformedSet(Map<String, dynamic> set) async {
    return _db.insert(
      'performed_sets',
      set,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updatePerformedSet(Map<String, dynamic> set) async {
    return _db.update(
      'performed_sets',
      set,
      where: 'id = ?',
      whereArgs: [set['id']],
    );
  }

  @override
  Future<int> deletePerformedSet(String id) async {
    return _db.delete(
      'performed_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Progression Records
  // ──────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getProgressionRecords({
    String? exerciseId,
    String? muscleGroupCode,
    int? fromMs,
    int? toMs,
  }) async {
    var where = '1=1';
    final args = <dynamic>[];

    if (exerciseId != null) {
      where += ' AND exercise_id = ?';
      args.add(exerciseId);
    }
    if (muscleGroupCode != null) {
      where += ' AND muscle_group = ?';
      args.add(muscleGroupCode);
    }
    if (fromMs != null) {
      where += ' AND achieved_at >= ?';
      args.add(fromMs);
    }
    if (toMs != null) {
      where += ' AND achieved_at <= ?';
      args.add(toMs);
    }

    return _db.query(
      'progression_records',
      where: where,
      whereArgs: args,
      orderBy: 'achieved_at DESC',
    );
  }

  @override
  Future<int> insertProgressionRecord(Map<String, dynamic> record) async {
    return _db.insert(
      'progression_records',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Readiness Scores
  // ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getTodaysReadiness() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return getReadinessForDate(dateKey);
  }

  @override
  Future<Map<String, dynamic>?> getReadinessForDate(String date) async {
    final result = await _db.query(
      'readiness_scores',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getReadinessHistory({int limit = 30}) async {
    return _db.query(
      'readiness_scores',
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  @override
  Future<int> insertReadinessScore(Map<String, dynamic> score) async {
    return _db.insert(
      'readiness_scores',
      score,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateReadinessScore(Map<String, dynamic> score) async {
    return _db.update(
      'readiness_scores',
      score,
      where: 'date = ?',
      whereArgs: [score['date']],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Analytics
  // ──────────────────────────────────────────────────────────────

  @override
  Future<WeeklyVolumeReportData> getWeeklyVolumeData(DateTime weekStart) async {
    final startMs = weekStart.millisecondsSinceEpoch;
    final endMs = weekStart.add(const Duration(days: 7)).millisecondsSinceEpoch;

    final sessions = await _db.query(
      'workout_sessions',
      where: 'completed_at >= ? AND completed_at < ?',
      whereArgs: [startMs, endMs],
    );

    final volumePerMuscle = <String, double>{};
    final setsPerMuscle = <String, int>{};
    final sessionsPerMuscle = <String, int>{};

    double totalVolume = 0;
    var totalSets = 0;
    final totalSessions = sessions.length;

    for (final session in sessions) {
      if (session['completed_at'] == null) continue;
      totalVolume += (session['total_volume_kg'] as num? ?? 0).toDouble();
      totalSets += session['total_sets'] as int? ?? 0;

      final exercises = await _db.query(
        'performed_exercises',
        where: 'session_id = ?',
        whereArgs: [session['id']],
      );

      for (final ex in exercises) {
        final muscle = ex['primary_muscle'] as String? ?? 'UNKNOWN';
        final volume = (ex['total_volume_kg'] as num? ?? 0).toDouble();

        volumePerMuscle[muscle] = (volumePerMuscle[muscle] ?? 0) + volume;
        setsPerMuscle[muscle] = (setsPerMuscle[muscle] ?? 0) + 1;
        sessionsPerMuscle[muscle] = (sessionsPerMuscle[muscle] ?? 0) + 1;
      }
    }

    return WeeklyVolumeReportData(
      volumePerMuscle: volumePerMuscle,
      setsPerMuscle: setsPerMuscle,
      sessionsPerMuscle: sessionsPerMuscle,
      totalVolumeKg: totalVolume,
      totalSets: totalSets,
      totalSessions: totalSessions,
      weekStartDate: weekStart.millisecondsSinceEpoch,
    );
  }

  @override
  Future<Map<String, double>> getVolumeTrends(int weeks) async {
    final trends = <String, double>{};
    final now = DateTime.now();

    for (var i = 0; i < weeks; i++) {
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1).subtract(Duration(days: i * 7));
      final data = await getWeeklyVolumeData(weekStart);
      trends['week_${weeks - i}'] = data.totalVolumeKg;
    }

    return trends;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentPrs({int limit = 10}) async {
    return _db.query(
      'progression_records',
      orderBy: 'achieved_at DESC',
      limit: limit,
    );
  }

  @override
  Future<Map<String, int>> getFrequencyPerMuscle(int weeks) async {
    final freq = <String, int>{};
    final now = DateTime.now();
    final startMs = DateTime(now.year, now.month, now.day).subtract(Duration(days: weeks * 7)).millisecondsSinceEpoch;

    final sessions = await _db.query(
      'workout_sessions',
      where: 'completed_at >= ?',
      whereArgs: [startMs],
    );

    for (final session in sessions) {
      final exercises = await _db.query(
        'performed_exercises',
        where: 'session_id = ?',
        whereArgs: [session['id']],
      );

      for (final ex in exercises) {
        final muscle = ex['primary_muscle'] as String? ?? 'UNKNOWN';
        freq[muscle] = (freq[muscle] ?? 0) + 1;
      }
    }

    return freq;
  }

  // ──────────────────────────────────────────────────────────────
  // Settings
  // ──────────────────────────────────────────────────────────────

  @override
  Future<SportsLocation> getLocation() async {
    final rows = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sports_location'],
      limit: 1,
    );
    if (rows.isEmpty) return SportsLocation.home;
    return SportsLocation.fromCode(rows.first['value'] as String? ?? 'HOME');
  }

  @override
  Future<int> setLocation(SportsLocation location) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert(
      'app_settings',
      {
        'key': 'sports_location',
        'value': location.code,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<WorkoutGoal> getGoalFocus() async {
    final rows = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sports_goal_focus'],
      limit: 1,
    );
    if (rows.isEmpty) return WorkoutGoal.hypertrophy;
    return WorkoutGoal.fromCode(rows.first['value'] as String? ?? 'HYPERTROPHY');
  }

  @override
  Future<int> setGoalFocus(WorkoutGoal goal) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert(
      'app_settings',
      {
        'key': 'sports_goal_focus',
        'value': goal.code,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool> isSetupDone() async {
    final rows = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sports_setup_done'],
      limit: 1,
    );
    return rows.isNotEmpty && (rows.first['value'] as String?) == 'true';
  }

  @override
  Future<int> markSetupDone() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert(
      'app_settings',
      {
        'key': 'sports_setup_done',
        'value': 'true',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> resetSetup() async {
    await _db.delete('workout_split_days', where: 'split_id IN (SELECT id FROM workout_splits)');
    await _db.delete('workout_split_exercises', where: 'split_day_id IN (SELECT id FROM workout_split_days WHERE split_id IN (SELECT id FROM workout_splits))');
    await _db.delete('workout_splits');
    return _db.insert(
      'app_settings',
      {
        'key': 'sports_setup_done',
        'value': 'false',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Legacy Migration
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> migrateLegacyLogs(Database db) async {
    final legacyLogs = await db.query('workout_logs');
    if (legacyLogs.isEmpty) return;

    final batch = db.batch();
    for (final log in legacyLogs) {
      final id = log['id'] as String? ?? 'wl_${DateTime.now().millisecondsSinceEpoch}';
      final loggedAt = log['loggedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final duration = log['durationMinutes'] as int? ?? 0;
      final intensity = log['intensity'] as String? ?? 'MEDIUM';
      final note = log['note'] as String? ?? '';
      final tier = log['tier'] as String? ?? 'FULL';
      final muscleGroups = log['muscleGroups'] as String? ?? '';

      final sessionId = id;
      batch.insert('workout_sessions', {
        'id': sessionId,
        'started_at': loggedAt - (duration * 60 * 1000),
        'completed_at': loggedAt,
        'split_day_id': null,
        'planned_tier': tier,
        'completed_tier': tier,
        'total_volume_kg': 0.0,
        'total_sets': 0,
        'total_reps': 0,
        'actual_duration_seconds': duration * 60,
        'session_rpe': _intensityToRPE(intensity),
        'notes': note,
        'was_auto_adjusted': 0,
        'created_at': loggedAt,
        'updated_at': loggedAt,
      });

      if (muscleGroups.isNotEmpty) {
        final groups = muscleGroups.split(',').where((g) => g.trim().isNotEmpty).toList();
        for (var i = 0; i < groups.length; i++) {
          final muscleCode = groups[i].trim();
          batch.insert('performed_exercises', {
            'id': '${sessionId}_ex_$i',
            'session_id': sessionId,
            'exercise_id': 'legacy_$muscleCode',
            'exercise_name': _muscleCodeToName(muscleCode),
            'primary_muscle': muscleCode,
            'set_order': i,
            'total_volume_kg': 0.0,
            'previous_best_weight': null,
            'previous_best_reps': null,
            'is_pr': 0,
            'created_at': loggedAt,
          });
        }
      }
    }
    await batch.commit(noResult: true);
    debugPrint('[Migration] Migrated ${legacyLogs.length} legacy workout_logs');
  }

  double _intensityToRPE(String intensity) {
    switch (intensity.toUpperCase()) {
      case 'LOW': return 6;
      case 'MEDIUM': return 8;
      case 'HIGH': return 9;
      default: return 8;
    }
  }

  String _muscleCodeToName(String code) {
    switch (code.toUpperCase()) {
      case 'CHEST': return 'Chest';
      case 'BACK': return 'Back';
      case 'SHOULDERS': return 'Shoulders';
      case 'BICEPS': return 'Biceps';
      case 'TRICEPS': return 'Triceps';
      case 'LEGS': return 'Legs';
      case 'ABS': return 'Abs';
      case 'FULLBODY': return 'Full Body';
      case 'CARDIO': return 'Cardio';
      case 'REST': return 'Rest';
      default: return code;
    }
  }
}