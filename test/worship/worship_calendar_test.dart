import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

void main() {
  group('Worship Calendar Logic & Conversion Tests', () {
    test('1. Saturday-indexed weekday alignment is correct', () {
      // 2026-08-08 is Saturday
      final sat = DateTime(2026, 8, 8);
      expect(sat.weekday, equals(DateTime.saturday));
      expect(WorshipCalendarLogic.getSaturdayIndexedWeekday(sat), equals(0));

      // 2026-08-09 is Sunday
      final sun = DateTime(2026, 8, 9);
      expect(WorshipCalendarLogic.getSaturdayIndexedWeekday(sun), equals(1));

      // 2026-08-14 is Friday
      final fri = DateTime(2026, 8, 14);
      expect(WorshipCalendarLogic.getSaturdayIndexedWeekday(fri), equals(6));
    });

    test('2. Month length calculation handles Esfand & leap years', () {
      // Month 1 to 6 have 31 days
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1405, 1), equals(31));
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1405, 6), equals(31));

      // Month 7 to 11 have 30 days
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1405, 7), equals(30));
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1405, 11), equals(30));

      // Month 12 (Esfand) in non-leap year (1402) has 29 days
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1402, 12), equals(29));

      // Month 12 (Esfand) in leap year (1403) has 30 days
      expect(WorshipCalendarLogic.getDaysInJalaliMonth(1403, 12), equals(30));
    });

    test('3. Grid generation creates valid 35 or 42 cell structure with unified dates', () {
      final monthData = WorshipCalendarLogic.generateMonthData(1405, 5); // Mordad 1405
      expect(monthData.monthName, equals('مرداد'));
      expect(monthData.days.length % 7, equals(0)); // 35 or 42

      final activeDays = monthData.days.where((d) => d.isCurrentMonth).toList();
      expect(activeDays.length, equals(31));

      // Check first active day matches 1 Mordad 1405
      final firstDay = activeDays.first;
      expect(firstDay.jalali.day, equals(1));
      expect(firstDay.jalali.month, equals(5));

      // Derive Hijri & Gregorian from same date
      final expectedHijri = HijriCalendarCalculator.hijriFromGregorian(firstDay.dateTime);
      expect(firstDay.hijri.day, equals(expectedHijri.day));
      expect(firstDay.hijri.month, equals(expectedHijri.month));
    });

    test('4. Worship occasions registry contains ONLY religious events', () {
      // 10 Muharram (Ashura)
      const ashuraH = HijriDate(day: 10, month: 1, year: 1448, monthName: 'محرم', formatted: '۱۰ محرم ۱۴۴۸');
      final ashuraSolar = Jalali(1405, 4, 15);
      final occasions = WorshipOccasionsData.getOccasionsForDay(ashuraSolar, ashuraH);

      expect(occasions.any((o) => o.title.contains('عاشورا')), isTrue);
      expect(occasions.first.isReligiousHoliday, isTrue);

      // Verify secular events are absent
      expect(occasions.any((o) => o.title.contains('سینما')), isFalse);
    });

    test('5. Daily Zikr of the week returns correct Persian dhikr', () {
      expect(WorshipOccasionsData.getDailyZikr(DateTime.saturday), contains('یا رَبَّ الْعالَمین'));
      expect(WorshipOccasionsData.getDailyZikr(DateTime.friday), contains('اللّهُمَّ صَلِّ'));
    });
  });
}
