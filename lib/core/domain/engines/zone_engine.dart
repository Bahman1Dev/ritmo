class ZoneEngine {
  /// Checks if the given [time] (hours and minutes) is within a zone scheduled from [startTimeStr] to [endTimeStr] (formatted as "HH:mm").
  /// Supports cross-midnight schedules (e.g., 23:00 to 05:00).
  static bool isTimeWithinRange({
    required DateTime time,
    required String startTimeStr,
    required String endTimeStr,
  }) {
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      return false;
    }

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMin = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final startMinutes = startHour * 60 + startMin;
    final endMinutes = endHour * 60 + endMin;
    final currentMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      // Normal range: e.g. 09:00 to 17:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Cross-midnight range: e.g. 23:00 to 05:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// Converts UI day index (0: Saturday to 6: Friday) to Dart's weekday index (1: Monday to 7: Sunday).
  static int displayIndexToDartWeekday(int displayIndex) {
    if (displayIndex < 0 || displayIndex > 6) {
      throw ArgumentError('Display index must be between 0 and 6');
    }
    if (displayIndex == 0) return 6; // Saturday
    if (displayIndex == 1) return 7; // Sunday
    return displayIndex - 1; // 2 (Monday) -> 1, etc.
  }

  /// Converts Dart's weekday index (1: Monday to 7: Sunday) to UI day index (0: Saturday to 6: Friday).
  static int dartWeekdayToDisplayIndex(int dartWeekday) {
    if (dartWeekday < 1 || dartWeekday > 7) {
      throw ArgumentError('Dart weekday must be between 1 and 7');
    }
    if (dartWeekday == 6) return 0; // Saturday
    if (dartWeekday == 7) return 1; // Sunday
    return dartWeekday + 1; // 1 (Monday) -> 2, etc.
  }

  /// Generates the absolute minute intervals in a week for a day and start/end time.
  /// Week starts at Monday 00:00 (minutes 0) and ends Sunday 24:00 (minutes 10080).
  static List<List<int>> getWeeklyMinutesForSchedule(int weekday, String startTimeStr, String endTimeStr) {
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    if (startParts.length != 2 || endParts.length != 2) return [];

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMin = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final startMinutesInDay = startHour * 60 + startMin;
    final endMinutesInDay = endHour * 60 + endMin;

    final dayOffset = (weekday - 1) * 24 * 60;

    if (startMinutesInDay <= endMinutesInDay) {
      // Normal range
      final start = dayOffset + startMinutesInDay;
      final end = dayOffset + endMinutesInDay;
      return [[start, end]];
    } else {
      // Cross-midnight range
      final start = dayOffset + startMinutesInDay;
      final nextWeekday = (weekday == 7) ? 1 : weekday + 1;
      final nextDayOffset = (nextWeekday - 1) * 24 * 60;
      final end = nextDayOffset + endMinutesInDay;

      if (start <= end) {
        return [[start, end]];
      } else {
        // Wraps around the end of the week (Sunday night to Monday morning)
        const weekEnd = 7 * 24 * 60;
        return [
          [start, weekEnd],
          [0, end],
        ];
      }
    }
  }

  /// Checks if a proposed zone schedule overlaps with any existing schedules.
  static Map<String, dynamic> checkOverlap({
    required Set<int> proposedDays,
    required String proposedStart,
    required String proposedEnd,
    required List<Map<String, dynamic>> existingSchedules,
  }) {
    final proposedRanges = <List<int>>[];
    for (final day in proposedDays) {
      proposedRanges.addAll(getWeeklyMinutesForSchedule(day, proposedStart, proposedEnd));
    }

    for (final existing in existingSchedules) {
      final daysStr = existing['daysOfWeek'] as String? ?? '';
      final existingDays = daysStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
      final existingStart = existing['startTime'] as String? ?? '00:00';
      final existingEnd = existing['endTime'] as String? ?? '23:59';
      final zoneName = existing['zoneName'] as String? ?? 'زون دیگر';

      final existingRanges = <List<int>>[];
      for (final day in existingDays) {
        existingRanges.addAll(getWeeklyMinutesForSchedule(day, existingStart, existingEnd));
      }

      for (final pRange in proposedRanges) {
        for (final eRange in existingRanges) {
          final startMax = pRange[0] > eRange[0] ? pRange[0] : eRange[0];
          final endMin = pRange[1] < eRange[1] ? pRange[1] : eRange[1];

          if (startMax < endMin) {
            return {
              'hasOverlap': true,
              'message': 'این زمان‌بندی با زون «$zoneName» ($existingStart الی $existingEnd) در برخی روزها تداخل دارد.',
              'suggestedStart': existingEnd,
            };
          }
        }
      }
    }

    return {'hasOverlap': false};
  }
}
