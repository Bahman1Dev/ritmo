import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:sqflite/sqflite.dart';

class CompleteOccurrenceHandler
    implements KernelCommandHandler<CompleteOccurrenceCommand> {
  const CompleteOccurrenceHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    CompleteOccurrenceCommand command,
  ) async {
    final nowMs = context.now.millisecondsSinceEpoch;
    final tasks = <Future<void> Function()>[];

    // 1. Ensure stub routine exists in routines table so Foreign Key constraints never fail
    final routineRows = await context.txn.query(
      'routines',
      columns: ['category', 'medStockCount'],
      where: 'id = ?',
      whereArgs: [command.routineId],
    );

    if (routineRows.isEmpty) {
      try {
        await context.txn.insert(
          'routines',
          {
            'id': command.routineId,
            'title': command.routineId,
            'category': 'personal',
            'routineType': 'HABIT',
            'notificationLevel': 'DEFAULT',
            'isEssential': 0,
            'displayOrder': 0,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        debugPrint('[CompleteOccurrenceHandler] Stub routine insert note: $e');
      }
    } else {
      final category = routineRows.first['category'] as String? ?? '';
      final currentStock = routineRows.first['medStockCount'] as int? ?? 0;

      if (category.toLowerCase() == 'medical' && currentStock > 0) {
        await context.txn.update(
          'routines',
          {'medStockCount': currentStock - 1},
          where: 'id = ?',
          whereArgs: [command.routineId],
        );
      }
    }

    // 2. Determine if this is an interval routine (may complete multiple times/day)
    final scheduleRows = await context.txn.query(
      'routine_schedules',
      columns: ['intervalHours'],
      where: 'routineId = ?',
      whereArgs: [command.routineId],
      limit: 1,
    );
    final isInterval = scheduleRows.isNotEmpty &&
        (scheduleRows.first['intervalHours'] as int? ?? 0) > 0;

    // T3: Deterministic ID for non-interval routines so ConflictAlgorithm.replace
    // actually deduplicates. Interval routines keep timestamp-based ID since they
    // may legitimately have multiple completions in one day.
    final completionId = isInterval
        ? 'comp_${command.routineId}_$nowMs'
        : 'comp_${command.routineId}_${command.dateStr}';

    // 3. Insert into routine_completions with ConflictAlgorithm.replace
    await context.txn.insert(
      'routine_completions',
      {
        'id': completionId,
        'routineId': command.routineId,
        'completionDate': command.dateStr,
        'completionTime': nowMs,
        'resultType': command.resultType,
        'resultSource': command.resultSource,
        'partialRatio': command.partialRatio,
        'durationMinutes': command.durationMinutes,
        'actual_duration_minutes': command.durationMinutes,
        'note': command.note,
        'createdAt': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 3. Update progression engine safely
    try {
      await ProgressionEngine().onCompletion(context.txn, command.routineId);
    } catch (e) {
      debugPrint('[CompleteOccurrenceHandler] ProgressionEngine onCompletion error: $e');
    }

    // 4. Update status in routine_occurrences
    final affected = await context.txn.rawUpdate(
      'UPDATE routine_occurrences SET status = ? WHERE routine_id = ? AND date = ?',
      ['done', command.routineId, command.dateStr],
    );

    if (affected == 0) {
      await context.txn.insert('routine_occurrences', {
        'routine_id': command.routineId,
        'date': command.dateStr,
        'status': 'done',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 5. Update pending reminders safely
    try {
      final dateDateTime = DateTime.parse(command.dateStr);
      final startOfDay = DateTime(
        dateDateTime.year,
        dateDateTime.month,
        dateDateTime.day,
      ).millisecondsSinceEpoch;
      final endOfDay = DateTime(
        dateDateTime.year,
        dateDateTime.month,
        dateDateTime.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      final reminders = await context.txn.query(
        'pending_reminders',
        where:
            'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
        whereArgs: [
          command.routineId,
          'unknown',
          'delayed',
          'sent',
          startOfDay,
          endOfDay,
        ],
      );

      for (final rem in reminders) {
        final remId = rem['id']! as String;
        tasks.add(() => sl<AlarmPlatform>().cancelAlarm(remId));

        await context.txn.update(
          'pending_reminders',
          {
            'state': 'opened',
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [remId],
        );
      }
    } catch (e) {
      debugPrint('[CompleteOccurrenceHandler] pending_reminders update note: $e');
    }

    tasks.add(() => DatabaseHelper.instance.logNotificationEvent(
          routineId: command.routineId,
          actionTaken: 'opened',
          notificationType: 'ROUTINE',
        ));

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineCompleted(
          now: context.now,
          routineId: command.routineId,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
