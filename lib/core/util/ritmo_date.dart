/// تنها مرجع مجاز تبدیل زمان به کلید روز در کل اپ (T-0.1).
class RitmoDate {
  const RitmoDate._();

  /// کلید روز به فرمت YYYY-MM-DD بر مبنای زمان محلی دستگاه.
  static String dayKey(DateTime instant) {
    final local = instant.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String dayKeyFromMillis(int millis) =>
      dayKey(DateTime.fromMillisecondsSinceEpoch(millis));

  static DateTime startOfDay(DateTime instant) {
    final l = instant.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static int startOfDayMillis(DateTime instant) =>
      startOfDay(instant).millisecondsSinceEpoch;

  /// کلیدهای روز از قدیم به جدید، شامل امروز. طول خروجی دقیقاً days است.
  static List<String> lastNDayKeys(DateTime now, int days) {
    final base = startOfDay(now);
    return List<String>.generate(
      days,
      (i) => dayKey(base.subtract(Duration(days: days - 1 - i))),
    );
  }

  static DateTime? tryParseDayKey(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
