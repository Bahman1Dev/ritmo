/// Cross-domain model bridging energy levels, sleep metrics, and cycle status
/// to downstream planners (e.g. Konkur session sizing).
class EnergyContext {
  const EnergyContext({
    required this.energyLevel,
    required this.sleepHoursLastNight,
    this.isCycleRestDay = false,
  });

  final String energyLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final double sleepHoursLastNight; // e.g. 6.5
  final bool isCycleRestDay; // female cycle low-energy day

  /// Returns a session duration multiplier between 0.5 and 1.0
  double get sessionMultiplier {
    if (isCycleRestDay) return 0.5;
    if (energyLevel == 'LOW' || sleepHoursLastNight < 5.5) return 0.6;
    if (energyLevel == 'MEDIUM' || sleepHoursLastNight < 7.0) return 0.8;
    return 1.0;
  }

  /// Returns user-facing Persian explanatory note for energy adjustments
  String get farsiNote {
    if (isCycleRestDay) return 'امروز روز استراحت بدنی است؛ جلسات کوتاهتر توصیه میشود.';
    if (energyLevel == 'LOW') return 'سطح انرژی پایین است؛ جلسات مطالعه ۶۰٪ کوتاهتر شدند.';
    if (sleepHoursLastNight < 5.5) return 'خواب کم دیشب — جلسات کوتاهتر برای حفظ تمرکز.';
    if (energyLevel == 'MEDIUM') return 'انرژی متوسط — جلسات بهینهسازی شدند.';
    return '';
  }
}
