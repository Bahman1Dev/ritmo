import 'dart:math' as math;
import 'package:ritmo/core/stats/sampled.dart';

class Stats {
  static double weightedMean(List<Sampled<num>> samples) {
    if (samples.isEmpty) return 0;
    double sum = 0;
    double weightSum = 0;
    for (final s in samples) {
      sum += s.value * s.weight;
      weightSum += s.weight;
    }
    return weightSum > 0 ? sum / weightSum : 0;
  }

  static double exponentialDecay(DateTime timestamp, DateTime now,
      {double halfLifeDays = 7.0}) {
    final days = now.difference(timestamp).inSeconds / 86400.0;
    return math.pow(0.5, days / halfLifeDays).toDouble();
  }
}
