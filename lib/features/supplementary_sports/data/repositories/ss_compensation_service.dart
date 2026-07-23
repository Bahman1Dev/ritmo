import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SSCompensationService {
  SSCompensationService._();

  static String _handledPrefKey(String dateStr) => 'ss_missed_handled_$dateStr';

  /// Check if a missed day dialog has already been handled by user
  static Future<bool> isMissedDayHandled(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_handledPrefKey(dateStr)) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark missed day as handled
  static Future<void> markMissedDayHandled(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_handledPrefKey(dateStr), true);
    } catch (_) {}
  }

  /// Option 1: Shift Schedule
  /// Shifts all remaining plans for the week by +1 day so today gets yesterday's missed workout.
  static Future<bool> shiftWeeklyPlanByOneDay({
    required Database db,
    required int currentWeek,
    required int missedDayOfWeek, // 1 to 7
  }) async {
    try {
      final weekIdPrefix = 'plan_w${currentWeek}_';
      final plans = await db.query(
        'ss_workout_plan',
        where: 'id LIKE ?',
        whereArgs: ['$weekIdPrefix%'],
        orderBy: 'dayOfWeek ASC',
      );

      if (plans.isEmpty) return false;

      final plansToShift = plans.where((p) => (p['dayOfWeek']! as int) >= missedDayOfWeek).toList();

      for (final p in plansToShift) {
        final currentDow = p['dayOfWeek']! as int;
        if (currentDow < 7) {
          final newDow = currentDow + 1;
          final oldId = p['id'].toString();
          final newId = 'plan_w${currentWeek}_$newDow';

          // Update crossrefs
          await db.update(
            'ss_workout_exercise_crossref',
            {'planId': newId},
            where: 'planId = ?',
            whereArgs: [oldId],
          );

          // Update plan
          await db.update(
            'ss_workout_plan',
            {
              'id': newId,
              'dayOfWeek': newDow,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [oldId],
          );
        }
      }

      // Log decision
      await db.insert('ss_decision_log', {
        'id': 'dec_shift_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 'default',
        'decisionType': 'COMPENSATE_SHIFT',
        'rejectionReason': 'shift_by_1_day',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e, st) {
      debugPrint('[SSCompensationService] Error shifting plan: $e\n$st');
      return false;
    }
  }

  /// Option 2: Express Merge
  /// Take 2-3 main exercises from yesterday's missed plan and append them to today's workout plan.
  static Future<bool> expressMergeWorkouts({
    required Database db,
    required String todayPlanId,
    required String missedPlanId,
  }) async {
    try {
      // 1. Fetch missed plan exercises
      final missedCrossrefs = await db.query(
        'ss_workout_exercise_crossref',
        where: 'planId = ?',
        whereArgs: [missedPlanId],
        orderBy: 'orderIndex ASC',
        limit: 3, // Top 3 main exercises
      );

      if (missedCrossrefs.isEmpty) return false;

      // 2. Fetch current max orderIndex in today's plan
      final todayCrossrefs = await db.query(
        'ss_workout_exercise_crossref',
        where: 'planId = ?',
        whereArgs: [todayPlanId],
        orderBy: 'orderIndex DESC',
        limit: 1,
      );
      var maxOrder = todayCrossrefs.isNotEmpty ? (todayCrossrefs.first['orderIndex'] as int? ?? 0) : 0;

      // 3. Append missed exercises to today's plan with targetSets reduced to 2 (Express)
      for (final ref in missedCrossrefs) {
        maxOrder++;
        final newId = 'xref_express_${DateTime.now().millisecondsSinceEpoch}_$maxOrder';
        await db.insert('ss_workout_exercise_crossref', {
          'id': newId,
          'planId': todayPlanId,
          'exerciseId': ref['exerciseId'],
          'orderIndex': maxOrder,
          'difficultyOffset': ref['difficultyOffset'] ?? 0.0,
          'targetSets': 2,
          'targetReps': ref['targetReps'] ?? 10,
          'targetWeight': ref['targetWeight'],
        });
      }

      // 4. Update today's estimated minutes slightly (+10 mins)
      final todayPlans = await db.query('ss_workout_plan', where: 'id = ?', whereArgs: [todayPlanId]);
      if (todayPlans.isNotEmpty) {
        final currentEst = todayPlans.first['estimatedMinutes'] as int? ?? 45;
        await db.update(
          'ss_workout_plan',
          {
            'estimatedMinutes': currentEst + 10,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [todayPlanId],
        );
      }

      // Log decision
      await db.insert('ss_decision_log', {
        'id': 'dec_merge_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 'default',
        'decisionType': 'COMPENSATE_MERGE',
        'rejectionReason': 'express_merge_top3',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e, st) {
      debugPrint('[SSCompensationService] Error express merging workouts: $e\n$st');
      return false;
    }
  }

  /// Option 3: Adaptive Rest
  /// Mark missed day as adaptive rest without breaking continuity.
  static Future<bool> markAsAdaptedRest({
    required Database db,
    required String missedPlanId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'ss_workout_session_log',
        {
          'id': 'log_adapted_rest_${DateTime.now().millisecondsSinceEpoch}',
          'planId': missedPlanId,
          'startedAt': now - 86400000,
          'finishedAt': now - 86400000 + 60000,
          'totalExercisesCount': 0,
          'completedExercisesCount': 0,
          'durationSeconds': 0,
          'rpe': 1,
          'feedbackNotes': 'Adaptive Rest (استراحت منطبیق‌شده جهت بازیابی)',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert('ss_decision_log', {
        'id': 'dec_rest_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 'default',
        'decisionType': 'COMPENSATE_ADAPTIVE_REST',
        'rejectionReason': 'adaptive_rest',
        'createdAt': now,
      });

      return true;
    } catch (e, st) {
      debugPrint('[SSCompensationService] Error marking adapted rest: $e\n$st');
      return false;
    }
  }
}
