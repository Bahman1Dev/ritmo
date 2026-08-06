import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/logic/prayer_timeline.dart';
import 'package:ritmo/features/worship/logic/prayer_times.dart';

void main() {
  group('Prayer Time Gating & Quality Window Tests', () {
    final now = DateTime(2026, 8, 6, 18, 0); // 18:00 PM today

    final times = PrayerTimes(
      date: '2026-08-06',
      cityId: 'tehran',
      fajr: DateTime(2026, 8, 6, 4, 30),
      sunrise: DateTime(2026, 8, 6, 6, 0),
      dhuhr: DateTime(2026, 8, 6, 13, 0),
      asr: DateTime(2026, 8, 6, 16, 30),
      sunset: DateTime(2026, 8, 6, 19, 30),
      maghrib: DateTime(2026, 8, 6, 19, 45), // 19:45 PM
      isha: DateTime(2026, 8, 6, 20, 30),
      midnightShari: DateTime(2026, 8, 6, 23, 45),
      calculationMethod: 'TEHRAN',
      ihtiyatMinutes: 0,
    );

    test('1. Maghrib prayer slot at 19:45 is in future relative to 18:00', () {
      final slot = PrayerTimeline.getSlotFor('MAGHRIB', times);
      expect(slot, isNotNull);
      expect(slot!.at, equals(DateTime(2026, 8, 6, 19, 45)));
      expect(now.isBefore(slot.at), isTrue);
    });

    test('2. Current time 18:00 is BEFORE Maghrib Athan (19:45) -> Time Gate Blocked', () {
      final slot = PrayerTimeline.getSlotFor('MAGHRIB', times);
      final isBefore = now.isBefore(slot!.at);
      expect(isBefore, isTrue);
    });

    test('3. Dhuhr prayer (Athan 13:00) logged at 13:15 (within 30 min) -> EARLY (اول وقت)', () {
      final logTime = DateTime(2026, 8, 6, 13, 15);
      final slot = PrayerTimeline.getSlotFor('DHUHR', times)!;
      final elapsed = logTime.difference(slot.at).inMinutes;

      expect(elapsed, equals(15));
      expect(elapsed <= 30, isTrue); // "اول وقت"
    });

    test('4. Dhuhr prayer (Athan 13:00) logged at 14:30 (>30 min) -> NORMAL (در وقت)', () {
      final logTime = DateTime(2026, 8, 6, 14, 30);
      final slot = PrayerTimeline.getSlotFor('DHUHR', times)!;
      final elapsed = logTime.difference(slot.at).inMinutes;

      expect(elapsed, equals(90));
      expect(elapsed > 30, isTrue); // "در وقت"
    });
  });
}
