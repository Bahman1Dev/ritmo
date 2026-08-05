import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/wellbeing_engine.dart';

final _now = DateTime(2026, 1, 15, 12);

WellbeingEngineInput _input({
  int sleepNights = 0,
  double? avgSleepHours,
  double? avgSleepQuality,
  double? sleepConsistency,
  int energySamples = 0,
  double? avgEnergyLevel,
  int moodSamples = 0,
  double? avgMoodScore,
  int reflectionEntries = 0,
  double? avgReflectionMood,
}) {
  return WellbeingEngineInput(
    now: _now,
    sleepNights: sleepNights,
    avgSleepHours: avgSleepHours,
    avgSleepQuality: avgSleepQuality,
    sleepConsistency: sleepConsistency,
    energySamples: energySamples,
    avgEnergyLevel: avgEnergyLevel,
    moodSamples: moodSamples,
    avgMoodScore: avgMoodScore,
    reflectionEntries: reflectionEntries,
    avgReflectionMood: avgReflectionMood,
  );
}

void main() {
  const engine = WellbeingEngine();

  test('no data returns null, never zero', () {
    final r = engine.compute(_input());
    expect(r.value, isNull);
    expect(r.hasValue, isFalse);
    expect(r.confidence, 0.0);
    expect(r.missing.length, 4);
  });

  test('below minimum samples still returns null', () {
    final r = engine.compute(_input(sleepNights: 2, avgSleepHours: 7.5));
    expect(r.value, isNull);
  });

  test('missing signals do not drag the index down', () {
    // فقط خواب و انرژی داده دارند و هر دو کاملند.
    final r = engine.compute(_input(
      sleepNights: 7, avgSleepHours: 7.5,
      energySamples: 14, avgEnergyLevel: 3.0,
    ));
    expect(r.value, isNotNull);
    // میانگین دو سیگنال کامل باید بالا بماند، نه نصف شود.
    expect(r.value, greaterThan(90));
    expect(r.confidence, closeTo(0.65, 0.01)); // 0.35 + 0.30
  });

  test('oversleeping is penalized, not rewarded', () {
    final perfect = WellbeingEngine.sleepDurationScore(7.5, 7.5);
    final over = WellbeingEngine.sleepDurationScore(12.0, 7.5);
    final under = WellbeingEngine.sleepDurationScore(4.0, 7.5);
    expect(perfect, closeTo(100, 0.001));
    expect(over, lessThan(perfect));
    expect(under, lessThan(perfect));
  });

  test('sleep score renormalizes when quality is unknown', () {
    final withQuality = WellbeingEngine.sleepScore(
        hours: 7.5, target: 7.5, quality: 100, consistency: 100);
    final withoutQuality =
        WellbeingEngine.sleepScore(hours: 7.5, target: 7.5);
    expect(withQuality, closeTo(100, 0.001));
    expect(withoutQuality, closeTo(100, 0.001)); // نه ۵۰
  });

  test('confidence ramps from min to full', () {
    expect(WellbeingEngine.confidenceFor(2, 3, 7), 0.0);
    expect(WellbeingEngine.confidenceFor(3, 3, 7), 0.5);
    expect(WellbeingEngine.confidenceFor(7, 3, 7), 1.0);
    expect(WellbeingEngine.confidenceFor(99, 3, 7), 1.0);
  });

  test('waterfall always reconciles with the final value', () {
    final r = engine.compute(_input(
      sleepNights: 7, avgSleepHours: 6.0,
      energySamples: 14, avgEnergyLevel: 2.0,
      moodSamples: 14, avgMoodScore: 3.0,
      reflectionEntries: 7, avgReflectionMood: 4.0,
    ));
    final sum = r.waterfall.values.fold<double>(0, (a, b) => a + b);
    expect(50 + sum, closeTo(r.value!, 0.0001));
  });

  test('uncertainty shrinks as confidence grows', () {
    final low = engine.compute(_input(sleepNights: 3, avgSleepHours: 7.5,
        energySamples: 3, avgEnergyLevel: 2.0));
    final high = engine.compute(_input(sleepNights: 7, avgSleepHours: 7.5,
        energySamples: 14, avgEnergyLevel: 2.0,
        moodSamples: 14, avgMoodScore: 3.0,
        reflectionEntries: 7, avgReflectionMood: 3.0));
    expect(high.uncertainty, lessThan(low.uncertainty));
  });

  test('index is always inside 0..100', () {
    final r = engine.compute(_input(
      sleepNights: 7, avgSleepHours: 0.5,
      energySamples: 14, avgEnergyLevel: 1.0,
      moodSamples: 14, avgMoodScore: 1.0,
      reflectionEntries: 7, avgReflectionMood: 1.0,
    ));
    expect(r.value, inInclusiveRange(0, 100));
  });

  test('engine is deterministic and does not read the clock', () {
    final a = engine.compute(_input(sleepNights: 7, avgSleepHours: 7.0,
        energySamples: 14, avgEnergyLevel: 2.5));
    final b = engine.compute(_input(sleepNights: 7, avgSleepHours: 7.0,
        energySamples: 14, avgEnergyLevel: 2.5));
    expect(a.value, b.value);
    expect(a.computedAtMillis, b.computedAtMillis);
  });
}
