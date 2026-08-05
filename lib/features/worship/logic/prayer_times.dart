// lib/features/worship/logic/prayer_times.dart
// PrayerTimes model with full DateTime fields (W-5 fix).
// Separated from WorshipEngine to avoid circular imports with PrayerTimeline.

/// Prayer times with full DateTime objects — not HH:mm strings (W-5 fix).
class PrayerTimes {
  const PrayerTimes({
    required this.date,
    required this.cityId,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.sunset,
    required this.isha,
    required this.midnightShari,
    required this.calculationMethod,
    required this.ihtiyatMinutes,
    this.isFallbackLocation = false,
  });

  final String date;
  final String cityId;

  /// Full DateTime — no HH:mm string truncation (W-5).
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime sunset;
  final DateTime isha;

  /// Shari midnight = midpoint between maghrib and NEXT-day fajr (W-5).
  final DateTime midnightShari;

  final String calculationMethod;
  final int ihtiyatMinutes;

  /// True when city lookup failed and Tehran was used as fallback (W-14).
  final bool isFallbackLocation;

  // Backward-compatible HH:mm text getters
  String get fajrText => _fmt(fajr);
  String get sunriseText => _fmt(sunrise);
  String get dhuhrText => _fmt(dhuhr);
  String get asrText => _fmt(asr);
  String get maghribText => _fmt(maghrib);
  String get sunsetText => _fmt(sunset);
  String get ishaText => _fmt(isha);
  String get midnightShariText => _fmt(midnightShari);

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
