import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
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

    await context.txn.update(
      'routines',
      {
        'isArchived': 1,
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final pending = await context.txn.query(
      'pending_reminders',
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    final tasks = <Future<void> Function()>[];

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      tasks.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    await context.txn.update(
      'pending_reminders',
      {
        'state': 'CANCELLED',
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await context.txn.delete(
      'routine_occurrences',
      where: 'routine_id = ? AND date >= ?',
      whereArgs: [id, todayStr],
    );

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
