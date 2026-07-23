import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_session_models.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_session_repository.dart';
import 'package:sqflite/sqflite.dart';

class SSSessionRepositoryImpl implements SSSessionRepository {
  @override
  Future<String> startSession(String planId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'session_${planId}_$now';
    
    await db.insert('ss_workout_session_log', {
      'id': id,
      'planId': planId,
      'startedAt': now,
      'finishedAt': null,
      'durationSeconds': 0,
      'completedExercisesCount': 0,
      'totalExercisesCount': 0,
    });
    return id;
  }

  @override
  Future<void> logExerciseFeeling(String sessionId, String exerciseId, Feeling feeling) async {
    final db = await DatabaseHelper.instance.database;
    final logId = 'feel_${sessionId}_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('ss_exercise_feeling_log', {
      'id': logId,
      'sessionLogId': sessionId,
      'exerciseId': exerciseId,
      'feeling': _feelingToString(feeling),
      'loggedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> finishSession(String sessionId, {required int completedCount, required int totalCount, String? overallFeeling}) async {
    final db = await DatabaseHelper.instance.database;
    final finishedAt = DateTime.now().millisecondsSinceEpoch;
    
    // Find startedAt
    final logs = await db.query('ss_workout_session_log', where: 'id = ?', whereArgs: [sessionId]);
    if (logs.isEmpty) return;
    
    final startedAt = logs.first['startedAt']! as int;
    final durationSec = ((finishedAt - startedAt) / 1000).round();
    
    await db.update('ss_workout_session_log', {
      'finishedAt': finishedAt,
      'durationSeconds': durationSec,
      'completedExercisesCount': completedCount,
      'totalExercisesCount': totalCount,
      'overallFeeling': overallFeeling,
    }, where: 'id = ?', whereArgs: [sessionId]);
  }

