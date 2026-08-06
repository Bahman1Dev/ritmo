
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

class CoursesEngineOutput {
  CoursesEngineOutput({
    this.planningCourses = const [],
    this.allCourses = const [],
    required this.weeklyDoneSessions,
    this.weeklyTargetSessions = 0,
    required this.weeklyStudyMinutes,
    this.estimatedMinutesIncluded = false,
    this.studyStreakDays = 0,
    this.behindSchedule = const {},
    required this.todaySessions,
    required this.estimatedEnd,
    required this.completionRate,
    required this.scheduleAdherence,
    required this.estimationAccuracy,
    required this.requiredWeeklyPace,
    required this.masteryByCourse,
  });

  final List<Course> planningCourses;
  final List<Course> allCourses;
  final int weeklyDoneSessions;
  final int weeklyTargetSessions;
  final int weeklyStudyMinutes;
  final bool estimatedMinutesIncluded;
  final int studyStreakDays;
  final Map<String, int> behindSchedule; // courseId -> days behind
  final List<CourseSession> todaySessions; // pending sessions scheduled for today
  final Map<String, DateTime?> estimatedEnd;

  final Map<String, double> completionRate; // courseId -> 0..1
  final Map<String, double> scheduleAdherence; // done / scheduled up to today
  final Map<String, double> estimationAccuracy; // actual / estimated
  final Map<String, int> requiredWeeklyPace; // pace needed for targetEndDate
  final Map<String, double> masteryByCourse; // courseId -> 0..100
}

class CoursesEngine implements CachedEngine<CoursesEngineInput, CoursesEngineOutput> {
  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(CoursesEngineInput input) {
    final dayStamp = _formatDate(input.today);
    return '$dayStamp|${input.courses.length}|${input.sessions.length}';
  }

  @override
  void invalidate() {}

