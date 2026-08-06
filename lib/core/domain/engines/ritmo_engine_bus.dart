import 'dart:async';
import 'package:ritmo/core/domain/engines/cache/cache_entry.dart';
import 'package:ritmo/core/domain/engines/cache/engine_key.dart';

abstract class CachedEngine<Input, Output> {
  Future<Output> calculate(Input input);

  /// String covering everything that changes output.
  String fingerprint(Input input) => input.toString();

  /// Cache TTL. Default 5 min; heavy engines can override with longer duration.
  Duration get ttl => const Duration(minutes: 5);

  void invalidate();
  bool canRun(Input input);
  List<Type> dependencies();
}

class EngineCannotRunException implements Exception {
  EngineCannotRunException(this.engineType, this.inputType);

  final Type engineType;
  final Type inputType;

  @override
  String toString() =>
      'EngineCannotRunException: Engine $engineType cannot run with input $inputType';
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

class EngineCacheStore {
  static const _maxEntries = 64;
  final Map<EngineKey, CacheEntry> _map = {};

  void set(EngineKey k, CacheEntry e) {
    if (_map.length >= _maxEntries) {
      final oldest = _map.entries
          .reduce((a, b) => a.value.computedAt.isBefore(b.value.computedAt) ? a : b);
      _map.remove(oldest.key);
    }
    _map[k] = e;
  }

  CacheEntry? get(EngineKey key) => _map[key];

  void invalidateType(Type engineType) {
    for (final k in _map.keys.where((k) => k.type == engineType).toList()) {
      final e = _map[k]!;
      e.data = null; // Memory released
      e.manuallyInvalidated = true; // Metadata remains for diagnostics
    }
  }

  void clear() => _map.clear();
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
  final Map<EngineKey, Future<dynamic>> _inFlight = {};

  void invalidate(Type engineType) {
    cacheStore.invalidateType(engineType);
  }

  static String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  Future<Output> execute<Input, Output>(dynamic engineOrType, Input input) {
    final Type engineType = engineOrType is Type
        ? engineOrType
        : (engineOrType as CachedEngine).runtimeType;
    final engine = registry.get<Input, Output>(engineType);

    // 1) Pre-condition check
    if (!engine.canRun(input)) {
      throw EngineCannotRunException(engineType, input.runtimeType);
    }

    // 2) Content-addressed key
    final key = EngineKey(engineType, engine.fingerprint(input));
    final todayKey = _todayKey();
    final now = DateTime.now();

    // 3) Fresh cache check
    final entry = cacheStore.get(key);
    if (entry != null && entry.isFresh(todayKey, now)) {
      diagnostics.recordCacheHit(engineType);
      return Future.value(entry.data as Output);
    }

    // 4) Single-flight deduplication (E-05)
    final pending = _inFlight[key];
    if (pending != null) return pending.then((v) => v as Output);

    final future =
        _run<Input, Output>(key, engineType, engine, input, todayKey)
            .whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = future;
    return future;
  }

  Future<Output> _run<Input, Output>(
    EngineKey key,
    Type engineType,
    CachedEngine<Input, Output> engine,
    Input input,
    String todayKey,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await engine.calculate(input);
      stopwatch.stop();
      diagnostics.recordExecution(engineType, stopwatch.elapsedMilliseconds);

      if (engine.ttl > Duration.zero) {
        cacheStore.set(
          key,
          CacheEntry(
            data: result,
            fingerprint: key.fingerprint,
            computedAt: DateTime.now(),
            dayStamp: todayKey,
            ttl: engine.ttl,
          ),
        );
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      diagnostics.recordFailure(engineType);
      rethrow;
    }
  }

  /// Pattern M-2: Return stale immediately, recompute fresh in background
  Stream<Output> observe<Input, Output>(
      dynamic engineOrType, Input input) async* {
    final Type engineType = engineOrType is Type
        ? engineOrType
        : (engineOrType as CachedEngine).runtimeType;
    final engine = registry.get<Input, Output>(engineType);
    if (!engine.canRun(input)) return;

    final key = EngineKey(engineType, engine.fingerprint(input));
    final entry = cacheStore.get(key);
    final todayKey = _todayKey();
    final now = DateTime.now();

    if (entry != null && entry.hasStale) {
      yield entry.data as Output;
      if (entry.isFresh(todayKey, now)) return;
    }
    yield await execute<Input, Output>(engineType, input);
  }
}
