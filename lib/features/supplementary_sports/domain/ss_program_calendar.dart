import 'package:sqflite/sqflite.dart';

/// Single source of truth for Supplementary Sports program calendar calculations.
class SSProgramCalendar {
  /// Calculates current active week based on programStartDate.
  static int currentWeek(String? programStartDateIso, DateTime today) {
    if (programStartDateIso == null || programStartDateIso.isEmpty) {
      return 1;
    }
    final startDate = DateTime.tryParse(programStartDateIso);
    if (startDate == null) return 1;

    final diffDays = today.difference(startDate).inDays;
    if (diffDays < 0) return 1;
    final week = (diffDays ~/ 7) + 1;
    return week < 1 ? 1 : week;
  }

  /// Farsi Day of Week: Saturday=1 ... Friday=7
  static int farsiDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 1;
      case DateTime.sunday:
        return 2;
      case DateTime.monday:
        return 3;
      case DateTime.tuesday:
        return 4;
      case DateTime.wednesday:
        return 5;
      case DateTime.thursday:
        return 6;
      case DateTime.friday:
        return 7;
      default:
        return 1;
    }
  }

  /// Returns calendar date for given week and Farsi day of week.
  static DateTime dateForPlanDay({
    required String? programStartDateIso,
    required int week,
    required int dayOfWeek,
  }) {
    DateTime baseDate = DateTime.now();
    if (programStartDateIso != null && programStartDateIso.isNotEmpty) {
      baseDate = DateTime.tryParse(programStartDateIso) ?? DateTime.now();
    }

    final baseDow = farsiDayOfWeek(baseDate);
    final satWeek1 = DateTime(baseDate.year, baseDate.month, baseDate.day).subtract(Duration(days: baseDow - 1));

    final daysOffset = ((week - 1) * 7) + (dayOfWeek - 1);
    return satWeek1.add(Duration(days: daysOffset));
  }

  /// Counts number of pending/missed days past scheduled date.
  static Future<int> missedDaysCount(Database db, DateTime today) async {
    final todayIso = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ss_plan_schedule WHERE scheduledDate < ? AND status = 'PENDING'",
      [todayIso],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns Persian day name (e.g. شنبه)
  static String getFarsiDayName(int farsiDow) {
    switch (farsiDow) {
      case 1:
        return 'شنبه';
      case 2:
        return 'یکشنبه';
      case 3:
        return 'دوشنبه';
      case 4:
        return 'سه‌شنبه';
      case 5:
        return 'چهارشنبه';
      case 6:
        return 'پنجشنبه';
      case 7:
        return 'جمعه';
      default:
        return 'شنبه';
    }
  }
}