  @override
  Future<CoursesEngineOutput> calculate(CoursesEngineInput input) async {
    final coursesMap = <String, Course>{for (final c in input.courses) c.id: c};

    // 1. planningCourses = ONLY active & non-archived courses
    final planningCourses = input.courses.where((c) => c.status == CourseStatus.active && !c.isArchived).toList();

    // 2. achievementSessions = ALL sessions across ALL courses (active, paused, completed)
    final achievementSessions = input.sessions;

    final todayStr = _formatDate(input.today);

    // Calculate Farsi week boundaries for current week
    final satOfWeek = CourseScheduler.getSaturdayOfWeek(input.today);
    final satStartMs = DateTime(satOfWeek.year, satOfWeek.month, satOfWeek.day).millisecondsSinceEpoch;
    final nextSat = satOfWeek.add(const Duration(days: 7));
    final nextSatStartMs = DateTime(nextSat.year, nextSat.month, nextSat.day).millisecondsSinceEpoch;

    // A. Calculate weeklyDoneSessions & weeklyStudyMinutes from achievementSessions
    var weeklyDone = 0;
    var weeklyMinutes = 0;
    var includesEstimatedMinutes = false;

    for (final session in achievementSessions) {
      if (session.isCompleted) {
        int compTimeMs;
        if (session.completedAt != null && session.completedAt! > 0) {
          compTimeMs = session.completedAt!;
        } else {
          RitmoLog.warning('COURSES_ENGINE', 'Session ${session.id} completedAt is null, falling back to updatedAt');
          compTimeMs = session.updatedAt;
        }

        if (compTimeMs >= satStartMs && compTimeMs < nextSatStartMs) {
          weeklyDone++;
          if (session.actualDurationMinutes != null && session.actualDurationMinutes! > 0) {
            weeklyMinutes += session.actualDurationMinutes!;
          } else {
            final course = coursesMap[session.courseId];
            final estimated = course?.sessionDurationMinutes ?? 45;
            weeklyMinutes += estimated;
            includesEstimatedMinutes = true;
          }
        }
      }
    }

    // B. weeklyTargetSessions from planningCourses
    var totalWeeklyTarget = 0;
    for (final course in planningCourses) {
      totalWeeklyTarget += course.weeklyTargetSessions;
    }

    // C. studyStreakDays from achievementSessions
    final completedDates = <String>{};
    for (final session in achievementSessions) {
      if (session.isCompleted) {
        final compMs = (session.completedAt != null && session.completedAt! > 0) ? session.completedAt! : session.updatedAt;
        final compDate = DateTime.fromMillisecondsSinceEpoch(compMs);
        completedDates.add(_formatDate(compDate));
      }
    }

    var streak = 0;
    var checkDate = DateTime(input.today.year, input.today.month, input.today.day);
    final todayFormatted = _formatDate(checkDate);
    final yesterdayFormatted = _formatDate(checkDate.subtract(const Duration(days: 1)));

    final hasStreak = completedDates.contains(todayFormatted) || completedDates.contains(yesterdayFormatted);

    if (hasStreak) {
      if (!completedDates.contains(todayFormatted)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (completedDates.contains(_formatDate(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // D. behindSchedule from planningCourses
    final behindMap = <String, int>{};
    for (final course in planningCourses) {
      final courseSessions = input.sessions.where((s) => s.courseId == course.id).toList();
      final behindCount = CourseScheduler.daysBehind(sessions: courseSessions, today: input.today);
      behindMap[course.id] = behindCount;
    }

    // E. todaySessions from planningCourses
    final todaySess = <CourseSession>[];
    for (final course in planningCourses) {
      final courseSessions = input.sessions.where((s) => s.courseId == course.id).toList();
      for (final session in courseSessions) {
        if (session.plannedDate == todayStr && !session.isCompleted && !session.isSkipped) {
          todaySess.add(session);
        }
      }
    }

    // F. estimatedEnd & requiredWeeklyPace from planningCourses
    final estEndMap = <String, DateTime?>{};
    final paceMap = <String, int>{};

    for (final course in planningCourses) {
      final courseSessions = input.sessions.where((s) => s.courseId == course.id).toList();
      final pendingCount = courseSessions.where((s) => !s.isCompleted && !s.isSkipped).length;

      final est = CourseScheduler.estimatedEndDate(
        remaining: pendingCount,
        weeklyTarget: course.weeklyTargetSessions,
        from: input.today,
        preferredDays: course.preferredDays,
      );
      estEndMap[course.id] = est;

      if (course.targetEndDate != null && course.targetEndDate!.trim().isNotEmpty) {
        final parts = course.targetEndDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            final targetDt = DateTime(y, m, d);
            final daysLeft = targetDt.difference(input.today).inDays;
            if (daysLeft > 0) {
              final weeksLeft = (daysLeft / 7.0).clamp(0.1, 100.0);
              final requiredPace = (pendingCount / weeksLeft).ceil();
              paceMap[course.id] = requiredPace.clamp(1, 21);
            }
          }
        }
      }
    }

    // G. completionRate, scheduleAdherence, estimationAccuracy, masteryByCourse
    final rateMap = <String, double>{};
    final adherenceMap = <String, double>{};
    final accuracyMap = <String, double>{};
    final masteryMap = <String, double>{};

    for (final course in input.courses) {
      final courseSessions = input.sessions.where((s) => s.courseId == course.id).toList();
      final learnSessions = courseSessions.where((s) => s.activityKind != CourseActivityKind.review).toList();
      final completedLearnCount = learnSessions.where((s) => s.isCompleted).length;
      final totalLearnCount = learnSessions.isNotEmpty ? learnSessions.length : course.totalSessions;

      rateMap[course.id] = (totalLearnCount > 0) ? (completedLearnCount / totalLearnCount).clamp(0.0, 1.0) : 0.0;

      // Adherence: done / (scheduled up to today)
      final scheduledUpToToday = courseSessions.where((s) => s.plannedDate != null && s.plannedDate!.compareTo(todayStr) <= 0).toList();
      if (scheduledUpToToday.isNotEmpty) {
        final doneScheduled = scheduledUpToToday.where((s) => s.isCompleted).length;
        adherenceMap[course.id] = (doneScheduled / scheduledUpToToday.length).clamp(0.0, 1.0);
      } else {
        adherenceMap[course.id] = 1.0;
      }

      // Accuracy: actual vs estimated
      final completedWithActual = courseSessions.where((s) => s.isCompleted && s.actualDurationMinutes != null && s.actualDurationMinutes! > 0).toList();
      if (completedWithActual.isNotEmpty) {
        var totalActual = 0;
        var totalEstimated = 0;
        for (final s in completedWithActual) {
          totalActual += s.actualDurationMinutes!;
          totalEstimated += s.estimatedDurationMinutes ?? course.sessionDurationMinutes;
        }
        if (totalEstimated > 0) {
          accuracyMap[course.id] = (totalActual / totalEstimated);
        }
      }

      // Mastery score: calculation
      if (course.masteryScore > 0) {
        masteryMap[course.id] = course.masteryScore;
      } else {
        final scoredSessions = learnSessions.where((s) => s.isCompleted && s.understandingScore != null).toList();
        if (scoredSessions.isNotEmpty) {
          final avgScore = scoredSessions.map((s) => s.understandingScore!).reduce((a, b) => a + b) / scoredSessions.length;
          masteryMap[course.id] = (avgScore / 5.0) * 100;
        } else {
          masteryMap[course.id] = (rateMap[course.id] ?? 0.0) * 100;
        }
      }
    }

    return CoursesEngineOutput(
      planningCourses: planningCourses,
      allCourses: input.courses,
      weeklyDoneSessions: weeklyDone,
      weeklyTargetSessions: totalWeeklyTarget,
      weeklyStudyMinutes: weeklyMinutes,
      estimatedMinutesIncluded: includesEstimatedMinutes,
      studyStreakDays: streak,
      behindSchedule: behindMap,
      todaySessions: todaySess,
      estimatedEnd: estEndMap,
      completionRate: rateMap,
      scheduleAdherence: adherenceMap,
      estimationAccuracy: accuracyMap,
      requiredWeeklyPace: paceMap,
      masteryByCourse: masteryMap,
    );
  }


  @override
  bool canRun(CoursesEngineInput input) => input.courses.isNotEmpty;

  @override
  List<Type> dependencies() => [];

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
