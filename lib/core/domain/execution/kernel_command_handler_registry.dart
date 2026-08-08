import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/handlers/reschedule_occurrence_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/undo_completion_handler.dart';
import 'command_handler.dart';

class KernelCommandHandlerRegistry {
  const KernelCommandHandlerRegistry({
    required this.createRoutineHandler,
    required this.editRoutineHandler,
    required this.deleteRoutineHandler,
    required this.archiveRoutineHandler,
    required this.unarchiveRoutineHandler,
    required this.completeOccurrenceHandler,
    required this.skipOccurrenceHandler,
    required this.snoozeReminderHandler,
    required this.confirmReshuffleHandler,
    required this.testAlarmHandler,
    this.rescheduleOccurrenceHandler = const RescheduleOccurrenceHandler(),
    this.undoCompletionHandler = const UndoCompletionHandler(),
  });

  final KernelCommandHandler<CreateRoutineCommand> createRoutineHandler;
  final KernelCommandHandler<EditRoutineCommand> editRoutineHandler;
  final KernelCommandHandler<DeleteRoutineCommand> deleteRoutineHandler;
  final KernelCommandHandler<ArchiveRoutineCommand> archiveRoutineHandler;
  final KernelCommandHandler<UnarchiveRoutineCommand> unarchiveRoutineHandler;
  final KernelCommandHandler<CompleteOccurrenceCommand> completeOccurrenceHandler;
  final KernelCommandHandler<SkipOccurrenceCommand> skipOccurrenceHandler;
  final KernelCommandHandler<SnoozeReminderCommand> snoozeReminderHandler;
  final KernelCommandHandler<ConfirmReshuffleCommand> confirmReshuffleHandler;
  final KernelCommandHandler<TestAlarmCommand> testAlarmHandler;
  final KernelCommandHandler<RescheduleOccurrenceCommand> rescheduleOccurrenceHandler;
  final KernelCommandHandler<UndoCompletionCommand> undoCompletionHandler;

  KernelCommandHandler resolve(KernelCommand command) {
    if (command is CreateRoutineCommand) return createRoutineHandler;
    if (command is EditRoutineCommand) return editRoutineHandler;
    if (command is DeleteRoutineCommand) return deleteRoutineHandler;
    if (command is ArchiveRoutineCommand) return archiveRoutineHandler;
    if (command is UnarchiveRoutineCommand) return unarchiveRoutineHandler;
    if (command is CompleteOccurrenceCommand) return completeOccurrenceHandler;
    if (command is SkipOccurrenceCommand) return skipOccurrenceHandler;
    if (command is SnoozeReminderCommand) return snoozeReminderHandler;
    if (command is ConfirmReshuffleCommand) return confirmReshuffleHandler;
    if (command is TestAlarmCommand) return testAlarmHandler;
    if (command is RescheduleOccurrenceCommand) return rescheduleOccurrenceHandler;
    if (command is UndoCompletionCommand) return undoCompletionHandler;
    throw UnsupportedError('No handler registered for ${command.runtimeType}');
  }
}
