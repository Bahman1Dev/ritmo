import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

class DeleteRoutineHandler
    implements KernelCommandHandler<DeleteRoutineCommand> {
  const DeleteRoutineHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    DeleteRoutineCommand command,
  ) async {
    final id = command.routineId;
    final tasks = <Future<void> Function()>[];

    // 1. Cancel native alarms for all pending/active reminders of this routine
    final pending = await context.txn.query(
      'pending_reminders',
      where: 'routineId = ?',
      whereArgs: [id],
    );

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      tasks.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    // 2. Cascading delete from all routine-related tables
    await context.txn.delete('pending_reminders', where: 'routineId = ?', whereArgs: [id]);
    await context.txn.delete('routine_occurrences', where: 'routine_id = ?', whereArgs: [id]);
    await context.txn.delete('routine_completions', where: 'routineId = ?', whereArgs: [id]);
    await context.txn.delete('routine_logs', where: 'routineId = ?', whereArgs: [id]);
    await context.txn.delete('routine_schedules', where: 'routineId = ?', whereArgs: [id]);
    await context.txn.delete('routines', where: 'id = ?', whereArgs: [id]);

    // 3. Clear dependency references in other routines
    await context.txn.update(
      'routines',
      {'dependsOnRoutineId': null},
      where: 'dependsOnRoutineId = ?',
      whereArgs: [id],
    );

    // 4. Clear goal step references if goal_steps table exists
    try {
      await context.txn.update(
        'goal_steps',
        {'linkedRoutineId': null},
        where: 'linkedRoutineId = ?',
        whereArgs: [id],
      );
    } catch (_) {}

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineDeleted(
          now: context.now,
          routineId: id,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
