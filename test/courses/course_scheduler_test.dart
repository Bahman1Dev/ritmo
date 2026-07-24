import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/logic/course_validation.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('CourseScheduler Unit Tests (C4)', () {
    test('distributeSessions: 7 sessions, weeklyTarget=3, preferredDays=[6,1,3] -> 7 dates, max 3 per week', () {
      final start = DateTime(2026, 8, 1); // Saturday
      final dates = CourseScheduler.distributeSessions(
        pendingCount: 7,
        from: start,
        weeklyTarget: 3,
        preferredDays: [6, 1, 3],
      );

      expect(dates.length, equals(7));

      // Group by Saturday of week
      final weekCounts = <DateTime, int>{};
      for (final d in dates) {
        final sat = CourseScheduler.getSaturdayOfWeek(d);
        weekCounts[sat] = (weekCounts[sat] ?? 0) + 1;
      }

      for (final count in weekCounts.values) {
        expect(count, lessThanOrEqualTo(3));
      }
    });

    test('distributeSessions with weeklyTarget=0 throws CourseValidationException', () {
      expect(
        () => CourseScheduler.distributeSessions(
          pendingCount: 5,
          from: DateTime.now(),
          weeklyTarget: 0,
          preferredDays: [6, 1, 3],
        ),
        throwsA(isA<CourseValidationException>()),
      );
    });

    test('distributeSessions with preferredDays=[9] normalizes to default without crash', () {
      final dates = CourseScheduler.distributeSessions(
        pendingCount: 3,
        from: DateTime(2026, 8, 1),
        weeklyTarget: 3,
        preferredDays: [9],
      );

      expect(dates.length, equals(3));
    });

    test('distributeSessions respects occupiedWeeklyCounts filling current week', () {
      final start = DateTime(2026, 8, 1); // Saturday
      final sat = CourseScheduler.getSaturdayOfWeek(start);

      final dates = CourseScheduler.distributeSessions(
        pendingCount: 3,
        from: start,
        weeklyTarget: 3,
        preferredDays: [6, 1, 3],
        occupiedWeeklyCounts: {sat: 3}, // current week is full!
      );

      expect(dates.length, equals(3));
      for (final d in dates) {
        expect(d.isAfter(start.add(const Duration(days: 6))), isTrue);
      }
    });

    test('distributeSessions respects blockedDates', () {
      final start = DateTime(2026, 8, 1); // Saturday
      final blocked = DateTime(2026, 8, 1);

      final dates = CourseScheduler.distributeSessions(
        pendingCount: 1,
        from: start,
        weeklyTarget: 3,
        preferredDays: [6, 1, 3],
        blockedDates: {blocked},
      );

      expect(dates.first, isNot(equals(blocked)));
    });

    test('daysBehind with SKIPPED session returns 0', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yStr = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final session = CourseSession(
        id: 's1',
        courseId: 'c1',
        sessionNumber: 1,
        plannedDate: yStr,
        completionStatus: SessionStatus.skipped,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final behind = CourseScheduler.daysBehind(
        sessions: [session],
        today: DateTime.now(),
      );

      expect(behind, equals(0));
    });
  });
}
