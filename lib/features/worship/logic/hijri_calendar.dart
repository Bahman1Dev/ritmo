import 'package:ritmo/features/worship/models/worship_models.dart';

/// Offline Tabular Islamic (Hijri) calendar calculator.
/// Uses 30-year cycle algorithm (leap years: 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29).
class HijriCalendarCalculator {
  const HijriCalendarCalculator._();

  static const List<int> _leapYears = [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29];

  static bool isLeapYear(int year) {
    final mod = year % 30;
    return _leapYears.contains(mod);
  }

  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 29;
    if (month % 2 != 0) return 30; // Odd months have 30 days
    if (month == 12 && isLeapYear(year)) return 30; // 12th month in leap year
    return 29; // Even months have 29 days
  }

  /// Converts Julian Day Number to HijriDate
  static HijriDate hijriFromGregorian(DateTime date, {int offsetDays = 0}) {
    final effectiveDate = date.add(Duration(days: offsetDays));
    final year = effectiveDate.year;
    final month = effectiveDate.month;
    final day = effectiveDate.day;

    // Convert Gregorian to Julian Day Number
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    final jdn = day + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;

    // Convert JDN to Hijri
    var l = jdn - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j = (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) + ((l / 5670).floor()) * (((43 * l) / 15238).floor());
    l = l - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) - ((j / 16).floor()) * (((15238 * j) / 43).floor()) + 29;

    var hMonth = ((24 * l) / 709).floor();
    var hDay = l - ((709 * hMonth) / 24).floor();
    final hYear = 30 * n + j - 30;

    if (hMonth > 12) {
      hMonth = 12;
    }
    if (hMonth < 1) {
      hMonth = 1;
    }
    if (hDay < 1) hDay = 1;

    final mName = hijriMonthsFa[hMonth] ?? 'محرم';
    final formatted = '${toPersianDigits(hDay.toString())} $mName ${toPersianDigits(hYear.toString())}';

    return HijriDate(
      day: hDay,
      month: hMonth,
      year: hYear,
      monthName: mName,
      formatted: formatted,
    );
  }

  /// Converts Hijri to Gregorian DateTime
  static DateTime gregorianFromHijri(int hy, int hm, int hd, {int offsetDays = 0}) {
    var jdn = ((11 * hy + 3) / 30).floor() + 354 * hy + 30 * hm - ((hm - 1) / 2).floor() + hd + 1948440 - 385;

    // Convert JDN to Gregorian
    var l = jdn + 68569;
    var n = ((4 * l) / 146097).floor();
    l = l - ((146097 * n + 3) / 4).floor();
    var i = ((4000 * (l + 1)) / 1464001).floor();
    l = l - ((1461 * i) / 4).floor() + 31;
    var j = ((80 * l) / 2447).floor();
    var day = l - ((2447 * j) / 80).floor();
    l = (j / 11).floor();
    var month = j + 2 - 12 * l;
    var year = 100 * (n - 49) + i + l;

    return DateTime(year, month, day).subtract(Duration(days: offsetDays));
  }
}
