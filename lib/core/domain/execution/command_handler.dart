import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'command_context.dart';
import 'kernel_mutation_result.dart';

abstract interface class KernelCommandHandler<T extends KernelCommand> {
  Future<KernelMutationResult> handle(
    CommandContext context,
    T command,
  );
}
