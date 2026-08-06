import 'package:shamsi_date/shamsi_date.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

class WorshipCalendarDay {
  const WorshipCalendarDay({
    required this.dateTime,
    required this.jalali,
    required this.hijri,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isFriday,
    required this.occasions,
    required this.dailyZikr,
  });

  final DateTime dateTime;
  final Jalali jalali;
  final HijriDate hijri;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isFriday;
  final List<WorshipOccasion> occasions;
  final String dailyZikr;

  bool get hasOccasions => occasions.isNotEmpty;
  bool get isReligiousHoliday => isFriday || occasions.any((o) => o.isReligiousHoliday);
}

class WorshipCalendarMonthData {
  const WorshipCalendarMonthData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.days,
    required this.gregorianRangeText,
    required this.hijriRangeText,
  });

  final int year;
  final int month;
  final String monthName;
  final List<WorshipCalendarDay> days;
  final String gregorianRangeText;
  final String hijriRangeText;
}

class WorshipCalendarLogic {
  const WorshipCalendarLogic._();

  static const List<String> jalaliMonthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> gregorianMonthNamesFa = [
    'ژوئیه', // placeholder index 0
    'ژانویه',
    'فوریه',
    'مارس',
    'آوریل',
    'می',
    'ژوئن',
    'ژوئیه',
    'اوت',
    'سپتامبر',
    'اکتبر',
    'نوامبر',
    'دسامبر',
  ];

  /// Returns 0 for Saturday, 1 for Sunday, ..., 6 for Friday
  static int getSaturdayIndexedWeekday(DateTime dt) {
    return (dt.weekday + 1) % 7;
  }

  /// Calculates total days in a Jalali month
  static int getDaysInJalaliMonth(int year, int month) {
    if (month >= 1 && month <= 6) return 31;
    if (month >= 7 && month <= 11) return 30;
    // Month 12 (Esfand)
    final j = Jalali(year, 12, 1);
    return j.isLeapYear() ? 30 : 29;
  }

  /// Generates grid days and headers for a Jalali month
  static WorshipCalendarMonthData generateMonthData(int year, int month, {DateTime? todayOverride}) {
    final now = todayOverride ?? DateTime.now();
    final todayJ = Jalali.fromDateTime(now);

    final firstDayJalali = Jalali(year, month, 1);
    final firstDayDt = firstDayJalali.toDateTime();

    final daysInMonth = getDaysInJalaliMonth(year, month);
    final startOffset = getSaturdayIndexedWeekday(firstDayDt);

    final totalGridCells = (startOffset + daysInMonth <= 35) ? 35 : 42;
    final daysList = <WorshipCalendarDay>[];

    final startDate = firstDayDt.subtract(Duration(days: startOffset));

    for (var i = 0; i < totalGridCells; i++) {
      final currentDt = startDate.add(Duration(days: i));
      final currentJ = Jalali.fromDateTime(currentDt);
      final currentH = HijriCalendarCalculator.hijriFromGregorian(currentDt);

      final isCurrentMonth = currentJ.year == year && currentJ.month == month;
      final isToday = currentJ.year == todayJ.year &&
          currentJ.month == todayJ.month &&
          currentJ.day == todayJ.day;
      final isFriday = currentDt.weekday == DateTime.friday;

      final occasions = WorshipOccasionsData.getOccasionsForDay(currentJ, currentH);
      final dailyZikr = WorshipOccasionsData.getDailyZikr(currentDt.weekday);

      daysList.add(WorshipCalendarDay(
        dateTime: currentDt,
        jalali: currentJ,
        hijri: currentH,
        isCurrentMonth: isCurrentMonth,
        isToday: isToday,
        isFriday: isFriday,
        occasions: occasions,
        dailyZikr: dailyZikr,
      ));
    }

    // Gregorian range calculation
    final monthStartDt = firstDayDt;
    final monthEndJalali = Jalali(year, month, daysInMonth);
    final monthEndDt = monthEndJalali.toDateTime();

    final startGMonth = gregorianMonthNamesFa[monthStartDt.month];
    final endGMonth = gregorianMonthNamesFa[monthEndDt.month];

    final gRange = (startGMonth == endGMonth)
        ? '${toPersianDigits(monthStartDt.day.toString())} تا ${toPersianDigits(monthEndDt.day.toString())} $startGMonth ${toPersianDigits(monthStartDt.year.toString())}'
        : '${toPersianDigits(monthStartDt.day.toString())} $startGMonth - ${toPersianDigits(monthEndDt.day.toString())} $endGMonth ${toPersianDigits(monthStartDt.year.toString())}';

    // Hijri range calculation
    final startHijri = HijriCalendarCalculator.hijriFromGregorian(monthStartDt);
    final endHijri = HijriCalendarCalculator.hijriFromGregorian(monthEndDt);

    final hRange = (startHijri.month == endHijri.month)
        ? '${toPersianDigits(startHijri.day.toString())} تا ${toPersianDigits(endHijri.day.toString())} ${startHijri.monthName} ${toPersianDigits(startHijri.year.toString())}'
        : '${toPersianDigits(startHijri.day.toString())} ${startHijri.monthName} - ${toPersianDigits(endHijri.day.toString())} ${endHijri.monthName} ${toPersianDigits(startHijri.year.toString())}';

    final monthName = jalaliMonthNames[month - 1];

    return WorshipCalendarMonthData(
      year: year,
      month: month,
      monthName: monthName,
      days: daysList,
      gregorianRangeText: gRange,
      hijriRangeText: hRange,
    );
  }
}
