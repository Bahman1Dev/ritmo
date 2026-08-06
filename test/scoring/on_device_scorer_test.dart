import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/scoring/on_device_scorer.dart';

void main() {
  test('1. OnDeviceScorer returns exact baseScore when feature flag is false', () {
    final settings = {'on_device_scorer_enabled': 'false'};
    final result = OnDeviceScorer.score(baseScore: 78.5, settings: settings);
    expect(result, equals(78.5));
  });

  test('2. OnDeviceScorer isEnabled checks feature flag correctly', () {
    expect(OnDeviceScorer.isEnabled({'on_device_scorer_enabled': 'true'}), isTrue);
    expect(OnDeviceScorer.isEnabled({}), isFalse);
  });
}
