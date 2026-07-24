import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/courses/logic/course_timer_service.dart';

void main() {
  group('CourseTimerService Unit Tests (C8)', () {
    test('ActiveCourseTimer calculateCurrentElapsedSeconds when running', () {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch;

      final timer = ActiveCourseTimer(
        courseId: 'c1',
        sessionId: 's1',
        startedAt: startedAt,
        elapsedSecondsBeforePause: 600, // 10 minutes from previous session
        isPaused: false,
        updatedAt: startedAt,
      );

      final current = timer.calculateCurrentElapsedSeconds(now);
      expect(current, equals(2400)); // 600 + 1800 = 2400 (40 mins)
    });

    test('ActiveCourseTimer calculateCurrentElapsedSeconds when paused', () {
      final now = DateTime.now();
      final timer = ActiveCourseTimer(
        courseId: 'c1',
        sessionId: 's1',
        startedAt: now.millisecondsSinceEpoch,
        elapsedSecondsBeforePause: 1500,
        isPaused: true,
        updatedAt: now.millisecondsSinceEpoch,
      );

      final current = timer.calculateCurrentElapsedSeconds(now);
      expect(current, equals(1500));
    });

    test('ActiveCourseTimer caps elapsed time at 8 hours (28800 seconds)', () {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(hours: 10)).millisecondsSinceEpoch;

      final timer = ActiveCourseTimer(
        courseId: 'c1',
        sessionId: 's1',
        startedAt: startedAt,
        elapsedSecondsBeforePause: 0,
        isPaused: false,
        updatedAt: startedAt,
      );

      final current = timer.calculateCurrentElapsedSeconds(now);
      expect(current, equals(28800)); // Capped at 8 hours
    });
  });
}
