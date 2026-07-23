import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';

void main() {
  test('Dashboard Bus Migration - EnergyAnalyticsEngine via RitmoEngineBus', () async {
    final registry = EngineRegistry()..register(EnergyAnalyticsEngine());
    RitmoEngineBus.init(registry);
    final bus = RitmoEngineBus.instance;

    final input = EnergyAnalyticsEngineInput(
      energyLogs: [],
      routineCompletions: [],
      dailyRhythm: [],
      now: DateTime(2026, 6, 22, 18), // 18:00 (Circadian: 0%)
    );

    final out1 = await bus.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
      EnergyAnalyticsEngine,
      input,
    );

    expect(out1.currentDynamicEnergy, 60.0); // default basePercent since energyLogs is empty

    final out2 = await bus.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
      EnergyAnalyticsEngine,
      input,
    );

    expect(out2.currentDynamicEnergy, 60.0);
    expect(bus.diagnostics.getMetrics(EnergyAnalyticsEngine).cacheHits, greaterThan(0));
  });

  test('RitmoIntelligenceOrchestrator invalidation cycle test', () async {
    final registry = EngineRegistry()..register(EnergyAnalyticsEngine());
    RitmoEngineBus.init(registry);
    final bus = RitmoEngineBus.instance;

    final orchestrator = RitmoIntelligenceOrchestrator(
      engineBus: bus,
      eventBus: RitmoEventBus(),
    );

    final input = EnergyAnalyticsEngineInput(
      energyLogs: [],
      routineCompletions: [],
      dailyRhythm: [],
      now: DateTime(2026, 6, 22, 18),
    );

    // Initial execution
    await bus.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
      EnergyAnalyticsEngine,
      input,
    );

    // Cache should be valid initially
    expect(bus.cacheStore.get(EnergyAnalyticsEngine)?.isValid, isTrue);

    // Fire event that triggers invalidation (e.g., RoutineCompleted)
    RitmoEventBus().fire(RitmoEvent(
      type: 'RoutineCompleted',
      timestamp: DateTime.now(),
      payload: {},
    ));

    // Wait a brief moment for stream delivery
    await Future.delayed(const Duration(milliseconds: 10));

    // Cache should be invalid now
    expect(bus.cacheStore.get(EnergyAnalyticsEngine)?.isValid, isFalse);

    orchestrator.dispose();
  });
}
