import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';

void main() {
  group('DayKey Single Definition Guard Tests (K-19)', () {
    test('DayKey.from formats YYYY-MM-DD correctly with leading zeros', () {
      final dt = DateTime(2026, 3, 5);
      final key = DayKey.from(dt);
      expect(key.value, equals('2026-03-05'));
      expect(key.toString(), equals('2026-03-05'));
    });

    test('DayKey.parse accepts valid YYYY-MM-DD strings', () {
      final key = DayKey.parse('2026-08-03');
      expect(key.value, equals('2026-08-03'));
    });

    test('DayKey.parse throws FormatException on invalid inputs', () {
      expect(() => DayKey.parse('invalid-date'), throwsFormatException);
      expect(() => DayKey.parse('2026/08/03'), throwsFormatException);
      expect(() => DayKey.parse('03-08-2026'), throwsFormatException);
    });

    test('addDays and differenceInDays compute correctly', () {
      final start = DayKey.parse('2026-08-01');
      final next = start.addDays(5);
      expect(next.value, equals('2026-08-06'));

      expect(next.differenceInDays(start), equals(5));
    });

    test('isBefore and isAfter compare dates correctly', () {
      final d1 = DayKey.parse('2026-08-01');
      final d2 = DayKey.parse('2026-08-02');

      expect(d1.isBefore(d2), isTrue);
      expect(d2.isAfter(d1), isTrue);
      expect(d1.isAfter(d2), isFalse);
    });
  });
}
