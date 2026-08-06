/// Fadhilat (First-time prayer window) logic — Section §9 (H-3)

const double kFadhilatFraction = 0.20;
const Duration kFadhilatMaxDuration = Duration(minutes: 20);

Duration fadhilatLength(DateTime windowStart, DateTime windowEnd) {
  final full = windowEnd.difference(windowStart);
  if (full.isNegative) return Duration.zero;
  final byFraction = full * kFadhilatFraction;
  return byFraction > kFadhilatMaxDuration ? kFadhilatMaxDuration : byFraction;
}

enum PrayerQuality { onTime, inTime, late }

PrayerQuality qualityAt(DateTime now, DateTime windowStart, DateTime windowEnd) {
  if (now.isBefore(windowStart)) return PrayerQuality.onTime;
  final fadhilatEnd = windowStart.add(fadhilatLength(windowStart, windowEnd));
  if (!now.isAfter(fadhilatEnd)) return PrayerQuality.onTime;
  if (!now.isAfter(windowEnd)) return PrayerQuality.inTime;
  return PrayerQuality.late;
}

String prayerQualityToCode(PrayerQuality q) {
  switch (q) {
    case PrayerQuality.onTime:
      return 'ON_TIME';
    case PrayerQuality.inTime:
    case PrayerQuality.late:
      return 'IN_TIME';
  }
}
