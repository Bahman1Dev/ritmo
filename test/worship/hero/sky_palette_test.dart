import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/logic/prayer_times.dart';
import 'package:ritmo/features/worship/presentation/theme/worship_sky_palette.dart';

void main() {
  group('WorshipSkyPalette & skyFor', () {
    test('returns independent sky palette per period', () {
      final now = DateTime(2026, 8, 6, 12, 0);
      final times = PrayerTimes(
        date: '2026-08-06',
        cityId: 'TEHRAN_TEHRAN',
        fajr: DateTime(2026, 8, 6, 4, 30),
        sunrise: DateTime(2026, 8, 6, 6, 0),
        dhuhr: DateTime(2026, 8, 6, 13, 0),
        asr: DateTime(2026, 8, 6, 16, 30),
        maghrib: DateTime(2026, 8, 6, 19, 30),
        sunset: DateTime(2026, 8, 6, 19, 15),
        isha: DateTime(2026, 8, 6, 20, 45),
        midnightShari: DateTime(2026, 8, 7, 0, 15),
        calculationMethod: 'TEHRAN_GEOPHYSICS',
        ihtiyatMinutes: 10,
      );

      final sky = skyFor(now, times);
      expect(sky.id, equals('morning'));
      expect(sky.isNight, isFalse);
    });

    test('lerp correctly blends palettes', () {
      final a = WorshipSkyPalette.night;
      final b = WorshipSkyPalette.morning;
      final lerped = WorshipSkyPalette.lerp(a, b, 0.5);
      expect(lerped.gradient.length, equals(3));
    });
  });
}
