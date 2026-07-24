import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_policy.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

void main() {
  group('EngineInvalidationPolicy Selective Tests', () {
    const policy = EngineInvalidationPolicy();

    test('1. RoutineCompleted invalidates routine-related engines, not CycleEngine or MedicalEngine', () {
      final event = RitmoEvent(
        type: 'RoutineCompleted',
        timestamp: DateTime.now(),
        payload: {'routineId': 'r1'},
      );

      final targets = policy.enginesToInvalidateFor(event);

      expect(targets.contains(LifeBalanceEngine), true);
      expect(targets.contains(GoalsEngine), true);
      expect(targets.contains(CycleEngine), false);
      expect(targets.contains(MedicalEngine), false);
    });

    test('2. CycleStarted invalidates CycleEngine, not LifeBalanceEngine', () {
      final event = RitmoEvent(
        type: 'CycleStarted',
        timestamp: DateTime.now(),
        payload: {},
      );

      final targets = policy.enginesToInvalidateFor(event);

      expect(targets.contains(CycleEngine), true);
      expect(targets.contains(LifeBalanceEngine), false);
    });

    test('3. ZoneChanged invalidates Zone-dependent engines only', () {
      final event = RitmoEvent(
        type: 'ZoneChanged',
        timestamp: DateTime.now(),
        payload: {},
      );

      final targets = policy.enginesToInvalidateFor(event);

      expect(targets.contains(LifeBalanceEngine), false);
      expect(targets.contains(CycleEngine), false);
      expect(targets.length < 5, true); // Not all engines!
    });

    test('4. RoutineDeleted is registered and invalidates routineStructure engines', () {
      final event = RitmoEvent(
        type: 'RoutineDeleted',
        timestamp: DateTime.now(),
        payload: {'routineId': 'r1'},
      );

      final targets = policy.enginesToInvalidateFor(event);

      expect(targets.contains(LifeBalanceEngine), true);
      expect(targets.contains(GoalsEngine), true);
    });
  });
}
