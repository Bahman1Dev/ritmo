import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/models.dart';

class ReshuffleEvent {

  ReshuffleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isLocked = false,
  });
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isLocked;
}

enum ReshuffleActionType {
  compress,
  shiftWithinZone,
  shiftToNextZone,
  moveToTomorrow,
}

class ReshuffleAction {

  ReshuffleAction({
    required this.routineId,
    required this.routineTitle,
    required this.actionType,
    this.originalDuration,
    this.newDuration,
    this.originalTime,
    this.newTime,
  });
  final String routineId;
  final String routineTitle;
  final ReshuffleActionType actionType;
  final int? originalDuration;
  final int? newDuration;
  final DateTime? originalTime;
  final DateTime? newTime;

  Map<String, dynamic> toJson() => {
    'routineId': routineId,
    'routineTitle': routineTitle,
    'actionType': actionType.name,
    'originalDuration': originalDuration,
    'newDuration': newDuration,
    'originalTime': originalTime?.millisecondsSinceEpoch,
    'newTime': newTime?.millisecondsSinceEpoch,
  };
}

class ReshuffleResult {

  ReshuffleResult({
    required this.success,
    required this.actions,
    this.message,
    this.capacityExhaustedTomorrow = false,
  });
  final bool success;
  final List<ReshuffleAction> actions;
  final String? message;
  final bool capacityExhaustedTomorrow;
}

class ReshuffleEngine {
  /// Pure function to calculate moveability score for a routine.
  /// Higher score means it is easier to move or modify.
  static double calculateMoveabilityScore(Routine routine) {
    var score = 0.0;

    // 1. Category base score


    // 2. Flexibility in duration (light or minimal versions)
    if (routine.lightDurationMinutes != null) {
      score += 15.0;
    }
    if (routine.minimalDurationMinutes != null) {
      score += 25.0;
    }

    // 3. Time flexibility: non-rigid routines (like interval or asNeeded)
    if (routine.routineType == RoutineType.asNeeded ||
        routine.routineType == RoutineType.intervalBased) {
      score += 20.0;
    }

    // 4. Base priority reduces moveability (highly important routines stay put)
    score -= routine.priority * 5.0;

    return score;
  }

