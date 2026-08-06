import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/time/time_base.dart';

void main() {
  tearDown(() {
    TimeBase.setMock(null);
  });

  test('1. TimeBase returns mock time when setMock is called', () {
    final mockTime = DateTime(2026, 5, 15, 10, 30);
    TimeBase.setMock(mockTime);
    expect(TimeBase.now, equals(mockTime));
    expect(TimeBase.todayStamp, equals('2026-05-15'));
  });

  test('2. TimeBase restores system time when setMock(null)', () {
    TimeBase.setMock(DateTime(2026, 5, 15));
    TimeBase.setMock(null);
    expect(TimeBase.now.year, greaterThanOrEqualTo(2026));
  });
}
