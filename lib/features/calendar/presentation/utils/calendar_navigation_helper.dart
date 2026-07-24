/// Navigation and scroll position anchor calculation utilities for calendar view.
class CalendarNavigationHelper {
  const CalendarNavigationHelper._();

  /// Returns the DateTime for the previous day.
  static DateTime previousDay(DateTime date) {
    return date.subtract(const Duration(days: 1));
  }

  /// Returns the DateTime for the next day.
  static DateTime nextDay(DateTime date) {
    return date.add(const Duration(days: 1));
  }

  /// Checks if [date] is the same calendar day as [now] (or DateTime.now()).
  static bool isToday(DateTime date, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    return date.year == ref.year &&
        date.month == ref.month &&
        date.day == ref.day;
  }

  /// Calculates a default initial scroll offset (in pixels) for the daily timeline grid.
  ///
  /// Anchors around [now] (or wake time / morning default 07:00) so user starts
  /// at a meaningful part of the day rather than always 00:00 midnight.
  static double calculateInitialScrollOffset({
    required DateTime date,
    DateTime? now,
    int wakingHour = 7,
    double pxPerMinute = 1.2,
    double viewportHeight = 600.0,
  }) {
    final currentRef = now ?? DateTime.now();
    int targetMinute;

    if (isToday(date, now: currentRef)) {
      // Anchor 60 minutes before current time, clamped to wake hour
      final currentMinute = (currentRef.hour * 60) + currentRef.minute;
      final wakeMinute = wakingHour * 60;
      targetMinute = (currentMinute - 60).clamp(wakeMinute, 1440 - 60);
    } else {
      // For future/past days, default to waking hour
      targetMinute = wakingHour * 60;
    }

    final targetPx = targetMinute * pxPerMinute;
    final maxScrollPx = (1440 * pxPerMinute) - viewportHeight;

    if (maxScrollPx <= 0) return 0.0;
    return targetPx.clamp(0.0, maxScrollPx);
  }
}
