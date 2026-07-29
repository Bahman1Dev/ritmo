import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';

class UndoCompletionHandler
    implements KernelCommandHandler<UndoCompletionCommand> {
  const UndoCompletionHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    UndoCompletionCommand command,
  ) async {
    final outcome = await CompletionGateway.instance.undo(command.undoToken);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(now: context.now, routineId: 'undo'),
      ],
    );
  }
}
