import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/movement_load_calculator.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

void main() {
  group('MovementLoadCalculator Unit Tests', () {
    test('metFor calculates intensity correctly', () {
      final low = MovementLoadCalculator.metFor(
        baseMet: 5.0,
        metLow: 3.5,
        metHigh: 8.0,
        intensity: MovementIntensity.low,
      );
      expect(low, 3.5);

      final high = MovementLoadCalculator.metFor(
        baseMet: 5.0,
        metLow: 3.5,
        metHigh: 8.0,
        intensity: MovementIntensity.high,
      );
      expect(high, 8.0);

      final med = MovementLoadCalculator.metFor(
        baseMet: 5.0,
        metLow: 3.5,
        metHigh: 8.0,
        intensity: MovementIntensity.medium,
      );
      expect(med, 5.0);
    });

    test('metMinutes calculates duration x met', () {
      final metMins = MovementLoadCalculator.metMinutes(met: 4.0, durationMinutes: 30);
      expect(metMins, 120.0);
    });

    test('calories calculates kcal correctly with fallback weight', () {
      final kcal = MovementLoadCalculator.calories(met: 7.0, weightKg: 70.0, durationMinutes: 60);
      expect(kcal, closeTo(514.5, 0.1));
    });
  });
}
