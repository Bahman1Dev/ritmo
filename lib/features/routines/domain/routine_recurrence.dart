import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Sealed hierarchy representing routine recurrence configuration.
@immutable
sealed class RoutineRecurrence {
  const RoutineRecurrence();
}

class DailyRecurrence extends RoutineRecurrence {
  const DailyRecurrence();
}

class WeekdaysRecurrence extends RoutineRecurrence {
  const WeekdaysRecurrence({required this.weekdays})
      : assert(weekdays.length > 0, 'Weekdays set cannot be empty');

  final Set<int> weekdays; // 1 (Mon) to 7 (Sun)
}

class IntervalRecurrence extends RoutineRecurrence {
  const IntervalRecurrence({required this.days})
      : assert(days > 0, 'Interval days must be positive');

  final int days;
}

class MonthlyRecurrence extends RoutineRecurrence {
  const MonthlyRecurrence({required this.monthDay})
      : assert(monthDay >= 1 && monthDay <= 31, 'Month day must be between 1 and 31');

  final int monthDay;
}

class OnceRecurrence extends RoutineRecurrence {
  const OnceRecurrence({required this.date});

  final DateTime date;
}

/// Helper functions for encoding recurrence rules securely.
String encodeRecurrenceRule({
  required RoutineRecurrence recurrence,
  required DateTime startDate,
  DateTime? endDate,
  required List<String> reminderTimes,
}) {
  assert(
    reminderTimes.isNotEmpty,
    'reminderTimes parameter is mandatory and cannot be empty',
  );

  final startDateStr =
      '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
  final endDateStr = endDate != null
      ? '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
      : null;

  final Map<String, dynamic> ruleMap = {
    'reminderTimes': reminderTimes,
    'startDate': startDateStr,
    if (endDateStr != null) 'endDate': endDateStr,
  };

  switch (recurrence) {
    case DailyRecurrence():
      ruleMap['weekdays'] = [1, 2, 3, 4, 5, 6, 7];
      break;
    case WeekdaysRecurrence(:final weekdays):
      ruleMap['weekdays'] = weekdays.toList()..sort();
      break;
    case IntervalRecurrence(:final days):
      ruleMap['intervalDays'] = days;
      break;
    case MonthlyRecurrence(:final monthDay):
      ruleMap['monthDay'] = monthDay;
      break;
    case OnceRecurrence(:final date):
      final dateOnlyStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      ruleMap['startDate'] = dateOnlyStr;
      ruleMap['endDate'] = dateOnlyStr;
      ruleMap['intervalDays'] = 1;
      break;
  }

  return jsonEncode(ruleMap);
}

/// Utility for deriving legacy scheduleType and daysOfWeek string.
(String scheduleType, String daysOfWeek) deriveScheduleParams(RoutineRecurrence recurrence) {
  switch (recurrence) {
    case DailyRecurrence():
      return ('EVERY_DAY', '6,7,1,2,3,4,5');
    case WeekdaysRecurrence(:final weekdays):
      final sorted = weekdays.toList()..sort();
      return ('SPECIFIC_DAYS', sorted.join(','));
    case IntervalRecurrence():
      return ('EVERY_N_DAYS', '');
    case MonthlyRecurrence():
      return ('MONTHLY', '');
    case OnceRecurrence():
      return ('ONCE', '');
  }
}