  @override
  Future<bool> isTodaySessionLogged() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59).millisecondsSinceEpoch;

    final result = await db.query(
      'ss_workout_session_log',
      where: 'startedAt >= ? AND startedAt <= ? AND finishedAt IS NOT NULL',
      whereArgs: [startOfToday, endOfToday],
    );
    return result.isNotEmpty;
  }

  @override
  Future<int> getCurrentStreak() async {
    final db = await DatabaseHelper.instance.database;
    final logs = await db.query(
      'ss_workout_session_log',
      where: 'finishedAt IS NOT NULL',
      orderBy: 'startedAt DESC',
    );
    if (logs.isEmpty) return 0;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final yesterdayMidnight = todayMidnight.subtract(const Duration(hours: 26)); // safe yesterday
    final yesterdayMidnightNormalized = DateTime(yesterdayMidnight.year, yesterdayMidnight.month, yesterdayMidnight.day);

    final loggedMidnights = logs.map((log) {
      final dt = DateTime.fromMillisecondsSinceEpoch(log['startedAt']! as int);
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();

    if (!loggedMidnights.contains(todayMidnight) && !loggedMidnights.contains(yesterdayMidnightNormalized)) {
      return 0;
    }

    var streak = 0;
    var check = loggedMidnights.contains(todayMidnight) ? todayMidnight : yesterdayMidnightNormalized;
    
    while (loggedMidnights.contains(check)) {
      streak++;
      final prev = check.subtract(const Duration(hours: 26));
      check = DateTime(prev.year, prev.month, prev.day);
    }
    
    return streak;
  }

  @override
  Future<List<bool>> getLast7DaysActivity() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    final logs = await db.query(
      'ss_workout_session_log',
      where: 'finishedAt IS NOT NULL',
    );
    
    final loggedMidnights = logs.map((log) {
      final dt = DateTime.fromMillisecondsSinceEpoch(log['startedAt']! as int);
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
    
    return List.generate(7, (i) {
      final targetDate = todayMidnight.subtract(Duration(hours: i * 26));
      final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
      return loggedMidnights.contains(targetMidnight);
    });
  }

  @override
  Future<int> getTotalSessionCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ss_workout_session_log WHERE finishedAt IS NOT NULL');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<double> getMonthContinuityPercent() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month).millisecondsSinceEpoch;
    
    final logs = await db.query(
      'ss_workout_session_log',
      where: 'startedAt >= ? AND finishedAt IS NOT NULL',
      whereArgs: [startOfMonth],
    );
    
    // Count days logged this month
    final loggedDays = <String>{};
    for (final log in logs) {
      final date = DateTime.fromMillisecondsSinceEpoch(log['startedAt']! as int);
      loggedDays.add('${date.year}-${date.month}-${date.day}');
    }

    final totalDaysPassed = today.day;
    if (totalDaysPassed == 0) return 0.0;
    return (loggedDays.length / totalDaysPassed) * 100.0;
  }

  @override
  Future<List<ExerciseFeelingLog>> getRecentFeelings(int sessionCount) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'ss_exercise_feeling_log',
      orderBy: 'loggedAt DESC',
      limit: sessionCount,
    );
    return results.map(ExerciseFeelingLog.fromMap).toList();
  }

  @override
  Future<List<ExerciseReadyForIncrease>> getExercisesReadyForProgression() async {
    final db = await DatabaseHelper.instance.database;
    final twelveWeeksAgo = DateTime.now().subtract(const Duration(days: 84)).millisecondsSinceEpoch;

    // Load recent feelings from past 12 weeks
    final logs = await db.query(
      'ss_exercise_feeling_log',
      where: 'loggedAt >= ?',
      whereArgs: [twelveWeeksAgo],
    );

    // Group logs by exerciseId
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final exId = log['exerciseId'].toString();
      grouped.putIfAbsent(exId, () => []).add(log);
    }

    final readyList = <ExerciseReadyForIncrease>[];

    for (final entry in grouped.entries) {
      final exId = entry.key;
      final exerciseLogs = entry.value;

      final consecutiveWeeks = _calculateConsecutiveEasyWeeks(exerciseLogs);
      
      // Rule: At least 2 consecutive easy weeks
      if (consecutiveWeeks >= 2) {
        // Fetch exercise name
        final exercises = await db.query('ss_exercise', where: 'id = ?', whereArgs: [exId]);
        if (exercises.isNotEmpty) {
          final name = exercises.first['name'].toString();
          readyList.add(
            ExerciseReadyForIncrease(
              exerciseId: exId,
              exerciseName: name,
              consecutiveEasyWeeks: consecutiveWeeks,
            ),
          );
        }
      }
    }

    return readyList;
  }

  int _calculateConsecutiveEasyWeeks(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;
    
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const oneDayMs = 24 * 60 * 60 * 1000;
    const oneWeekMs = 7 * oneDayMs;
    
    var consecutiveWeeks = 0;
    var currentBlock = 0;
    
    // Check up to 12 weeks back
    while (currentBlock < 12) {
      final start = nowMs - (currentBlock + 1) * oneWeekMs;
      final end = nowMs - currentBlock * oneWeekMs;
      
      final blockLogs = logs.where((log) {
        final time = log['loggedAt'] as int;
        return time >= start && time < end;
      }).toList();
      
      if (blockLogs.isEmpty) {
        if (currentBlock == 0) {
          currentBlock++;
          continue;
        } else {
          break;
        }
      }
      
      final easyCount = blockLogs.where((l) => l['feeling'].toString() == 'EASY').length;
      final easyRatio = easyCount / blockLogs.length;
      
      if (easyRatio >= 0.7) {
        consecutiveWeeks++;
        currentBlock++;
      } else {
        break;
      }
    }
    
    return consecutiveWeeks;
  }

  String _feelingToString(Feeling feeling) {
    switch (feeling) {
      case Feeling.easy: return 'EASY';
      case Feeling.good: return 'GOOD';
      case Feeling.hard: return 'HARD';
    }
  }
}
