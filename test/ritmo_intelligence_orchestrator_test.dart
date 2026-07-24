import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';

void main() {
  group('RitmoIntelligenceOrchestrator Selective Tests', () {
    late RitmoEngineBus engineBus;
    late RitmoEventBus eventBus;
    late RitmoIntelligenceOrchestrator orchestrator;

    setUp(() {
      final registry = EngineRegistry();
      engineBus = RitmoEngineBus(registry: registry);
      eventBus = RitmoEventBus();
      orchestrator = RitmoIntelligenceOrchestrator(
        engineBus: engineBus,
        eventBus: eventBus,
      );
    });

    tearDown(() {
      orchestrator.dispose();
    });

    test('Orchestrator invalidates target engine cache stores on event', () async {
      // Put dummy valid caches in cacheStore for LifeBalanceEngine and CycleEngine
      engineBus.cacheStore.set<String>(LifeBalanceEngine, 'dummy_data');
      engineBus.cacheStore.set<String>(CycleEngine, 'dummy_cycle_data');

      expect(engineBus.cacheStore.get(LifeBalanceEngine)?.isValid, true);
      expect(engineBus.cacheStore.get(CycleEngine)?.isValid, true);

      // Fire RoutineCompleted event
      eventBus.fire(RitmoEvent(
        type: 'RoutineCompleted',
        timestamp: DateTime.now(),
        payload: {'routineId': 'r1'},
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      // LifeBalanceEngine should be marked invalid (isValid: false), CycleEngine should remain valid!
      expect(engineBus.cacheStore.get(LifeBalanceEngine)?.isValid, false);
      expect(engineBus.cacheStore.get(CycleEngine)?.isValid, true);
    });
  });
}
