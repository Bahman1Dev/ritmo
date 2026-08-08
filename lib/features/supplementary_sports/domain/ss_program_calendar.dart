class SsProgramCalendar {
  /// هفتهٔ چندم از چرخه؟ از programStartDate محاسبه می‌شود.
  static int cycleWeekFor(DateTime date, {required DateTime programStart, int cycleLength = 4}) {
    // If start is in the future, return week 1
    if (date.isBefore(programStart)) {
      return 1;
    }
    // Normalize date and start to ignore time of day
    final startNormalized = DateTime(programStart.year, programStart.month, programStart.day);
    final dateNormalized = DateTime(date.year, date.month, date.day);
    
    final diffDays = dateNormalized.difference(startNormalized).inDays;
    final elapsedWeeks = diffDays ~/ 7;
    return (elapsedWeeks % cycleLength) + 1;
  }

  /// آیا این هفته دیلود (استراحت/ریکاوری سبک) است؟ deloadEveryNWeeks == 0 یعنی هرگز.
  static bool isDeloadWeek(int cycleWeek, {required int deloadEveryNWeeks}) {
    return deloadEveryNWeeks > 0 && cycleWeek == deloadEveryNWeeks;
  }

  /// تبدیل صریح بین دو نگاشت روز هفته — تنها جایی که این تبدیل مجاز است.
  /// ۱=شنبه  →  ۶=شنبه
  static int legacySsDayToRitmoDay(int ssDay) {
    return switch (ssDay) {
      1 => 6, // Sat
      2 => 7, // Sun
      3 => 1, // Mon
      4 => 2, // Tue
      5 => 3, // Wed
      6 => 4, // Thu
      7 => 5, // Fri
      _ => 6,
    };
  }

  static int ritmoDayToLegacySsDay(int ritmoDay) {
    return switch (ritmoDay) {
      6 => 1, // Sat
      7 => 2, // Sun
      1 => 3, // Mon
      2 => 4, // Tue
      3 => 5, // Wed
      4 => 6, // Thu
      5 => 7, // Fri
      _ => 1,
    };
  }

  static int ritmoDayOf(DateTime date) {
    return date.weekday; // 1: Mon ... 7: Sun
  }
}
