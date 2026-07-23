import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  group('RecurrenceRule & RoutineOccurrenceGenerator Tests', () {
    test('Everyday rule matches all weekdays', () {
      final rule = RecurrenceRule(
        weekdays: [6, 7, 1, 2, 3, 4, 5],
        reminderTimes: ['08:00'],
      );

      final sat = DateTime(2026, 6, 20); // Saturday
      final sun = DateTime(2026, 6, 21); // Sunday
      final mon = DateTime(2026, 6, 22); // Monday

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sat, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sun, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(mon, rule), isTrue);
    });

    test('Workdays rule matches Sat to Wed only', () {
      final rule = RecurrenceRule(
        weekdays: [6, 7, 1, 2, 3], // Sat, Sun, Mon, Tue, Wed
        reminderTimes: ['08:00'],
      );

      final sat = DateTime(2026, 6, 20); // Sat (6) -> true
      final wed = DateTime(2026, 6, 24); // Wed (3) -> true
      final thu = DateTime(2026, 6, 25); // Thu (4) -> false
      final fri = DateTime(2026, 6, 26); // Fri (5) -> false

      expect(sat.weekday, equals(DateTime.saturday));
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sat, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(wed, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(thu, rule), isFalse);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(fri, rule), isFalse);
    });

    test('Interval rule matches every N days starting from startDate', () {
      final rule = RecurrenceRule(
        weekdays: [],
        intervalDays: 3,
        startDate: DateTime(2026, 6, 20), // Saturday
        reminderTimes: ['08:00'],
      );

      final sat = DateTime(2026, 6, 20); // day 0 -> true
      final sun = DateTime(2026, 6, 21); // day 1 -> false
      final tue = DateTime(2026, 6, 23); // day 3 -> true

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sat, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sun, rule), isFalse);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(tue, rule), isTrue);
    });

    test('Monthly rule matches specific day of month', () {
      final rule = RecurrenceRule(
        weekdays: [],
        monthDay: 15,
        reminderTimes: ['08:00'],
      );

      final date15 = DateTime(2026, 6, 15);
      final date16 = DateTime(2026, 6, 16);

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(date15, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(date16, rule), isFalse);
    });

    test('Weekly pattern matches specific weekdays with multi-week intervals', () {
      final rule = RecurrenceRule(
        weekdays: [6, 1], // Saturday, Monday
        intervalDays: 14, // Every 2 weeks
        startDate: DateTime(2026, 6, 20), // Saturday
        reminderTimes: ['08:00'],
      );

      final satWeek1 = DateTime(2026, 6, 20); // Sat same week -> true
      final monWeek1 = DateTime(2026, 6, 22); // Mon same week -> true
      final satWeek2 = DateTime(2026, 6, 27); // Sat next week -> false
      final satWeek3 = DateTime(2026, 7, 4);  // Sat 2 weeks later -> true

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(satWeek1, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(monWeek1, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(satWeek2, rule), isFalse);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(satWeek3, rule), isTrue);
    });

    test('Excluded dates are skipped', () {
      final rule = RecurrenceRule(
        weekdays: [6, 7, 1, 2, 3, 4, 5],
        excludedDates: [DateTime(2026, 6, 22)], // Monday
        reminderTimes: ['08:00'],
      );

      final sat = DateTime(2026, 6, 20);
      final mon = DateTime(2026, 6, 22);

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(sat, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(mon, rule), isFalse);
    });

    test('Hourly recurrence matches correct days for intervalHours = 8', () {
      final rule = RecurrenceRule(
        weekdays: [],
        intervalHours: 8,
        startDate: DateTime(2026, 6, 20, 8),
        reminderTimes: [],
      );

      final day20 = DateTime(2026, 6, 20);
      final day21 = DateTime(2026, 6, 21);
      final day22 = DateTime(2026, 6, 22);

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day20, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day21, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day22, rule), isTrue);
    });

    test('Hourly recurrence matches correct days for intervalHours = 48', () {
      final rule = RecurrenceRule(
        weekdays: [],
        intervalHours: 48,
        startDate: DateTime(2026, 6, 20, 8),
        reminderTimes: [],
      );

      final day20 = DateTime(2026, 6, 20);
      final day21 = DateTime(2026, 6, 21);
      final day22 = DateTime(2026, 6, 22);
      final day23 = DateTime(2026, 6, 23);
      final day24 = DateTime(2026, 6, 24);

      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day20, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day21, rule), isFalse);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day22, rule), isTrue);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day23, rule), isFalse);
      expect(RoutineOccurrenceGenerator.shouldOccurOnDate(day24, rule), isTrue);
    });
  });
}
