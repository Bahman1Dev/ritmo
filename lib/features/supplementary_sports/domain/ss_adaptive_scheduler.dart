import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_profile_repository.dart';
import 'package:ritmo/features/supplementary_sports/domain/ss_program_calendar.dart';
import 'package:sqflite/sqflite.dart';

/// Handles weekly adaptive plan regeneration based on progression signals and completion rates.
class SSAdaptiveScheduler {
  /// Ensures upcoming week's plan is generated adaptively.
  static Future<void> ensureUpcomingWeekReady(Database db, DateTime today) async {
    final profile = await SSProfileRepository.instance.getProfile();
    if (profile == null) return;

    final currentWk = SSProgramCalendar.currentWeek(profile.programStartDate, today);
    final nextWk = currentWk + 1;

    final check = await db.query(
      'ss_workout_plan',
      where: 'week = ?',
      whereArgs: [nextWk],
    );

    if (check.isNotEmpty) return; // Idempotent guard

    final signals = await _collectProgressionSignals(db);
    final completionRate = await _calculateWeekCompletionRate(db, currentWk);

    var effectiveProfile = profile;
    if (completionRate < 0.5 && profile.daysPerWeek > 2) {
      effectiveProfile = profile.copyWith(daysPerWeek: profile.daysPerWeek - 1);
    }

    final isDeloadWeek = (nextWk % profile.deloadEveryNWeeks == 0);

    await db.transaction((txn) async {
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(
        txn,
        effectiveProfile,
        week: nextWk,
        progressionSignals: signals,
        isDeload: isDeloadWeek,
      );

      await txn.insert('ss_decision_log', {
        'id': RitmoIdFactory.ssDecision(),
        'userId': 'default',
        'decisionType': isDeloadWeek ? 'DELOAD_WEEK' : 'WEEK_REGENERATED',
        'rejectionReason': 'CompletionRate: ${(completionRate * 100).toStringAsFixed(0)}%',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  static Future<Map<String, ProgressionSignal>> _collectProgressionSignals(Database db) async {
    final Map<String, ProgressionSignal> signals = {};

    final feelings = await db.rawQuery('''
      SELECT exerciseId, feeling, COUNT(*) as count
      FROM ss_exercise_feeling_log
      GROUP BY exerciseId, feeling
    ''');

    final Map<String, int> easyCounts = {};
    final Map<String, int> hardCounts = {};

    for (final row in feelings) {
      final exId = row['exerciseId'] as String;
      final feeling = row['feeling'] as String;
      final count = row['count'] as int;

      if (feeling == 'EASY') {
        easyCounts[exId] = (easyCounts[exId] ?? 0) + count;
      } else if (feeling == 'HARD' || feeling == 'TOO_HARD') {
        hardCounts[exId] = (hardCounts[exId] ?? 0) + count;
      }
    }

    final allExIds = {...easyCounts.keys, ...hardCounts.keys};
    for (final exId in allExIds) {
      final easy = easyCounts[exId] ?? 0;
      final hard = hardCounts[exId] ?? 0;

      if (easy >= 2 && hard == 0) {
        signals[exId] = ProgressionSignal.increase;
      } else if (hard >= 1) {
        signals[exId] = ProgressionSignal.decrease;
      } else {
        signals[exId] = ProgressionSignal.maintain;
      }
    }

    return signals;
  }

  static Future<double> _calculateWeekCompletionRate(Database db, int week) async {
    final rows = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ss_plan_schedule
      GROUP BY status
    ''');

    int completed = 0;
    int total = 0;

    for (final r in rows) {
      final status = r['status'] as String;
      final count = r['count'] as int;
      if (status == 'COMPLETED' || status == 'SHIFTED') {
        completed += count;
      }
      if (status != 'REST') {
        total += count;
      }
    }

    if (total == 0) return 1.0;
    return completed / total;
  }
}
