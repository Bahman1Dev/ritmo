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

  static int resolveForCompletion({
    required int? targetMinutes,
    required int? lightMinutes,
    required int? minimalMinutes,
    required String resultType,
    int? customDuration,
    int currentTargetMinutes = 0,
  }) {
    if (customDuration != null && customDuration > 0) {
      return sanitize(customDuration);
    }

    final effectiveTarget = currentTargetMinutes > 0 ? currentTargetMinutes : sanitize(targetMinutes);

    return switch (resultType.toUpperCase()) {
      'LIGHT' => sanitize(lightMinutes, fallback: (effectiveTarget * 0.75).round()),
      'MINIMAL' => sanitize(minimalMinutes, fallback: (effectiveTarget * 0.50).round()),
      _ => effectiveTarget,
    };
  }
}
