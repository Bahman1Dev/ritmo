import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:ritmo/core/analytics/mood_engine.dart';

void main() {
  group('MoodEngine Tests', () {
    final today = DateTime(2026, 6, 24);

    test('Insufficient data returns null correlation', () async {
      final engine = MoodEngine();
      final input = MoodEngineInput(
        moodLogs: [
          MoodLog(id: 'm1', mood: Mood.happy, valence: 5, loggedAt: today.millisecondsSinceEpoch),
        ],
        energyLogs: [
          EnergyLog(id: 'e1', energyLevel: EnergyLevel.high, source: 'MANUAL', loggedAt: today.millisecondsSinceEpoch),
        ],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.energyMoodCorrelation, isNull);
      expect(output.dominantMood, Mood.happy);
      expect(output.correlationInsight, contains('کافی نیست'));
    });

    test('Positive correlation test', () async {
      final engine = MoodEngine();
      final m1 = today.subtract(const Duration(hours: 4)).millisecondsSinceEpoch;
      final m2 = today.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      final m3 = today.millisecondsSinceEpoch;

      final input = MoodEngineInput(
        moodLogs: [
          MoodLog(id: 'm1', mood: Mood.sad, valence: 1, loggedAt: m1),
          MoodLog(id: 'm2', mood: Mood.neutral, valence: 3, loggedAt: m2),
          MoodLog(id: 'm3', mood: Mood.happy, valence: 5, loggedAt: m3),
        ],
        energyLogs: [
          EnergyLog(id: 'e1', energyLevel: EnergyLevel.low, source: 'MANUAL', loggedAt: m1),
          EnergyLog(id: 'e2', energyLevel: EnergyLevel.medium, source: 'MANUAL', loggedAt: m2),
          EnergyLog(id: 'e3', energyLevel: EnergyLevel.high, source: 'MANUAL', loggedAt: m3),
        ],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.energyMoodCorrelation, isNotNull);
      expect(output.energyMoodCorrelation, greaterThan(0.8));
      expect(output.correlationInsight, contains('مثبتی'));
    });

    test('Negative correlation test', () async {
      final engine = MoodEngine();
      final m1 = today.subtract(const Duration(hours: 4)).millisecondsSinceEpoch;
      final m2 = today.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      final m3 = today.millisecondsSinceEpoch;

      final input = MoodEngineInput(
        moodLogs: [
          MoodLog(id: 'm1', mood: Mood.happy, valence: 5, loggedAt: m1),
          MoodLog(id: 'm2', mood: Mood.neutral, valence: 3, loggedAt: m2),
          MoodLog(id: 'm3', mood: Mood.sad, valence: 1, loggedAt: m3),
        ],
        energyLogs: [
          EnergyLog(id: 'e1', energyLevel: EnergyLevel.low, source: 'MANUAL', loggedAt: m1),
          EnergyLog(id: 'e2', energyLevel: EnergyLevel.medium, source: 'MANUAL', loggedAt: m2),
          EnergyLog(id: 'e3', energyLevel: EnergyLevel.high, source: 'MANUAL', loggedAt: m3),
        ],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.energyMoodCorrelation, isNotNull);
      expect(output.energyMoodCorrelation, lessThan(-0.8));
      expect(output.correlationInsight, contains('معکوس'));
    });

    test('Circadian and cycle indirect insight test', () async {
      final engine = MoodEngine();
      final input = MoodEngineInput(
        moodLogs: [],
        energyLogs: [],
        today: today,
        isEnergyTuned: true,
        isUserMenstruating: true,
      );

      final output = await engine.calculate(input);
      expect(output.correlationInsight, contains('ریتمِ طبیعیِ بدن'));
    });
  });
}
