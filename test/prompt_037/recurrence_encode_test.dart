import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/routines/domain/routine_recurrence.dart';

void main() {
  group('RoutineRecurrence & encodeRecurrenceRule Tests', () {
    final now = DateTime(2026, 7, 29, 8, 0);

    test('DailyRecurrence encodes correctly with mandatory reminderTimes', () {
      final jsonStr = encodeRecurrenceRule(
        recurrence: const DailyRecurrence(),
        startDate: now,
        reminderTimes: ['08:00'],
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(map['reminderTimes'], equals(['08:00']));
      expect(map['weekdays'], equals([1, 2, 3, 4, 5, 6, 7]));
    });

    test('WeekdaysRecurrence encodes sorted weekdays', () {
      final jsonStr = encodeRecurrenceRule(
        recurrence: const WeekdaysRecurrence(weekdays: {5, 1, 3}),
        startDate: now,
        reminderTimes: ['21:00'],
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(map['weekdays'], equals([1, 3, 5]));
      expect(map['reminderTimes'], equals(['21:00']));
    });

    test('OnceRecurrence sets startDate and endDate to same date', () {
      final targetDate = DateTime(2026, 8, 15);
      final jsonStr = encodeRecurrenceRule(
        recurrence: OnceRecurrence(date: targetDate),
        startDate: now,
        reminderTimes: ['14:00'],
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(map['startDate'], equals('2026-08-15'));
      expect(map['endDate'], equals('2026-08-15'));
      expect(map['intervalDays'], equals(1));
    });

    test('deriveScheduleParams maps recurrence types to legacy schedule parameters', () {
      expect(
        deriveScheduleParams(const DailyRecurrence()),
        equals(('EVERY_DAY', '6,7,1,2,3,4,5')),
      );

      expect(
        deriveScheduleParams(const WeekdaysRecurrence(weekdays: {1, 3, 5})),
        equals(('SPECIFIC_DAYS', '1,3,5')),
      );

      expect(
        deriveScheduleParams(const IntervalRecurrence(days: 3)),
        equals(('EVERY_N_DAYS', '')),
      );

      expect(
        deriveScheduleParams(const MonthlyRecurrence(monthDay: 15)),
        equals(('MONTHLY', '')),
      );

      expect(
        deriveScheduleParams(OnceRecurrence(date: DateTime.now())),
        equals(('ONCE', '')),
      );
    });
  });
}