  /// Evaluates smart reshuffle logic purely.
  static ReshuffleResult decideReshuffle({
    required ReshuffleEvent event,
    required List<RoutineTask> todayTasks,
    required List<RoutineTask> tomorrowTasks,
    required Set<String> preferredRoutineIds,
    required int maxCapacityMinutesTomorrow,
  }) {
    final proposedActions = <ReshuffleAction>[];

    // Find today's tasks that overlap with the new event
    final conflictingTasks = todayTasks.where((task) {
      final taskStart = task.scheduledTime;
      final taskDuration = Duration(minutes: task.routine.targetDurationMinutes ?? 30);
      final taskEnd = taskStart.add(taskDuration);

      // Check for overlap
      return taskStart.isBefore(event.endTime) && taskEnd.isAfter(event.startTime);
    }).toList();

    if (conflictingTasks.isEmpty) {
      return ReshuffleResult(success: true, actions: []);
    }

    // Check if any conflicting task is absolute locked/essential
    final lockedConflicts = conflictingTasks.where((task) {
      return task.routine.isEssential || preferredRoutineIds.contains(task.routine.id);
    }).toList();

    if (lockedConflicts.isNotEmpty) {
      final lockedTitles = lockedConflicts.map((t) => t.routine.title).join('، ');
      return ReshuffleResult(
        success: false,
        actions: [],
        message: 'امکان جابه‌جایی وجود ندارد زیرا با روتین‌های حیاتی تداخل دارد: $lockedTitles',
      );
    }

    // Sort conflicting tasks by moveability score descending (easiest to move first)
    conflictingTasks.sort((a, b) =>
        calculateMoveabilityScore(b.routine).compareTo(calculateMoveabilityScore(a.routine)));

    var minutesNeeded = event.durationMinutes;

    for (final task in conflictingTasks) {
      if (minutesNeeded <= 0) break;

      final originalDuration = task.routine.targetDurationMinutes ?? 30;

      // Strategy A: Compression (Fashorde-sazi)
      if (task.routine.minimalDurationMinutes != null &&
          task.routine.minimalDurationMinutes! < originalDuration) {
        final minDur = task.routine.minimalDurationMinutes!;
        final saved = originalDuration - minDur;
        proposedActions.add(ReshuffleAction(
          routineId: task.routine.id,
          routineTitle: task.routine.title,
          actionType: ReshuffleActionType.compress,
          originalDuration: originalDuration,
          newDuration: minDur,
        ));
        minutesNeeded -= saved;
        continue;
      } else if (task.routine.lightDurationMinutes != null &&
          task.routine.lightDurationMinutes! < originalDuration) {
        final lightDur = task.routine.lightDurationMinutes!;
        final saved = originalDuration - lightDur;
        proposedActions.add(ReshuffleAction(
          routineId: task.routine.id,
          routineTitle: task.routine.title,
          actionType: ReshuffleActionType.compress,
          originalDuration: originalDuration,
          newDuration: lightDur,
        ));
        minutesNeeded -= saved;
        continue;
      }

      // Strategy B/C: Shift to free slots of the day (mocked/stubbed as shifting time)
      // For simplicity, we pretend we shift it by the event duration.
      final newScheduledTime = task.scheduledTime.add(Duration(minutes: event.durationMinutes));
      if (newScheduledTime.day == task.scheduledTime.day) {
        proposedActions.add(ReshuffleAction(
          routineId: task.routine.id,
          routineTitle: task.routine.title,
          actionType: ReshuffleActionType.shiftWithinZone,
          originalTime: task.scheduledTime,
          newTime: newScheduledTime,
        ));
        minutesNeeded -= originalDuration;
        continue;
      }

      // Strategy D: Move to Tomorrow (Checking Capacity)
      final tomorrowRoutinesDuration = tomorrowTasks.fold<int>(
          0, (sum, t) => sum + (t.routine.targetDurationMinutes ?? 30));

      final freeMinutesTomorrow = maxCapacityMinutesTomorrow - tomorrowRoutinesDuration;

      if (freeMinutesTomorrow >= originalDuration) {
        // We have capacity tomorrow
        proposedActions.add(ReshuffleAction(
          routineId: task.routine.id,
          routineTitle: task.routine.title,
          actionType: ReshuffleActionType.moveToTomorrow,
          originalTime: task.scheduledTime,
          newTime: task.scheduledTime.add(const Duration(days: 1)),
        ));
        minutesNeeded -= originalDuration;
      } else {
        // Recursive capacity resolution on tomorrow's tasks (depth = 1)
        final compressibleTomorrowTasks = tomorrowTasks.where((t) {
          return !t.routine.isEssential &&
              !preferredRoutineIds.contains(t.routine.id) &&
              (t.routine.minimalDurationMinutes != null ||
                  t.routine.lightDurationMinutes != null);
        }).toList();

        // Sort tomorrow's compressible tasks by moveability score descending
        compressibleTomorrowTasks.sort((a, b) =>
            calculateMoveabilityScore(b.routine).compareTo(calculateMoveabilityScore(a.routine)));

        var freedTomorrow = 0;
        final tomorrowCompressions = <ReshuffleAction>[];

        for (final tomTask in compressibleTomorrowTasks) {
          final tomOriginal = tomTask.routine.targetDurationMinutes ?? 30;
          final tomMin = tomTask.routine.minimalDurationMinutes ?? tomTask.routine.lightDurationMinutes ?? tomOriginal;
          if (tomMin < tomOriginal) {
            freedTomorrow += tomOriginal - tomMin;
            tomorrowCompressions.add(ReshuffleAction(
              routineId: tomTask.routine.id,
              routineTitle: '${tomTask.routine.title} (فردا)',
              actionType: ReshuffleActionType.compress,
              originalDuration: tomOriginal,
              newDuration: tomMin,
            ));
          }
          if (freeMinutesTomorrow + freedTomorrow >= originalDuration) {
            break;
          }
        }

        if (freeMinutesTomorrow + freedTomorrow >= originalDuration) {
          // Yes! Compress tomorrow's tasks and move this to tomorrow
          proposedActions.addAll(tomorrowCompressions);
          proposedActions.add(ReshuffleAction(
            routineId: task.routine.id,
            routineTitle: task.routine.title,
            actionType: ReshuffleActionType.moveToTomorrow,
            originalTime: task.scheduledTime,
            newTime: task.scheduledTime.add(const Duration(days: 1)),
          ));
          minutesNeeded -= originalDuration;
        } else {
          // Capacity completely exhausted tomorrow
          return ReshuffleResult(
            success: false,
            actions: [],
            capacityExhaustedTomorrow: true,
            message: 'فردا هم ظرفیت ندارد. برای اضافه کردن "${event.title}" باید روتین "${task.routine.title}" یا برخی روتین‌های فردا را حذف کنید.',
          );
        }
      }
    }

    if (minutesNeeded > 0) {
      return ReshuffleResult(
        success: false,
        actions: [],
        message: 'امکان باز کردن جا برای تمام مدت زمان رویداد وجود ندارد.',
      );
    }

    return ReshuffleResult(success: true, actions: proposedActions);
  }
}
