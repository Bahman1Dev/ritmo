class DurationBounds {
  const DurationBounds._();

  static const int minMinutes = 5;
  static const int maxMinutes = 1440;
  static const int defaultMinutes = 30;
  static const int maxRenderMinutes = 1440;

  static int sanitize(int? minutes, {int fallback = defaultMinutes}) {
    final val = minutes ?? fallback;
    return val.clamp(minMinutes, maxMinutes);
  }
}
