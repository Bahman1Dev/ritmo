import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

class ConfirmReshuffleHandler
    implements KernelCommandHandler<ConfirmReshuffleCommand> {
  const ConfirmReshuffleHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    ConfirmReshuffleCommand command,
  ) async {
    final tasks = <Future<void> Function()>[];

    for (final action in command.actions) {
      if (action.actionType == ReshuffleActionType.shiftWithinZone ||
          action.actionType == ReshuffleActionType.shiftToNextZone ||
          action.actionType == ReshuffleActionType.moveToTomorrow) {
        if (action.newTime == null) continue;

        final startOfDay = DateTime(
          context.now.year,
          context.now.month,
          context.now.day,
        ).millisecondsSinceEpoch;

        final endOfDay = DateTime(
          context.now.year,
          context.now.month,
          context.now.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

        final reminders = await context.txn.query(
          'pending_reminders',
          where:
              'routineId = ? AND (state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
          whereArgs: [
            action.routineId,
            'unknown',
            'delayed',
            startOfDay,
            endOfDay,
          ],
        );

        for (final rem in reminders) {
          final remId = rem['id']! as String;
          final newScheduledMs = action.newTime!.millisecondsSinceEpoch;

          await context.txn.update(
            'pending_reminders',
            {
              'scheduledTime': newScheduledMs,
              'updatedAt': context.now.millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [remId],
          );

          final routinesList = await context.txn.query(
            'routines',
            where: 'id = ?',
            whereArgs: [action.routineId],
            limit: 1,
          );

          final title = routinesList.isNotEmpty
              ? routinesList.first['title']! as String
              : action.routineTitle;

          final isEssential =
              routinesList.isNotEmpty && routinesList.first['isEssential'] == 1;

          tasks.add(() async {
            await sl<AlarmPlatform>().cancelAlarm(remId);
            await sl<AlarmPlatform>().scheduleExactAlarm(
              id: remId,
              timeMsUTC: newScheduledMs,
              title: title,
              isEssential: isEssential,
            );
            await DatabaseHelper.instance.logNotificationEvent(
              routineId: action.routineId,
              actionTaken: 'sent',
              notificationType: 'ROUTINE',
            );
          });
        }
      }
    }

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: null,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
