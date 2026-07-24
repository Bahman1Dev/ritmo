import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/kernel_command_handler_registry.dart';
import 'package:ritmo/core/domain/execution/handlers/complete_occurrence_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/confirm_reshuffle_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/create_routine_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/delete_routine_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/edit_routine_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/skip_occurrence_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/snooze_reminder_handler.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/execution/post_commit_pipeline.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

abstract class KernelCommand {
  const KernelCommand();
}

class CreateRoutineCommand extends KernelCommand {
  const CreateRoutineCommand({
    required this.routineData,
    this.scheduleData,
  });
  final Map<String, dynamic> routineData;
  final Map<String, dynamic>? scheduleData;
}

class EditRoutineCommand extends KernelCommand {
  const EditRoutineCommand({
    required this.routineId,
    required this.routineData,
    this.scheduleData,
    this.applyToAll = false,
  });
  final String routineId;
  final Map<String, dynamic> routineData;
  final Map<String, dynamic>? scheduleData;
  final bool applyToAll;
}

class DeleteRoutineCommand extends KernelCommand {
  const DeleteRoutineCommand({required this.routineId});
  final String routineId;
}

class CompleteOccurrenceCommand extends KernelCommand {
  const CompleteOccurrenceCommand({
    required this.routineId,
    required this.dateStr,
    required this.resultType,
    required this.durationMinutes,
    this.note,
  });
  final String routineId;
  final String dateStr;
  final String resultType;
  final int durationMinutes;
  final String? note;
}

class SkipOccurrenceCommand extends KernelCommand {
  const SkipOccurrenceCommand({
    required this.routineId,
    required this.dateStr,
    this.reason,
  });
  final String routineId;
  final String dateStr;
  final String? reason;
}

class SnoozeReminderCommand extends KernelCommand {
  const SnoozeReminderCommand({
    required this.reminderId,
    required this.snoozeMinutes,
  });
  final String reminderId;
  final int snoozeMinutes;
}

class ConfirmReshuffleCommand extends KernelCommand {
  const ConfirmReshuffleCommand({required this.actions});
  final List<ReshuffleAction> actions;
}

class RitmoExecutionKernel {
  RitmoExecutionKernel._internal()
      : _handlers = const KernelCommandHandlerRegistry(
          createRoutineHandler: CreateRoutineHandler(),
          editRoutineHandler: EditRoutineHandler(),
          deleteRoutineHandler: DeleteRoutineHandler(),
          completeOccurrenceHandler: CompleteOccurrenceHandler(),
          skipOccurrenceHandler: SkipOccurrenceHandler(),
          snoozeReminderHandler: SnoozeReminderHandler(),
          confirmReshuffleHandler: ConfirmReshuffleHandler(),
        );

  static final RitmoExecutionKernel instance = RitmoExecutionKernel._internal();

  final RitmoEventBus _eventBus = RitmoEventBus();
  final KernelCommandHandlerRegistry _handlers;

  Future<void> execute(KernelCommand command) async {
    final db = await DatabaseHelper.instance.database;
    late KernelMutationResult result;

    await db.transaction((txn) async {
      final context = CommandContext(
        txn: txn,
        now: DateTime.now(),
      );

      final handler = _handlers.resolve(command);
      result = await handler.handle(context, command);
    });

    await PostCommitPipeline.run(result.postCommitTasks);

    for (final event in result.domainEvents) {
      _eventBus.fire(event);
    }
  }

  Future<void> reconcileExternalState() async {
    await SnapshotSyncService.syncAll();
  }
}
