import 'package:ritmo/core/domain/models/completion_result.dart';

/// Sealed class hierarchy representing any completion or state-change request.
sealed class CompletionRequest {
  const CompletionRequest();
}

final class RoutineCompletion extends CompletionRequest {
  const RoutineCompletion({
    required this.routineId,
    required this.dateStr,
    this.result = CompletionResult.full,
    this.durationMinutes = 0,
    this.partialRatio,
  });

  final String routineId;
  final String dateStr;
  final CompletionResult result;
  final int durationMinutes;
  final double? partialRatio;
}

final class RoutineSkip extends CompletionRequest {
  const RoutineSkip({
    required this.routineId,
    required this.dateStr,
    this.reason,
  });

  final String routineId;
  final String dateStr;
  final String? reason;
}

final class RoutineReschedule extends CompletionRequest {
  const RoutineReschedule({
    required this.routineId,
    required this.fromDateStr,
    required this.toDateStr,
    this.reason,
  });

  final String routineId;
  final String fromDateStr;
  final String toDateStr;
  final String? reason;
}

final class RoutineSnooze extends CompletionRequest {
  const RoutineSnooze({
    required this.reminderId,
    required this.dateStr,
    required this.snoozeMinutes,
  });

  final String reminderId;
  final String dateStr;
  final int snoozeMinutes;
}

final class CourseSessionCompletion extends CompletionRequest {
  const CourseSessionCompletion({
    required this.sessionId,
    required this.courseId,
    required this.dateStr,
    this.durationMinutes = 0,
  });

  final String sessionId;
  final String courseId;
  final String dateStr;
  final int durationMinutes;
}

final class KonkurSessionCompletion extends CompletionRequest {
  const KonkurSessionCompletion({
    required this.topicId,
    required this.subjectId,
    required this.dateStr,
    this.durationMinutes = 0,
    this.questionsCount = 0,
  });

  final String topicId;
  final String subjectId;
  final String dateStr;
  final int durationMinutes;
  final int questionsCount;
}

final class WorshipCompletion extends CompletionRequest {
  const WorshipCompletion({
    required this.worshipId,
    required this.dateStr,
    this.count = 1,
  });

  final String worshipId;
  final String dateStr;
  final int count;
}

final class GoalStepCompletion extends CompletionRequest {
  const GoalStepCompletion({
    required this.goalId,
    required this.stepId,
    required this.dateStr,
    this.isCompleted = true,
  });

  final String goalId;
  final String stepId;
  final String dateStr;
  final bool isCompleted;
}

final class MedicationTake extends CompletionRequest {
  const MedicationTake({
    required this.medicationId,
    required this.dateStr,
    this.doseTime,
  });

  final String medicationId;
  final String dateStr;
  final String? doseTime;
}

final class MovementCompletion extends CompletionRequest {
  const MovementCompletion({
    required this.kindCode,
    required this.durationMinutes,
    required this.dateStr,
    this.intensity = 'MEDIUM',
  });

  final String kindCode;
  final int durationMinutes;
  final String dateStr;
  final String intensity;
}
