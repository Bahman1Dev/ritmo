import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1. sweep-line algorithm processes 10,000 intervals in under 50ms', () {
    final stopwatch = Stopwatch()..start();

    // 10,000 synthetic intervals
    final events = <_Event>[];
    for (var i = 0; i < 10000; i++) {
      final start = i * 5;
      final end = start + 30;
      events.add(_Event(start, 1));
      events.add(_Event(end, -1));
    }

    events.sort((a, b) => a.time.compareTo(b.time));

    var activeCount = 0;
    var maxOverlap = 0;
    for (final e in events) {
      activeCount += e.delta;
      if (activeCount > maxOverlap) {
        maxOverlap = activeCount;
      }
    }

    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(50));
    expect(maxOverlap, greaterThan(0));
  });
}

class _Event {
  _Event(this.time, this.delta);
  final int time;
  final int delta;
}
