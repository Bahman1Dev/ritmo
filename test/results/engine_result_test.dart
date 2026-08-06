import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/results/engine_result.dart';

void main() {
  test('1. EngineSuccess wraps value correctly', () {
    const result = EngineSuccess<int>(100);
    expect(result.data, equals(100));
    expect(result, isA<EngineResult<int>>());
  });

  test('2. EngineFailure wraps exception correctly', () {
    final error = Exception('Engine error');
    final result = EngineFailure<int>(error);
    expect(result.error, equals(error));
    expect(result, isA<EngineResult<int>>());
  });
}
