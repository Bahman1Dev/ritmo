import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/stats/sampled.dart';
import 'package:ritmo/core/stats/stats.dart';

void main() {
  test('1. weightedMean calculates correct weighted average', () {
    final now = DateTime(2026, 3, 20);
    final samples = [
      Sampled<num>(10, now, weight: 1.0),
      Sampled<num>(20, now, weight: 3.0),
    ];
    // (10*1 + 20*3) / 4 = 70 / 4 = 17.5
    expect(Stats.weightedMean(samples), equals(17.5));
  });

  test('2. exponentialDecay halves weight after 1 half-life', () {
    final now = DateTime(2026, 3, 20);
    final weekAgo = now.subtract(const Duration(days: 7));
    final decay = Stats.exponentialDecay(weekAgo, now, halfLifeDays: 7.0);
    expect(decay, closeTo(0.5, 0.001));
  });
}
