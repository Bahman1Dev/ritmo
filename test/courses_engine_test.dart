// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/courses_engine.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('CoursesEngine Tests', () {
    test('calculate correctly aggregates statistics and outputs predicted end dates', () async {
      final today = DateTime(2026, 6, 24, 12); // Wednesday
      
      final activeCourse = Course(
        id: 'c1',
        title: 'Flutter Course',
        totalSessions: 10,
        sessionDurationMinutes: 45,
        createdAt: 0,
        updatedAt: 0,
        courseType: CourseType.video,
        preferredDays: [1, 3, 5],
      );

      final completedSession = CourseSession(
        id: 's1',
        courseId: 'c1',
        sessionNumber: 1,
        plannedDate: '2026-06-22',
        completionStatus: 'COMPLETED',
        actualDurationMinutes: 50,
        createdAt: 0,
        // Completed inside current Farsi week: Monday June 22
        updatedAt: DateTime(2026, 6, 22, 10).millisecondsSinceEpoch,
      );

      final pendingToday = CourseSession(
        id: 's2',
        courseId: 'c1',
        sessionNumber: 2,
        plannedDate: '2026-06-24', // Today
        createdAt: 0,
        updatedAt: 0,
      );

      final pendingFuture = CourseSession(
        id: 's3',
        courseId: 'c1',
        sessionNumber: 3,
        plannedDate: '2026-06-26',
        createdAt: 0,
        updatedAt: 0,
      );

      final engine = CoursesEngine();
      final satOfWeekDebug = CourseScheduler.getSaturdayOfWeek(today);
      final satStartMs = DateTime(satOfWeekDebug.year, satOfWeekDebug.month, satOfWeekDebug.day).millisecondsSinceEpoch;
      final nextSat = satOfWeekDebug.add(const Duration(days: 7));
      final nextSatStartMs = DateTime(nextSat.year, nextSat.month, nextSat.day).millisecondsSinceEpoch;
      final compTime = completedSession.updatedAt;

      print('DEBUG: satOfWeek = $satOfWeekDebug');
      print('DEBUG: satStartMs = $satStartMs');
      print('DEBUG: nextSatStartMs = $nextSatStartMs');
      print('DEBUG: compTime = $compTime');
      print('DEBUG: isCompleted = ${completedSession.isCompleted}');
      print('DEBUG: courseId = ${completedSession.courseId}');
      print('DEBUG: course.status = ${activeCourse.status}');
      print('DEBUG: course.isArchived = ${activeCourse.isArchived}');

      final output = await engine.calculate(
        CoursesEngineInput(
          courses: [activeCourse],
          sessions: [completedSession, pendingToday, pendingFuture],
          currentEnergyLevel: 'MEDIUM',
          today: today,
        ),
      );

      expect(output.weeklyDoneSessions, 1);
      expect(output.weeklyTargetSessions, 3);
      expect(output.weeklyStudyMinutes, 50);
      expect(output.todaySessions.length, 1);
      expect(output.todaySessions.first.id, 's2');
      expect(output.behindSchedule['c1'], 0);
      // Completed date was 2026-06-22, and today is 2026-06-24.
      // Since yesterday (2026-06-23) had no completed sessions, the streak is broken (0).
      expect(output.studyStreakDays, 0);
    });

    test('calculate correctly calculates active study streak', () async {
      final today = DateTime(2026, 6, 24); // Wed
      
      final activeCourse = Course(
        id: 'c1',
        title: 'Flutter Course',
        totalSessions: 10,
        sessionDurationMinutes: 45,
        createdAt: 0,
        updatedAt: 0,
        courseType: CourseType.video,
        preferredDays: [1, 3, 5],
      );

      // Completed today (2026-06-24)
      final sessionToday = CourseSession(
        id: 's2',
        courseId: 'c1',
        sessionNumber: 2,
        plannedDate: '2026-06-24',
        completionStatus: 'COMPLETED',
        actualDurationMinutes: 45,
        createdAt: 0,
        updatedAt: DateTime(2026, 6, 24, 10).millisecondsSinceEpoch,
      );

      // Completed yesterday (2026-06-23)
      final sessionYesterday = CourseSession(
        id: 's1',
        courseId: 'c1',
        sessionNumber: 1,
        plannedDate: '2026-06-23',
        completionStatus: 'COMPLETED',
        actualDurationMinutes: 45,
        createdAt: 0,
        updatedAt: DateTime(2026, 6, 23, 10).millisecondsSinceEpoch,
      );

      final engine = CoursesEngine();
      final output = await engine.calculate(
        CoursesEngineInput(
          courses: [activeCourse],
          sessions: [sessionYesterday, sessionToday],
          currentEnergyLevel: 'MEDIUM',
          today: today,
        ),
      );

      expect(output.studyStreakDays, 2); // 24 and 23 completed -> streak = 2
    });
  });
}
