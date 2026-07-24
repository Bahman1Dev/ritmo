// lib/core/domain/models/duration_bounds.dart

class DurationBounds {
  const DurationBounds._();

  /// حداقل مطلق مدت یک آیتم
  static const int minMinutes = 5;

  /// حداکثر منطقی مدت یک آیتم قابل برنامه‌ریزی (۸ ساعت)
  static const int maxMinutes = 480;

  /// حداکثر ارتفاع بصری یک کارت روی تایم‌لاین (۴ ساعت)
  /// آیتم‌های بلندتر با نشانگر «ادامه دارد» بریده می‌شوند.
  static const int maxRenderMinutes = 240;

  /// پیش‌فرض وقتی مدت نامعتبر یا غایب است
  static const int defaultMinutes = 30;

  static int sanitize(int? raw) {
    if (raw == null || raw <= 0) return defaultMinutes;
    return raw.clamp(minMinutes, maxMinutes);
  }
}
