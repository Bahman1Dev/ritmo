import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/sports/movement/domain/endurance_progression.dart';
import 'package:ritmo/features/sports/movement/domain/movement_kind.dart';

void main() {
  group('EnduranceProgressionEngine Unit Tests', () {
    test('10% rule calculates max +10% progression', () {
      final res = EnduranceProgressionEngine.evaluateProgression(
        kindCode: 'RUNNING',
        lastWeekValue: 10.0,
        previousWeekValue: 9.5,
        metric: MovementMetric.distance,
      );

      expect(res.suggestedWeeklyValue, closeTo(11.0, 0.01));
      expect(res.isInjuryRisk, isFalse);
    });

    test('Injury risk warning triggers if volume increase > 15%', () {
      final res = EnduranceProgressionEngine.evaluateProgression(
        kindCode: 'RUNNING',
        lastWeekValue: 15.0,
        previousWeekValue: 10.0,
        metric: MovementMetric.distance,
      );

      expect(res.isInjuryRisk, isTrue);
    });
  });
}
