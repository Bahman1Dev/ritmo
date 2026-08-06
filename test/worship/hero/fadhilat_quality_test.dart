import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/logic/fadhilat.dart';

void main() {
  group('Fadhilat & PrayerQuality', () {
    final start = DateTime(2026, 8, 6, 13, 0);
    final end = DateTime(2026, 8, 6, 18, 0);

    test('fadhilatLength clamps max duration to 20 minutes', () {
      final len = fadhilatLength(start, end);
      expect(len.inMinutes, equals(20));
    });

    test('qualityAt correctly classifies timing', () {
      expect(qualityAt(DateTime(2026, 8, 6, 13, 5), start, end), equals(PrayerQuality.onTime));
      expect(qualityAt(DateTime(2026, 8, 6, 13, 19), start, end), equals(PrayerQuality.onTime));
      expect(qualityAt(DateTime(2026, 8, 6, 13, 25), start, end), equals(PrayerQuality.inTime));
      expect(qualityAt(DateTime(2026, 8, 6, 18, 5), start, end), equals(PrayerQuality.late));
    });
  });
}
