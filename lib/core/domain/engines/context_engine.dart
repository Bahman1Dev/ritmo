import 'package:ritmo/core/domain/engines/notification_decider.dart';
import 'package:ritmo/core/domain/models.dart';

class RoutineTask {

  RoutineTask({
    required this.routine,
    this.scheduleTimeStr,
    required this.scheduledTime,
  });
  final Routine routine;
  final String? scheduleTimeStr; // e.g., "08:00"
  final DateTime scheduledTime;
}

class ContextEngine {
  /// Resolves the next proposed task based on priorities and current decider status.
  static RoutineTask? getNextProposedTask({
    required List<RoutineTask> activeTasksForToday,
    required List<String> completedRoutineIdsToday,
    required Map<String, String> appSettings,
    required Set<String> blockedZoneIdsForRoutines,
    bool isMenstruating = false,
  }) {
    // 1. Filter out already completed tasks
    final remainingTasks = activeTasksForToday.where((task) {
      return !completedRoutineIdsToday.contains(task.routine.id);
    }).toList();

    if (remainingTasks.isEmpty) {
      return null;
    }

    // 2. Sort remaining tasks by priority descending, then by scheduled time ascending
    remainingTasks.sort((a, b) {
      // High priority first
      final priorityCompare = b.routine.priority.compareTo(a.routine.priority);
      if (priorityCompare != 0) return priorityCompare;
      // Earlier time first
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    // 3. Find the first task that is resolved as executable (not skipped/deferred/ignored)
    for (final task in remainingTasks) {
      final isBlocked = blockedZoneIdsForRoutines.contains(task.routine.id);

      final outcome = NotificationDecider.decide(
        routine: task.routine,
        appSettings: appSettings,
        isCurrentZoneBlocked: isBlocked,
        isMenstruating: isMenstruating,
      );

      if (outcome == DecisionOutcome.sendStandard ||
          outcome == DecisionOutcome.offerLight ||
          outcome == DecisionOutcome.offerMinimal) {
        return task;
      }
    }

    return null; // No available task matches current context
  }
}
