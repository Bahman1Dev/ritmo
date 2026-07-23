import 'dart:async';

abstract class CachedEngine<Input, Output> {
  Future<Output> calculate(Input input);
  void invalidate();
  bool canRun(Input input);
  List<Type> dependencies();
}

class EngineRegistry {
  final Map<Type, CachedEngine> _registry = {};

  void register(CachedEngine engine) {
    _registry[engine.runtimeType] = engine;
  }

  CachedEngine<Input, Output> get<Input, Output>(Type type) {
    final engine = _registry[type];
    if (engine == null) {
      throw Exception('Engine $type not registered');
    }
    return engine as CachedEngine<Input, Output>;
  }

  List<Type> get registeredTypes => _registry.keys.toList();
}

class CacheEntry {

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.sourceVersion,
    required this.isValid,
  });
  final dynamic data;
  final DateTime timestamp;
  final int sourceVersion;
  final bool isValid;
}

class EngineCacheStore {
  final Map<Type, CacheEntry> _cache = {};

  void set<Output>(Type engineType, Output data, {int sourceVersion = 1, bool isValid = true}) {
    _cache[engineType] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      sourceVersion: sourceVersion,
      isValid: isValid,
    );
  }

  CacheEntry? get(Type engineType) {
    return _cache[engineType];
  }

  void invalidate(Type engineType) {
    final entry = _cache[engineType];
    if (entry != null) {
      _cache[engineType] = CacheEntry(
        data: entry.data,
        timestamp: entry.timestamp,
        sourceVersion: entry.sourceVersion,
        isValid: false,
      );
    }
  }

  void clear() {
    _cache.clear();
  }
}

class EngineMetrics {
  int executionTimeMs = 0;
  int cacheHits = 0;
  int failures = 0;
  DateTime? lastExecution;
}

class EngineDiagnostics {
  final Map<Type, EngineMetrics> _metrics = {};

  EngineMetrics getMetrics(Type engineType) {
    return _metrics.putIfAbsent(engineType, EngineMetrics.new);
  }

  void recordExecution(Type engineType, int elapsedMs) {
    final m = getMetrics(engineType);
    m.executionTimeMs = elapsedMs;
    m.lastExecution = DateTime.now();
  }

  void recordCacheHit(Type engineType) {
    final m = getMetrics(engineType);
    m.cacheHits++;
  }

  void recordFailure(Type engineType) {
    final m = getMetrics(engineType);
    m.failures++;
  }
}

class RitmoEngineBus {

  RitmoEngineBus({required this.registry});
  static RitmoEngineBus? _instance;
  static RitmoEngineBus get instance {
    if (_instance == null) {
      throw Exception('RitmoEngineBus not initialized. Call init() first.');
    }
    return _instance!;
  }

  static void init(EngineRegistry registry) {
    _instance = RitmoEngineBus(registry: registry);
  }

  final EngineRegistry registry;
  final EngineCacheStore cacheStore = EngineCacheStore();
  final EngineDiagnostics diagnostics = EngineDiagnostics();

  Future<Output> execute<Input, Output>(Type engineType, Input input) async {
    final engine = registry.get<Input, Output>(engineType);

    // Check if cache is valid
    final cached = cacheStore.get(engineType);
    if (cached != null && cached.isValid) {
      diagnostics.recordCacheHit(engineType);
      return cached.data as Output;
    }

    if (!engine.canRun(input)) {
      throw Exception('Engine $engineType cannot run with the provided input');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await engine.calculate(input);
      stopwatch.stop();
      diagnostics.recordExecution(engineType, stopwatch.elapsedMilliseconds);
      cacheStore.set<Output>(engineType, result);
      return result;
    } catch (e) {
      stopwatch.stop();
      diagnostics.recordFailure(engineType);
      rethrow;
    }
  }

  void invalidate(Type engineType) {
    cacheStore.invalidate(engineType);
    try {
      final engine = registry.get(engineType);
      engine.invalidate();
    } catch (_) {}
  }
}
