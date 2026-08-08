import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/cognitive_routing_engine.dart';
import 'package:ritmo/core/analytics/daily_budget_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/fresh_start_engine.dart';
import 'package:ritmo/core/analytics/motivation_diagnosis_engine.dart';

void main() {
  group('Engine Fingerprint Tests (§3 T-A1)', () {
    test('MotivationDiagnosisEngine produces unique fingerprints for different routineIds', () {
      final engine = MotivationDiagnosisEngine();
      final now = DateTime(2026, 8, 8, 10, 0);

      final inputA = MotivationDiagnosisInput(
        routineId: 'routine_101',
        routineCompletions: const [],
        now: now,
      );

      final inputB = MotivationDiagnosisInput(
        routineId: 'routine_202',
        routineCompletions: const [],
        now: now,
      );

      final fpA = engine.fingerprint(inputA);
      final fpB = engine.fingerprint(inputB);

      expect(fpA, isNot(equals(fpB)));
      expect(fpA, contains('routine_101'));
      expect(fpB, contains('routine_202'));
    });

    test('DailyBudgetEngine produces unique fingerprints for different dates', () {
      final engine = DailyBudgetEngine();

      final inputA = const DailyBudgetInput(
        dateStr: '2026-08-08',
        plannedItems: [],
      );

      final inputB = const DailyBudgetInput(
        dateStr: '2026-08-09',
        plannedItems: [],
      );

      expect(engine.fingerprint(inputA), isNot(equals(engine.fingerprint(inputB))));
    });

    test('CognitiveRoutingEngine produces unique fingerprints for different candidate counts', () {
      final engine = CognitiveRoutingEngine();

      final inputA = CognitiveRoutingInput(
        dateStr: '2026-08-08',
        routines: const [{'id': '1'}],
        energyOutput: EnergyAnalyticsOutput(sampleCount: 0),
      );

      final inputB = CognitiveRoutingInput(
        dateStr: '2026-08-08',
        routines: const [{'id': '1'}, {'id': '2'}],
        energyOutput: EnergyAnalyticsOutput(sampleCount: 0),
      );

      expect(engine.fingerprint(inputA), isNot(equals(engine.fingerprint(inputB))));
    });

    test('FreshStartEngine produces unique fingerprints for different dates', () {
      final engine = FreshStartEngine();

      final inputA = FreshStartInput(now: DateTime(2026, 8, 8), stagnantGoals: const [], deadRoutines: const []);
      final inputB = FreshStartInput(now: DateTime(2026, 8, 9), stagnantGoals: const [], deadRoutines: const []);

      expect(engine.fingerprint(inputA), isNot(equals(engine.fingerprint(inputB))));
    });
  });
}
