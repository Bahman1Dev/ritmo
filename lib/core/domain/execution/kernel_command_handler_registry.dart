import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'command_handler.dart';

class KernelCommandHandlerRegistry {
  const KernelCommandHandlerRegistry({
    required this.createRoutineHandler,
    required this.editRoutineHandler,
    required this.deleteRoutineHandler,
    required this.completeOccurrenceHandler,
    required this.skipOccurrenceHandler,
    required this.snoozeReminderHandler,
    required this.confirmReshuffleHandler,
  });

  final KernelCommandHandler<CreateRoutineCommand> createRoutineHandler;
  final KernelCommandHandler<EditRoutineCommand> editRoutineHandler;
  final KernelCommandHandler<DeleteRoutineCommand> deleteRoutineHandler;
  final KernelCommandHandler<CompleteOccurrenceCommand> completeOccurrenceHandler;
  final KernelCommandHandler<SkipOccurrenceCommand> skipOccurrenceHandler;
  final KernelCommandHandler<SnoozeReminderCommand> snoozeReminderHandler;
  final KernelCommandHandler<ConfirmReshuffleCommand> confirmReshuffleHandler;

  KernelCommandHandler resolve(KernelCommand command) {
    if (command is CreateRoutineCommand) return createRoutineHandler;
    if (command is EditRoutineCommand) return editRoutineHandler;
    if (command is DeleteRoutineCommand) return deleteRoutineHandler;
    if (command is CompleteOccurrenceCommand) return completeOccurrenceHandler;
    if (command is SkipOccurrenceCommand) return skipOccurrenceHandler;
    if (command is SnoozeReminderCommand) return snoozeReminderHandler;
    if (command is ConfirmReshuffleCommand) return confirmReshuffleHandler;
    throw UnsupportedError('No handler registered for ${command.runtimeType}');
  }
}
