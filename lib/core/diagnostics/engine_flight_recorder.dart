class FlightRecord {
  FlightRecord({
    required this.engineType,
    required this.timestamp,
    required this.elapsedMs,
    required this.fingerprint,
    required this.cacheHit,
    this.error,
  });

  final Type engineType;
  final DateTime timestamp;
  final int elapsedMs;
  final String fingerprint;
  final bool cacheHit;
  final Object? error;
}

class EngineFlightRecorder {
  static const int maxCapacity = 100;
  final List<FlightRecord> _buffer = [];

  void record(FlightRecord r) {
    if (_buffer.length >= maxCapacity) {
      _buffer.removeAt(0);
    }
    _buffer.add(r);
  }

  List<FlightRecord> get records => List.unmodifiable(_buffer);

  void clear() => _buffer.clear();
}
