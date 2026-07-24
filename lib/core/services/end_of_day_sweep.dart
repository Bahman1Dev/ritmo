import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:sqflite/sqflite.dart';

/// EndOfDaySweep sweeps stale pending/snoozed occurrences past midnight and converts them to 'missed'.
class EndOfDaySweep {
  EndOfDaySweep._();

  static Future<int> runSweep(Database db, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    var sweptCount = 0;

    try {
      final staleRows = await db.rawQuery('''
        SELECT o.id, o.routineId, o.date, r.isEssential, r.category
        FROM routine_occurrences o
        LEFT JOIN routines r ON o.routineId = r.id
        WHERE o.status IN ('pending', 'snoozed') AND o.date < ?
      ''', [todayStr]);

      if (staleRows.isEmpty) return 0;

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
              {'state': 'expired'},
              where: 'routineId = ? AND state IN (\'active\', \'delayed\', \'unknown\')',
              whereArgs: [routineId],
            );
          }
        }
      });
    } catch (e) {
      debugPrint('EndOfDaySweep error: $e');
    }

    return sweptCount;
  }
}
