import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';

void main() {
  group('Clock & DayKey Unified Time Tests', () {
    test('DayKey formats correctly to YYYY-MM-DD', () {
      final dt = DateTime(2026, 7, 29, 23, 59, 59);
      final key = DayKey.from(dt);

      expect(key.value, equals('2026-07-29'));
    });

    test('FakeClock handles midnight crossover deterministically', () {
      final fakeClock = FakeClock(DateTime(2026, 7, 29, 23, 50));
      expect(fakeClock.today().value, equals('2026-07-29'));

      // Advance by 15 minutes across midnight
      fakeClock.advanceBy(const Duration(minutes: 15));

      expect(fakeClock.today().value, equals('2026-07-30'));
    });

    test('DayKey addDays and differenceInDays work properly', () {
      final key1 = DayKey.parse('2026-07-29');
      final key2 = key1.addDays(3);

      expect(key2.value, equals('2026-08-01'));
      expect(key2.differenceInDays(key1), equals(3));
    });
  });
}
