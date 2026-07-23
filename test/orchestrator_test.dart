import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';

class MockHeavyEngineInput {
  MockHeavyEngineInput(this.value);
  final int value;
}

class MockHeavyEngine implements CachedEngine<MockHeavyEngineInput, int> {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<int> calculate(MockHeavyEngineInput input) async {
    callCount++;
    if (shouldFail) {
      throw Exception('Simulation of engine failure');
    }
    return input.value * 2;
  }

  @override
  void invalidate() {}

  @override
  bool canRun(MockHeavyEngineInput input) => true;

  @override
  List<Type> dependencies() => [];
}

class DependentMockEngine implements CachedEngine<MockHeavyEngineInput, int> {
  int callCount = 0;

  @override
  Future<int> calculate(MockHeavyEngineInput input) async {
    callCount++;
    return input.value + 10;
  }

  @override
  void invalidate() {}

  @override
  bool canRun(MockHeavyEngineInput input) => true;

  @override
  List<Type> dependencies() => [MockHeavyEngine];
}

void main() {
  group('Ritmo Event Bus & Engine Bus & Orchestrator Tests', () {
    late RitmoEventBus eventBus;
    late EngineRegistry registry;
    late RitmoEngineBus engineBus;
    late RitmoIntelligenceOrchestrator orchestrator;

    late MockHeavyEngine mockEngine;
    late DependentMockEngine dependentEngine;

    setUp(() {
      eventBus = RitmoEventBus();
      registry = EngineRegistry();
      engineBus = RitmoEngineBus(registry: registry);
      orchestrator = RitmoIntelligenceOrchestrator(
        engineBus: engineBus,
        eventBus: eventBus,
      );

      mockEngine = MockHeavyEngine();
      dependentEngine = DependentMockEngine();

      registry.register(mockEngine);
      registry.register(dependentEngine);
    });

    tearDown(() {
      orchestrator.dispose();
    });

    test('Engine runs and caches the results on subsequent calls', () async {
      final input = MockHeavyEngineInput(5);
      final res1 = await engineBus.execute<MockHeavyEngineInput, int>(MockHeavyEngine, input);
      expect(res1, 10);
      expect(mockEngine.callCount, 1);

      // Subsequent call should hit cache and not increment callCount
      final res2 = await engineBus.execute<MockHeavyEngineInput, int>(MockHeavyEngine, input);
      expect(res2, 10);
      expect(mockEngine.callCount, 1);
      expect(engineBus.diagnostics.getMetrics(MockHeavyEngine).cacheHits, 1);
    });

    test('Event Bus firing invalidates engine cache', () async {
      final input = MockHeavyEngineInput(5);
      await engineBus.execute<MockHeavyEngineInput, int>(MockHeavyEngine, input);
      expect(mockEngine.callCount, 1);

      // Fire event to invalidate
      eventBus.fire(RitmoEvent(
        type: 'RoutineCompleted',
        timestamp: DateTime.now(),
        payload: {},
      ));

      // Wait a microtask for stream listener to handle the event
      await Future.delayed(Duration.zero);

      // Call should recalculate
      final res2 = await engineBus.execute<MockHeavyEngineInput, int>(MockHeavyEngine, input);
      expect(res2, 10);
      expect(mockEngine.callCount, 2);
    });

    test('Failure Isolation: failing engine records diagnostics and does not crash bus', () async {
      mockEngine.shouldFail = true;
      final input = MockHeavyEngineInput(5);

      try {
        await engineBus.execute<MockHeavyEngineInput, int>(MockHeavyEngine, input);
        fail('Should have thrown');
      } catch (_) {
        // expected
      }

      final metrics = engineBus.diagnostics.getMetrics(MockHeavyEngine);
      expect(metrics.failures, 1);
    });

    test('Dependency listing works correctly', () {
      expect(dependentEngine.dependencies(), contains(MockHeavyEngine));
    });
  });
}
