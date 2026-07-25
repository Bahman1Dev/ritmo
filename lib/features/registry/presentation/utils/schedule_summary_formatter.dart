// lib/features/registry/presentation/utils/schedule_summary_formatter.dart

import 'package:ritmo/core/utils/persian_digits.dart';

class ScheduleSummaryFormatter {
  const ScheduleSummaryFormatter._();

  static const Map<int, String> _dayNames = {
    6: 'شنبه',
    7: 'یکشنبه',
    1: 'دوشنبه',
    2: 'سه‌شنبه',
    3: 'چهارشنبه',
    4: 'پنج‌شنبه',
    5: 'جمعه',
  };

  static String format({
    String? scheduleType,
    String? daysOfWeekStr,
    String? timeOfDay,
    String? recurrenceRule,
  }) {
    final parts = <String>[];

    if (daysOfWeekStr != null && daysOfWeekStr.trim().isNotEmpty) {
      final days = daysOfWeekStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toSet();

      if (days.length == 7) {
        parts.add('هر روز');
      } else if (days.length == 5 &&
          days.containsAll([6, 7, 1, 2, 3])) {
        parts.add('شنبه تا چهارشنبه');
      } else if (days.length == 2 && days.containsAll([4, 5])) {
        parts.add('پنج‌شنبه و جمعه');
      } else if (days.isNotEmpty) {
        // Sort in Persian order: 6, 7, 1, 2, 3, 4, 5
        const order = [6, 7, 1, 2, 3, 4, 5];
        final sortedDays = order.where((d) => days.contains(d)).map((d) => _dayNames[d]!).toList();
        parts.add(sortedDays.join('، '));
      }
    } else if (scheduleType == 'DAILY') {
      parts.add('هر روز');
    }

    if (timeOfDay != null && timeOfDay.trim().isNotEmpty) {
      parts.add(toPersianDigits(timeOfDay.trim()));
    }

    if (parts.isEmpty) {
      return 'بدون زمان‌بندی';
    }

    return parts.join(' · ');
  }
}
