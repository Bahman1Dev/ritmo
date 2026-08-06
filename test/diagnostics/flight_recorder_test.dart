import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/diagnostics/engine_flight_recorder.dart';

void main() {
  test('1. EngineFlightRecorder caps at maxCapacity (100) records', () {
    final recorder = EngineFlightRecorder();
    for (var i = 0; i < 120; i++) {
      recorder.record(FlightRecord(
        engineType: GoalsEngine,
        timestamp: DateTime.now(),
        elapsedMs: i,
        fingerprint: 'fp-$i',
        cacheHit: i % 2 == 0,
      ));
    }

    expect(recorder.records.length, equals(100));
    // Oldest record (0..19) should have been shifted out
    expect(recorder.records.first.elapsedMs, equals(20));
    expect(recorder.records.last.elapsedMs, equals(119));
  });
}
