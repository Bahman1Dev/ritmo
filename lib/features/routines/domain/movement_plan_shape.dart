// lib/features/routines/domain/movement_plan_shape.dart

/// Enumeration of the 4 distinct shapes of movement in Ritmo.
enum MovementPlanShape {
  /// Daily/recurring movement habit (e.g. Walking 30m every morning) -> stored in `routines`
  habit('HABIT', 'عادت حرکتی', '🚶'),

  /// Scheduled sport appointment/meetup (e.g. Football Thursday 9 PM at Azadi) -> stored in `routines` with `movementIsMeetup = 1`
  meetup('MEETUP', 'قرار ورزشی', '⚽'),

  /// Structured strength training session -> stored in `ss_workout_plan`
  structuredSession('STRUCTURED_SESSION', 'جلسه برنامه‌دار قدرتی', '🏋️'),

  /// Retrospective logged activity -> stored in `workout_logs`
  retrospectiveLog('RETROSPECTIVE_LOG', 'ثبت گذشته‌نگر فعالیت', '⚡');

  const MovementPlanShape(this.code, this.titleFa, this.emoji);
  final String code;
  final String titleFa;
  final String emoji;

  static MovementPlanShape detect(Map<String, dynamic> map) {
    if (map.containsKey('workoutName') || map.containsKey('planId')) {
      return MovementPlanShape.structuredSession;
    }
    final isMeetup = (map['movementIsMeetup'] as int? ?? 0) == 1;
    if (isMeetup) {
      return MovementPlanShape.meetup;
    }
    if (map.containsKey('movementKind') || map['category'] == 'fitness') {
      return MovementPlanShape.habit;
    }
    return MovementPlanShape.retrospectiveLog;
  }
}
