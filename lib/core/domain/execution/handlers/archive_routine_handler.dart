import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';

class ArchiveRoutineHandler implements KernelCommandHandler<ArchiveRoutineCommand> {
  const ArchiveRoutineHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    ArchiveRoutineCommand command,
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
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed' OR state = 'active')",
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
        'state': ReminderState.cancelled.dbValue,
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed' OR state = 'active')",
      whereArgs: [id],
    );

    // Cancel future pending occurrences, but keep history
    final todayStr = RitmoDate.now().value;
    await context.txn.delete(
      'routine_occurrences',
      where: "routine_id = ? AND date >= ? AND status = 'pending'",
      whereArgs: [id, todayStr],
    );

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: id,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}

class UnarchiveRoutineHandler implements KernelCommandHandler<UnarchiveRoutineCommand> {
  const UnarchiveRoutineHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    UnarchiveRoutineCommand command,
  ) async {
    final id = command.routineId;

    await context.txn.update(
      'routines',
      {
        'isArchived': 0,
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: id,
        ),
      ],
      postCommitTasks: tasks,
    );
  }

  List<Future<void> Function()> get tasks => [SnapshotSyncService.syncAll];
}
