import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

class SkipOccurrenceHandler
    implements KernelCommandHandler<SkipOccurrenceCommand> {
  const SkipOccurrenceHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    SkipOccurrenceCommand command,
  ) async {
    final nowMs = context.now.millisecondsSinceEpoch;
    final tasks = <Future<void> Function()>[];

    await context.txn.insert('routine_completions', {
      'id': 'comp_${command.routineId}_$nowMs',
      'routineId': command.routineId,
      'completionDate': command.dateStr,
      'completionTime': nowMs,
      'resultType': 'SKIPPED',
      'resultSource': 'USER',
      'note': command.reason,
      'createdAt': nowMs,
      'updatedAt': nowMs,
    });

    try {
      await context.txn.insert('skip_reasons', {
        'id': 'skip_${command.routineId}_$nowMs',
        'itemId': command.routineId,
        'domain': 'routine',
        'dateStr': command.dateStr,
        'reason': command.reason ?? 'SKIPPED',
        'note': null,
        'createdAt': nowMs,
      });
    } catch (e, st) {
      RitmoLog.warning('SkipOccurrenceHandler', 'Failed to insert skip_reason record', e, st);
    }

    final affected = await context.txn.rawUpdate(
      'UPDATE routine_occurrences SET status = ? WHERE routine_id = ? AND date = ?',
      ['skipped', command.routineId, command.dateStr],
    );

    if (affected == 0) {
      await context.txn.insert('routine_occurrences', {
        'routine_id': command.routineId,
        'date': command.dateStr,
        'status': 'skipped',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

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

    tasks.add(() => DatabaseHelper.instance.logNotificationEvent(
          routineId: command.routineId,
          actionTaken: 'opened',
          notificationType: 'ROUTINE',
        ));

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineSkipped(
          now: context.now,
          routineId: command.routineId,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
