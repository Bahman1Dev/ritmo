import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class AdaptiveAdjustmentResult {
  AdaptiveAdjustmentResult({
    required this.courseId,
    required this.oldWeeklyTarget,
    required this.newWeeklyTarget,
    required this.reasonFa,
    required this.appliedAt,
  });

  final String courseId;
  final int oldWeeklyTarget;
  final int newWeeklyTarget;
  final String reasonFa;
  final DateTime appliedAt;
}

class CourseAdaptiveEngine {
  static Future<AdaptiveAdjustmentResult?> evaluateAndAdjustCourse({
    required Course course,
    required List<CourseSession> sessions,
    required DateTime today,
  }) async {
    if (!course.isAdaptive) return null;

    final nowMs = today.millisecondsSinceEpoch;

    // 1. Guard: Check if applied in last 14 days
    if (course.adaptiveLastAppliedAt != null) {
      final daysSinceLast = (nowMs - course.adaptiveLastAppliedAt!) / (1000 * 60 * 60 * 24);
      if (daysSinceLast < 14) {
        return null;
      }
    }

    final overdueCount = CourseScheduler.daysBehind(sessions: sessions, today: today);

    int proposedTarget = course.weeklyTargetSessions;
    String? reason;

    if (overdueCount >= 6 && course.weeklyTargetSessions > 1) {
      proposedTarget = course.weeklyTargetSessions - 1;
      reason = 'به دلیل انباشت ۶ جلسه معوقه، ریتم هفتگی برای جلوگیری از فشار مطالعه به $proposedTarget جلسه کاهش یافت.';
    } else {
      // Check last 2 weeks completion rate
      final satCurrent = CourseScheduler.getSaturdayOfWeek(today);
      final satPrev1 = satCurrent.subtract(const Duration(days: 7));
      final satPrev2 = satCurrent.subtract(const Duration(days: 14));

      final sat1Ms = satPrev1.millisecondsSinceEpoch;
      final sat2Ms = satPrev2.millisecondsSinceEpoch;

      final prevWeek1Done = sessions.where((s) => s.isCompleted && s.completedAt != null && s.completedAt! >= sat1Ms && s.completedAt! < satCurrent.millisecondsSinceEpoch).length;
      final prevWeek2Done = sessions.where((s) => s.isCompleted && s.completedAt != null && s.completedAt! >= sat2Ms && s.completedAt! < sat1Ms).length;

      if (prevWeek1Done >= course.weeklyTargetSessions * 1.5 && prevWeek2Done >= course.weeklyTargetSessions * 1.5) {
        proposedTarget = (course.weeklyTargetSessions + 1).clamp(1, 14);
        reason = 'به دلیل سرعت بالای مطالعه شما در دو هفته گذشته، ریتم هفتگی به $proposedTarget جلسه افزایش یافت! 🚀';
      } else if (prevWeek1Done < course.weeklyTargetSessions * 0.5 && prevWeek2Done < course.weeklyTargetSessions * 0.5 && course.weeklyTargetSessions > 1) {
        proposedTarget = (course.weeklyTargetSessions - 1).clamp(1, 14);
        reason = 'به دلیل مشغله زیاد در دو هفته اخیر، هدف هفتگی به $proposedTarget جلسه تنظیم شد تا ریتم یادگیری حفظ شود.';
      }
    }

    if (proposedTarget == course.weeklyTargetSessions || reason == null) {
      return null;
    }

    final updatedCourse = course.copyWith(
      weeklyTargetSessions: proposedTarget,
      adaptiveLastAppliedAt: nowMs,
      updatedAt: nowMs,
    );

    await CoursesRepository.instance.updateCourse(updatedCourse);

    return AdaptiveAdjustmentResult(
      courseId: course.id,
      oldWeeklyTarget: course.weeklyTargetSessions,
      newWeeklyTarget: proposedTarget,
      reasonFa: reason,
      appliedAt: today,
    );
  }
}
