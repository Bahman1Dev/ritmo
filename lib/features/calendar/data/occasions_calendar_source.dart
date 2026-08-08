import 'package:flutter/foundation.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Occasion item structure for calendar display.
class CalendarOccasion {
  const CalendarOccasion({
    required this.title,
    required this.isHoliday,
    required this.category,
    this.recommendedAmal,
  });

  final String title;
  final bool isHoliday;
  final String category;
  final String? recommendedAmal;
}

/// K41 — Loads worship & Jalali/Hijri occasions for a given date.
class OccasionsCalendarSource {
  OccasionsCalendarSource._();

  static List<CalendarOccasion> occasionsForDate(DateTime date) {
    try {
      final solar = Jalali.fromDateTime(date);
      // Derive Hijri date (approximate or via WorshipCalendarLogic)
      final hijriDate = WorshipCalendarLogic.getHijriDateForJalali(solar);
      final list = WorshipOccasionsData.getOccasionsForDay(solar, hijriDate);

      final result = <CalendarOccasion>[];

      // Add Friday as weekly holiday
      if (solar.weekDay == 7) {
        result.add(const CalendarOccasion(
          title: 'جمعه (تعطیل هفته)',
          isHoliday: true,
          category: 'تعطیلات',
        ));
      }

      for (final occ in list) {
        result.add(CalendarOccasion(
          title: occ.title,
          isHoliday: occ.isReligiousHoliday,
          category: occ.category,
          recommendedAmal: occ.recommendedAmal,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('[OccasionsCalendarSource] Error: $e');
      return const [];
    }
  }
}
