import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class CatchupPlan {
  CatchupPlan({
    required this.courseId,
    required this.overdueSessionsCount,
    required this.proposedWeeklyTarget,
    required this.rescheduledSessions,
    required this.suggestedSkipsCount,
    required this.messageFa,
  });

  final String courseId;
  final int overdueSessionsCount;
  final int proposedWeeklyTarget;
  final List<CourseSession> rescheduledSessions;
  final int suggestedSkipsCount;
  final String messageFa;
}

class CourseCatchupEngine {
  static CatchupPlan generateCatchupPlan({
    required Course course,
    required List<CourseSession> sessions,
    required DateTime today,
    int maxAdditionalWeeklyTarget = 2,
  }) {
    final overdueCount = CourseScheduler.daysBehind(sessions: sessions, today: today);

    if (overdueCount <= 0) {
      return CatchupPlan(
        courseId: course.id,
        overdueSessionsCount: 0,
        proposedWeeklyTarget: course.weeklyTargetSessions,
        rescheduledSessions: [],
        suggestedSkipsCount: 0,
        messageFa: 'شما کاملاً بر طبق برنامه‌ریزی پیش می‌روید! 👏',
      );
    }

    // Proposed new weekly target (cap at 14)
    final proposedTarget = (course.weeklyTargetSessions + maxAdditionalWeeklyTarget).clamp(1, 14);

    final pendingToReschedule = sessions.where((s) => !s.isCompleted && !s.isSkipped).toList();

    final newDates = CourseScheduler.distributeSessions(
      pendingCount: pendingToReschedule.length,
      from: today,
      weeklyTarget: proposedTarget,
      preferredDays: course.preferredDays,
    );

    final rescheduled = <CourseSession>[];
    for (var i = 0; i < pendingToReschedule.length; i++) {
      final session = pendingToReschedule[i];
      String? dateStr;
      if (i < newDates.length) {
        final dt = newDates[i];
        dateStr = '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      rescheduled.add(session.copyWith(plannedDate: dateStr));
    }

    int suggestedSkips = 0;
    if (overdueCount > 10) {
      suggestedSkips = overdueCount - 10;
    }

    final msg = overdueCount > 5
        ? 'شما $overdueCount جلسه از برنامه عقب هستید. پیشنهاد می‌کنیم هدف هفتگی را به $proposedTarget جلسه افزایش دهید تا ظرف ۳ هفته جبران شود.'
        : 'شما $overdueCount جلسه عقب هستید. جلسات معوقه در روزهای آینده زمان‌بندی مجدد شدند.';

    return CatchupPlan(
      courseId: course.id,
      overdueSessionsCount: overdueCount,
      proposedWeeklyTarget: proposedTarget,
      rescheduledSessions: rescheduled,
      suggestedSkipsCount: suggestedSkips,
      messageFa: msg,
    );
  }

  static Future<void> applyCatchupPlan(CatchupPlan plan) async {
    final course = await CoursesRepository.instance.getCourseById(plan.courseId);
    if (course == null) return;

    final updatedCourse = course.copyWith(
      weeklyTargetSessions: plan.proposedWeeklyTarget,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await CoursesRepository.instance.updateCourse(updatedCourse);

    for (final session in plan.rescheduledSessions) {
      await CoursesRepository.instance.rescheduleSession(session.id, session.plannedDate);
    }
  }
}
