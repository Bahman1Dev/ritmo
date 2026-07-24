import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Presentation formatting utilities for dates, times, and day headers.
class CalendarDateFormatter {
  const CalendarDateFormatter._();

  /// Formats a date into a human-readable title for the selected day header.
  /// E.g. "جمعه، ۳ مرداد ۱۴۰۵" or "امروز - ۳ مرداد"
  static String formatSelectedDateTitle(
    DateTime date, {
    DateTime? relativeTo,
    bool includeYear = false,
  }) {
    final jalali = Jalali.fromDateTime(date);
    final dayName = jalali.formatter.wN;
    final monthName = jalali.formatter.mN;
    final dayNum = toPersianDigits(jalali.day.toString());
    final yearNum = toPersianDigits(jalali.year.toString());

    final relLabel = getDayRelativeLabel(date, relativeTo: relativeTo);

    if (relLabel != null) {
      return '$relLabel - $dayNum $monthName';
    }

    if (includeYear) {
      return '$dayName، $dayNum $monthName $yearNum';
    }

    return '$dayName، $dayNum $monthName';
  }

  /// Returns "امروز", "دیروز", "فردا", or null if not within +/- 1 day of reference.
  static String? getDayRelativeLabel(DateTime date, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final ref = DateTime(now.year, now.month, now.day);

    final diff = d.difference(ref).inDays;
    if (diff == 0) return 'امروز';
    if (diff == -1) return 'دیروز';
    if (diff == 1) return 'فردا';
    return null;
  }

  /// Formats an hour index (0..23) to "HH:00" in Persian digits if requested.
  static String formatHourLabel(int hour, {bool usePersianDigits = true}) {
    final hStr = hour.toString().padLeft(2, '0');
    final formatted = '$hStr:00';
    return usePersianDigits ? toPersianDigits(formatted) : formatted;
  }

  /// Converts any string digits to Persian digits using project-standard helper.
  static String formatPersian(String input) {
    return toPersianDigits(input);
  }
}
