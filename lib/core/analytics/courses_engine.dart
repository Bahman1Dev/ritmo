import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class CoursesEngineInput {

  CoursesEngineInput({
    required this.courses,
    required this.sessions,
    required this.currentEnergyLevel,
    required this.today,
  });
  final List<Course> courses;
  final List<CourseSession> sessions;
  final String currentEnergyLevel; // e.g. HIGH, MEDIUM, LOW
  final DateTime today;
}

class CoursesEngineOutput { // courseId -> estimated end date

  CoursesEngineOutput({
    required this.weeklyDoneSessions,
    required this.weeklyTargetSessions,
    required this.weeklyStudyMinutes,
    required this.studyStreakDays,
    required this.behindSchedule,
    required this.todaySessions,
    required this.estimatedEnd,
  });
  final int weeklyDoneSessions;
  final int weeklyTargetSessions;
  final int weeklyStudyMinutes;
  final int studyStreakDays;
  final Map<String, int> behindSchedule; // courseId -> days behind
  final List<CourseSession> todaySessions; // pending sessions scheduled for today
  final Map<String, DateTime?> estimatedEnd;
}

class CoursesEngine implements CachedEngine<CoursesEngineInput, CoursesEngineOutput> {
  @override
  Future<CoursesEngineOutput> calculate(CoursesEngineInput input) async {
    final activeCourses = input.courses.where((c) => c.status == CourseStatus.active && !c.isArchived).toList();
    final activeCourseIds = activeCourses.map((c) => c.id).toSet();

    RitmoLog.debug('COURSES', 'activeCourses size = ${activeCourses.length}');
    RitmoLog.debug('COURSES', 'activeCourseIds = $activeCourseIds');

    final todayStr = _formatDate(input.today);

    // Calculate Farsi week boundaries for current week
    final satOfWeek = CourseScheduler.getSaturdayOfWeek(input.today);
    // Saturday at 00:00:00
    final satStartMs = DateTime(satOfWeek.year, satOfWeek.month, satOfWeek.day).millisecondsSinceEpoch;
    // Next Saturday at 00:00:00 (exclusive) is the end boundary
    final nextSat = satOfWeek.add(const Duration(days: 7));
    final nextSatStartMs = DateTime(nextSat.year, nextSat.month, nextSat.day).millisecondsSinceEpoch;

    // Filter active sessions
    final activeSessions = input.sessions.where((s) => activeCourseIds.contains(s.courseId)).toList();

    RitmoLog.debug('COURSES', 'activeSessions size = ${activeSessions.length}');

    // 1. weeklyDoneSessions & weeklyStudyMinutes
    var weeklyDone = 0;
    var weeklyMinutes = 0;

    for (final session in activeSessions) {
      RitmoLog.debug('COURSES', 'session id = ${session.id}, isCompleted = ${session.isCompleted}, completionStatus = ${session.completionStatus}, updatedAt = ${session.updatedAt}');
      if (session.isCompleted) {
        final compTime = session.updatedAt;
        RitmoLog.debug('COURSES', 'satStartMs = $satStartMs, compTime = $compTime, nextSatStartMs = $nextSatStartMs');
        if (compTime >= satStartMs && compTime < nextSatStartMs) {
          weeklyDone++;
          weeklyMinutes += session.actualDurationMinutes ?? 0;
          RitmoLog.debug('COURSES', 'incremented weeklyDone = $weeklyDone');
        }
      }
    }

    // 2. weeklyTargetSessions
    var totalWeeklyTarget = 0;
    for (final course in activeCourses) {
      totalWeeklyTarget += course.weeklyTargetSessions;
    }

    // 3. studyStreakDays
    final completedDates = <String>{};
    for (final session in input.sessions) {
      if (session.isCompleted) {
        final compDate = DateTime.fromMillisecondsSinceEpoch(session.updatedAt);
        completedDates.add(_formatDate(compDate));
      }
    }

    var streak = 0;
    var checkDate = DateTime(input.today.year, input.today.month, input.today.day);
    final todayFormatted = _formatDate(checkDate);
    final yesterdayFormatted = _formatDate(checkDate.subtract(const Duration(days: 1)));

    final hasStreak = completedDates.contains(todayFormatted) || completedDates.contains(yesterdayFormatted);

    if (hasStreak) {
      // If today doesn't have a session completed but yesterday does, start counting from yesterday
      if (!completedDates.contains(todayFormatted)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (completedDates.contains(_formatDate(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // 4. behindSchedule
    final behindMap = <String, int>{};
    for (final course in activeCourses) {
      final courseSessions = activeSessions.where((s) => s.courseId == course.id).toList();
      final behindCount = CourseScheduler.daysBehind(sessions: courseSessions, today: input.today);
      behindMap[course.id] = behindCount;
    }

    // 5. todaySessions
    final todaySess = <CourseSession>[];
    for (final session in activeSessions) {
      if (session.plannedDate == todayStr && !session.isCompleted) {
        todaySess.add(session);
      }
    }

    // 6. estimatedEnd
    final estEndMap = <String, DateTime?>{};
    for (final course in activeCourses) {
      final courseSessions = activeSessions.where((s) => s.courseId == course.id).toList();
      final pendingCount = courseSessions.where((s) => !s.isCompleted).length;

      final est = CourseScheduler.estimatedEndDate(
        remaining: pendingCount,
        weeklyTarget: course.weeklyTargetSessions,
        from: input.today,
        preferredDays: course.preferredDays,
      );
      estEndMap[course.id] = est;
    }

    return CoursesEngineOutput(
      weeklyDoneSessions: weeklyDone,
      weeklyTargetSessions: totalWeeklyTarget,
      weeklyStudyMinutes: weeklyMinutes,
      studyStreakDays: streak,
      behindSchedule: behindMap,
      todaySessions: todaySess,
      estimatedEnd: estEndMap,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(CoursesEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
