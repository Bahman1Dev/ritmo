import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/features/worship/logic/prayer_times.dart';

/// Independent "Sky" Palette for the Worship Arc Hero Card.
///
/// This file is intentionally NOT dependent on RitmoColors or context.colors.
/// The Worship Hero card is a "Window to the Sky", not a standard app surface.
/// Changing the app theme palette MUST NOT change the colors of this card.
/// (Constraint 2 of Prompt 052)
@immutable
class WorshipSkyPalette {
  const WorshipSkyPalette({
    required this.id,
    required this.periodName,
    required this.periodIcon,
    required this.gradient,
    required this.textColor,
    required this.accentColor,
    required this.goldColor,
    required this.doneFrom,
    required this.doneTo,
    required this.isNight,
  });

  final String id;
  final String periodName;
  final IconData periodIcon;
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;
  final Color goldColor;
  final Color doneFrom;
  final Color doneTo;
  final bool isNight;

  /// A-15: Computed dark text requirement based on average gradient luminance
  bool get useDarkText {
    if (gradient.isEmpty) return false;
    final avgLuminance = gradient
            .map((c) => c.computeLuminance())
            .reduce((a, b) => a + b) /
        gradient.length;
    return avgLuminance > 0.55;
  }

  static WorshipSkyPalette lerp(WorshipSkyPalette a, WorshipSkyPalette b, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final maxLen = b.gradient.length;
    final lerpedGradient = <Color>[];

    for (var i = 0; i < maxLen; i++) {
      final colorA = i < a.gradient.length ? a.gradient[i] : a.gradient.last;
      final colorB = b.gradient[i];
      lerpedGradient.add(Color.lerp(colorA, colorB, clampedT) ?? colorB);
    }

    return WorshipSkyPalette(
      id: clampedT < 0.5 ? a.id : b.id,
      periodName: clampedT < 0.5 ? a.periodName : b.periodName,
      periodIcon: clampedT < 0.5 ? a.periodIcon : b.periodIcon,
      gradient: lerpedGradient,
      textColor: Color.lerp(a.textColor, b.textColor, clampedT) ?? b.textColor,
      accentColor: Color.lerp(a.accentColor, b.accentColor, clampedT) ?? b.accentColor,
      goldColor: Color.lerp(a.goldColor, b.goldColor, clampedT) ?? b.goldColor,
      doneFrom: Color.lerp(a.doneFrom, b.doneFrom, clampedT) ?? b.doneFrom,
      doneTo: Color.lerp(a.doneTo, b.doneTo, clampedT) ?? b.doneTo,
      isNight: clampedT < 0.5 ? a.isNight : b.isNight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorshipSkyPalette) return false;
    if (id != other.id || isNight != other.isNight) return false;
    if (textColor != other.textColor || accentColor != other.accentColor || goldColor != other.goldColor) return false;
    if (doneFrom != other.doneFrom || doneTo != other.doneTo) return false;
    if (gradient.length != other.gradient.length) return false;
    for (var i = 0; i < gradient.length; i++) {
      if (gradient[i] != other.gradient[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, isNight, textColor, accentColor, goldColor, doneFrom, doneTo);

  // ── Preset Palettes ───────────────────────────────────────────────────────

  static const night = WorshipSkyPalette(
    id: 'night',
    periodName: 'شب',
    periodIcon: CupertinoIcons.moon_stars_fill,
    gradient: [Color(0xFF070B14), Color(0xFF0F172A)],
    textColor: Color(0xFFCCD6F6),
    accentColor: Color(0xFF8892B0),
    goldColor: Color(0xFFC4A35A),
    doneFrom: Color(0xFFD9B75F),
    doneTo: Color(0xFFB8763C),
    isNight: true,
  );

  static const sahar = WorshipSkyPalette(
    id: 'sahar',
    periodName: 'سپیده‌دم',
    periodIcon: CupertinoIcons.sunrise_fill,
    gradient: [
      Color(0xFF0D0826),
      Color(0xFF1F1442),
      Color(0xFF43255F),
      Color(0xFF7A4269),
    ],
    textColor: Color(0xFFF4EBF7),
    accentColor: Color(0xFFD8B4FE),
    goldColor: Color(0xFFF7D070),
    doneFrom: Color(0xFFF7D070),
    doneTo: Color(0xFFE8913A),
    isNight: true,
  );

  static const morning = WorshipSkyPalette(
    id: 'morning',
    periodName: 'صبح',
    periodIcon: CupertinoIcons.sun_min_fill,
    gradient: [Color(0xFF2C3E6B), Color(0xFF4A90D9), Color(0xFF74B9FF)],
    textColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFA8D8EA),
    goldColor: Color(0xFFFFD700),
    doneFrom: Color(0xFFFFD700),
    doneTo: Color(0xFFFF9800),
    isNight: false,
  );

  static const noon = WorshipSkyPalette(
    id: 'noon',
    periodName: 'ظهر',
    periodIcon: CupertinoIcons.sun_max_fill,
    gradient: [Color(0xFF1F618D), Color(0xFF2980B9), Color(0xFF5DADE2)],
    textColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFA8D8EA),
    goldColor: Color(0xFFFFD700),
    doneFrom: Color(0xFFFFD700),
    doneTo: Color(0xFFFF9800),
    isNight: false,
  );

  static const afternoon = WorshipSkyPalette(
    id: 'afternoon',
    periodName: 'بعدازظهر',
    periodIcon: CupertinoIcons.cloud_sun_fill,
    gradient: [Color(0xFF2471A3), Color(0xFF5499C7), Color(0xFF85C1E9)],
    textColor: Color(0xFFF8F4EF),
    accentColor: Color(0xFFE8D5B0),
    goldColor: Color(0xFFFFD700),
    doneFrom: Color(0xFFFFD700),
    doneTo: Color(0xFFFF9800),
    isNight: false,
  );

  static const sunset = WorshipSkyPalette(
    id: 'sunset',
    periodName: 'غروب',
    periodIcon: CupertinoIcons.sunset_fill,
    gradient: [Color(0xFF2C3E6B), Color(0xFFBE5B3A), Color(0xFFE8913A), Color(0xFFF5D78A)],
    textColor: Color(0xFFFFF5E8),
    accentColor: Color(0xFFFFD185),
    goldColor: Color(0xFFFFD700),
    doneFrom: Color(0xFFFFD700),
    doneTo: Color(0xFFFF9800),
    isNight: false,
  );

  static const dusk = WorshipSkyPalette(
    id: 'dusk',
    periodName: 'شفق',
    periodIcon: CupertinoIcons.moon_fill,
    gradient: [Color(0xFF0D1B3E), Color(0xFF1E3163), Color(0xFF4A2866)],
    textColor: Color(0xFFD6CEE6),
    accentColor: Color(0xFFA78BCA),
    goldColor: Color(0xFFFFD700),
    doneFrom: Color(0xFFD9B75F),
    doneTo: Color(0xFFB8763C),
    isNight: true,
  );
}

/// Pure function that determines the sky palette based on prayer times (§8.3)
WorshipSkyPalette skyFor(DateTime now, PrayerTimes times) {
  try {
    final fajr = times.fajr;
    final sunrise = times.sunrise;
    final dhuhr = times.dhuhr;
    final maghrib = times.maghrib;
    final isha = times.isha;

    final saharStart = fajr.subtract(const Duration(minutes: 60));
    final preSunset = maghrib.subtract(const Duration(minutes: 90));
    final sunsetEnd = maghrib.add(const Duration(minutes: 20));
    final duskEnd = isha.add(const Duration(minutes: 30));

    if (now.isAfter(saharStart) && now.isBefore(fajr)) {
      return WorshipSkyPalette.sahar;
    }
    if ((now.isAfter(fajr) || now.isAtSameMomentAs(fajr)) && now.isBefore(sunrise)) {
      return WorshipSkyPalette.sahar;
    }
    if ((now.isAfter(sunrise) || now.isAtSameMomentAs(sunrise)) && now.isBefore(dhuhr)) {
      return WorshipSkyPalette.morning;
    }
    final dhuhrPlus1 = dhuhr.add(const Duration(hours: 1));
    if ((now.isAfter(dhuhr) || now.isAtSameMomentAs(dhuhr)) && now.isBefore(dhuhrPlus1)) {
      return WorshipSkyPalette.noon;
    }
    if ((now.isAfter(dhuhrPlus1) || now.isAtSameMomentAs(dhuhrPlus1)) && now.isBefore(preSunset)) {
      return WorshipSkyPalette.afternoon;
    }
    if ((now.isAfter(preSunset) || now.isAtSameMomentAs(preSunset)) && now.isBefore(sunsetEnd)) {
      return WorshipSkyPalette.sunset;
    }
    if ((now.isAfter(sunsetEnd) || now.isAtSameMomentAs(sunsetEnd)) && now.isBefore(duskEnd)) {
      return WorshipSkyPalette.dusk;
    }

    return WorshipSkyPalette.night;
  } catch (_) {
    return WorshipSkyPalette.night;
  }
}
