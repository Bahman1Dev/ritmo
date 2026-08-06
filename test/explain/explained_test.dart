import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/explain/explained.dart';

void main() {
  test('1. Explained holds value and evidence list correctly', () {
    const item = Explained<double>(
      value: 85.5,
      evidence: [
        'Consistency score = 90%',
        'Energy alignment = HIGH',
      ],
    );
    expect(item.value, equals(85.5));
    expect(item.evidence.length, equals(2));
  });
}
