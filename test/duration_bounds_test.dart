import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';

void main() {
  group('DurationBounds Unit Tests', () {
    test('sanitize handles null and non-positive numbers with defaultMinutes', () {
      expect(DurationBounds.sanitize(null), DurationBounds.defaultMinutes);
      expect(DurationBounds.sanitize(0), DurationBounds.defaultMinutes);
      expect(DurationBounds.sanitize(-10), DurationBounds.defaultMinutes);
    });

    test('sanitize clamps values between minMinutes (5) and maxMinutes (480)', () {
      expect(DurationBounds.sanitize(2), DurationBounds.minMinutes);
      expect(DurationBounds.sanitize(45), 45);
      expect(DurationBounds.sanitize(600), DurationBounds.maxMinutes);
      expect(DurationBounds.sanitize(9999), DurationBounds.maxMinutes);
    });
  });
}
