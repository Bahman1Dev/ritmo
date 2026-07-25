import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('CourseScheduler Tests', () {
    test('distributeSessions with empty preferredDays schedules on consecutive days', () {
      final start = DateTime(2026, 6, 20); // Saturday
      final dates = CourseScheduler.distributeSessions(
        pendingCount: 3,
        from: start,
        weeklyTarget: 5,
        preferredDays: [],
      );

      expect(dates.length, 3);
      expect(dates[0], DateTime(2026, 6, 20)); // Sat
      expect(dates[1], DateTime(2026, 6, 21)); // Sun
      expect(dates[2], DateTime(2026, 6, 22)); // Mon
    });

    test('distributeSessions respects weeklyTarget and preferredDays', () {
      final start = DateTime(2026, 6, 22); // Monday (weekday=1)
      // preferredDays: Monday (1), Wednesday (3), Friday (5)
      // weeklyTarget: 2 sessions per week
      // pendingCount: 4 sessions
      final dates = CourseScheduler.distributeSessions(
        pendingCount: 4,
        from: start,
        weeklyTarget: 2,
        preferredDays: [1, 3, 5],
      );

      // Week 1 (starts Sat 2026-06-20, ends Fri 2026-06-26):
      // - Monday 2026-06-22 (session 1)
      // - Wednesday 2026-06-24 (session 2)
      // - Friday 2026-06-26 (skipped because week count = 2)

      // Week 2 (starts Sat 2026-06-27, ends Fri 2026-07-03):
      // - Monday 2026-06-29 (session 3)
      // - Wednesday 2026-07-01 (session 4)

      expect(dates.length, 4);
      expect(dates[0], DateTime(2026, 6, 22));
      expect(dates[1], DateTime(2026, 6, 24));
      expect(dates[2], DateTime(2026, 6, 29));
      expect(dates[3], DateTime(2026, 7));
    });

    test('daysBehind calculates pending overdue sessions correctly', () {
      final sessions = [
        CourseSession(
          id: 's1',
          courseId: 'c1',
          sessionNumber: 1,
          plannedDate: '2026-06-20',
          completionStatus: SessionStatus.completed,
          createdAt: 0,
          updatedAt: 0,
        ),
        CourseSession(
          id: 's2',
          courseId: 'c1',
          sessionNumber: 2,
          plannedDate: '2026-06-21',
          createdAt: 0,
          updatedAt: 0,
        ),
        CourseSession(
          id: 's3',
          courseId: 'c1',
          sessionNumber: 3,
          plannedDate: '2026-06-22',
          createdAt: 0,
          updatedAt: 0,
        ),
        CourseSession(
          id: 's4',
          courseId: 'c1',
          sessionNumber: 4,
          plannedDate: '2026-06-25',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final today = DateTime(2026, 6, 23); // June 23
      final behind = CourseScheduler.daysBehind(sessions: sessions, today: today);

      // s1 is completed (no)
      // s2 planned 20th < 23rd (yes)
      // s3 planned 21st < 23rd (yes)
      // s4 planned 25th > 23rd (no)
      // total = 2

      expect(behind, 2);
    });

    test('estimatedEndDate calculates correct last session date', () {
      final start = DateTime(2026, 6, 22); // Monday
      final endDate = CourseScheduler.estimatedEndDate(
        remaining: 4,
        weeklyTarget: 2,
        from: start,
        preferredDays: [1, 3, 5],
      );

      expect(endDate, DateTime(2026, 7));
    });
  });
}
