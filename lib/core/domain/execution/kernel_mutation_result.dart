import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'post_commit_task.dart';

class KernelMutationResult {
  const KernelMutationResult({
    this.domainEvents = const [],
    this.postCommitTasks = const [],
  });

  final List<RitmoEvent> domainEvents;
  final List<PostCommitTask> postCommitTasks;

  static const empty = KernelMutationResult();

  KernelMutationResult merge(KernelMutationResult other) {
    return KernelMutationResult(
      domainEvents: [...domainEvents, ...other.domainEvents],
      postCommitTasks: [...postCommitTasks, ...other.postCommitTasks],
    );
  }
}
