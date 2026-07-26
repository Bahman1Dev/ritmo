import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:sqflite/sqflite.dart';

/// EndOfDaySweep sweeps stale pending/snoozed occurrences past midnight and converts them to 'missed'.
class EndOfDaySweep {
  EndOfDaySweep._();

  static Future<int> runSweep(Database db, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final todayStr = RitmoDate(today).value;
    final yesterdayStr = RitmoDate(today.subtract(const Duration(days: 1))).value;

    var sweptCount = 0;

    try {
      final staleRows = await db.rawQuery('''
        SELECT o.id, o.routineId, o.date, r.isEssential, r.category
        FROM routine_occurrences o
        LEFT JOIN routines r ON o.routineId = r.id
        WHERE o.status IN ('pending', 'snoozed') AND o.date < ?
      ''', [todayStr]);

      await db.transaction((txn) async {
        for (final row in staleRows) {
          final occId = row['id']! as String;
          final routineId = row['routineId'] as String?;
          final isEssential = row['isEssential'] == 1;
          final category = row['category'] as String?;

          await txn.update(
            'routine_occurrences',
            {'status': 'missed'},
            where: 'id = ?',
            whereArgs: [occId],
          );
          sweptCount++;

          if (isEssential || category == 'medical') {
            await CentralInboxService.push(
              category: InboxCategory.ALERT,
              sourceSystem: 'end_of_day_sweep',
              entityId: occId,
              eventType: 'missed_essential',
              priority: 2,
              title: 'آیتم ضروری فراموش‌شده',
              body: 'یکی از آیتم‌های مهم یا داروی شما دیروز انجام نشد.',
              payload: {'routineId': routineId, 'occurrenceId': occId},
            );
          }

          if (routineId != null) {
            await txn.update(
              'pending_reminders',
              {'state': ReminderState.expired.dbValue},
              where:
                  'routineId = ? AND state IN (?, ?, ?, ?)',
              whereArgs: [
                routineId,
                ReminderState.active.dbValue,
                ReminderState.delayed.dbValue,
                ReminderState.unknown.dbValue,
                ReminderState.cancelled.dbValue,
              ],
            );
          }
        }

        // Worship Sweep
        await _sweepWorship(txn, yesterdayStr, todayStr);
      });

      WorshipRepository.instance.invalidateCache();
      DayAgendaService.instance.invalidateDate(yesterdayStr);
      DayAgendaService.instance.invalidateDate(todayStr);

      await db.execute(
        "INSERT OR REPLACE INTO app_settings (key, value) VALUES ('last_worship_sweep_date', ?)",
        [todayStr],
      );
    } catch (e) {
      debugPrint('EndOfDaySweep error: $e');
    }

    return sweptCount;
  }

  static Future<void> _sweepWorship(DatabaseExecutor txn, String yesterdayStr, String todayStr) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final uncompletedRows = await txn.rawQuery('''
      SELECT p.id, p.practiceType, p.dailyTarget
      FROM worship_practices p
      WHERE p.isActive = 1
      AND p.practiceType IN ('PRAYER', 'MUSTAHAB', 'FASTING')
      AND NOT EXISTS (
        SELECT 1 FROM worship_completions c
        WHERE c.practiceId = p.id AND c.dateStr = ?
      )
    ''', [yesterdayStr]);

    for (final row in uncompletedRows) {
      final pid = row['id']! as String;
      final pType = row['practiceType']! as String;
      final target = row['dailyTarget'] as int?;
      final recordId = 'wc_missed_${pid}_$yesterdayStr';

      try {
        await txn.insert(
          'worship_completions',
          {
            'id': recordId,
            'practiceId': pid,
            'dateStr': yesterdayStr,
            'practiceType': pType,
            'resultType': 'MISSED',
            'countDone': 0,
            'countTarget': target,
            'loggedAt': nowMs,
            'createdAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (_) {}
    }

    // Reset dailyDone for active practices
    await txn.update(
      'worship_practices',
      {
        'dailyDone': 0,
        'dailyDoneDate': todayStr,
        'updatedAt': nowMs,
      },
      where: 'isActive = 1',
    );
  }
}
