import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

class SnoozeReminderHandler
    implements KernelCommandHandler<SnoozeReminderCommand> {
  const SnoozeReminderHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    SnoozeReminderCommand command,
  ) async {
    final nowMs = context.now.millisecondsSinceEpoch;
    final snoozeUntilMs = nowMs + (command.snoozeMinutes * 60 * 1000);
    final tasks = <Future<void> Function()>[];

    final reminders = await context.txn.query(
      'pending_reminders',
      where: 'id = ?',
      whereArgs: [command.reminderId],
    );

    if (reminders.isEmpty) {
      return KernelMutationResult(
        domainEvents: [
          KernelEventFactory.routineEdited(
            now: context.now,
            routineId: null,
            payload: {'reminderId': command.reminderId},
          ),
        ],
      );
    }

    final rem = reminders.first;
    final routineId = rem['routineId']! as String;
    final origTimeMs = rem['originalTime']! as int;
    final dateStr = DateTime.fromMillisecondsSinceEpoch(origTimeMs)
        .toIso8601String()
        .substring(0, 10);

    await context.txn.update(
      'pending_reminders',
      {
        'state': 'delayed',
        'snoozeUntil': snoozeUntilMs,
        'scheduledTime': snoozeUntilMs,
        'deferCount': (rem['deferCount']! as int) + 1,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [command.reminderId],
    );

    await context.txn.update(
      'routine_occurrences',
      {'status': 'snoozed'},
      where: 'routine_id = ? AND date = ?',
      whereArgs: [routineId, dateStr],
    );

    final routineList = await context.txn.query(
      'routines',
      where: 'id = ?',
      whereArgs: [routineId],
      limit: 1,
    );

    final title =
        routineList.isNotEmpty ? routineList.first['title']! as String : 'روتین';
    final isEssential =
        routineList.isNotEmpty && routineList.first['isEssential'] == 1;

    tasks.add(() async {
      await sl<AlarmPlatform>().cancelAlarm(command.reminderId);
      await sl<AlarmPlatform>().scheduleExactAlarm(
        id: command.reminderId,
        timeMsUTC: snoozeUntilMs,
        title: title,
        isEssential: isEssential,
      );
      await DatabaseHelper.instance.logNotificationEvent(
        routineId: routineId,
        actionTaken: 'delayed',
        notificationType: 'ROUTINE',
      );
      await SnapshotSyncService.syncAll();
    });

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: null,
          payload: {'reminderId': command.reminderId},
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
