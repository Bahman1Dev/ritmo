import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';

void main() {
  group('ReflectionEngine Analytics Engine Tests', () {
    final engine = ReflectionEngine();

    test('calculate streak correctly - continuous', () async {
      final today = DateTime(2026, 6, 26);
      
      final input = ReflectionEngineInput(
        dailyReflections: [
          {'date': '2026-06-26', 'mood_score': 5},
          {'date': '2026-06-25', 'mood_score': 4},
          {'date': '2026-06-24', 'mood_score': 3},
        ],
        dailyCheckins: [],
        energyLogs: [],
        moodLogs: [],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.currentStreak, 3);
      expect(output.longestStreak, 3);
      expect(output.entryCount, 3);
      expect(output.completionRate, closeTo(3 / 14, 0.01));
    });

    test('calculate streak correctly - intermittent / broken streak', () async {
      final today = DateTime(2026, 6, 26);
      
      final input = ReflectionEngineInput(
        dailyReflections: [
          {'date': '2026-06-26', 'mood_score': 5},
          {'date': '2026-06-25', 'mood_score': 4},
          // Missing 24th
          {'date': '2026-06-23', 'mood_score': 3},
          {'date': '2026-06-22', 'mood_score': 4},
          {'date': '2026-06-21', 'mood_score': 4},
        ],
        dailyCheckins: [],
        energyLogs: [],
        moodLogs: [],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.currentStreak, 2); // 26, 25
      expect(output.longestStreak, 3); // 23, 22, 21
    });

    test('Pearson correlation - positive correlation', () async {
      final today = DateTime(2026, 6, 26);
      
      // We need at least 3 matching days
      final reflections = [
        {'date': '2026-06-26', 'mood_score': 5},
        {'date': '2026-06-25', 'mood_score': 4},
        {'date': '2026-06-24', 'mood_score': 2},
      ];

      // Mood logs (loggedAt timestamps corresponding to dates)
      final m26 = DateTime(2026, 6, 26, 12).millisecondsSinceEpoch;
      final m25 = DateTime(2026, 6, 25, 12).millisecondsSinceEpoch;
      final m24 = DateTime(2026, 6, 24, 12).millisecondsSinceEpoch;

      final moodLogs = [
        {'loggedAt': m26, 'valence': 5},
        {'loggedAt': m25, 'valence': 4},
        {'loggedAt': m24, 'valence': 2},
      ];

      final input = ReflectionEngineInput(
        dailyReflections: reflections,
        dailyCheckins: [],
        energyLogs: [],
        moodLogs: moodLogs,
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.reflectionMoodCorrelation, isNotNull);
      expect(output.reflectionMoodCorrelation, greaterThan(0.9));
      expect(output.correlationInsight, contains('روحیه بالاتری'));
    });

    test('Pearson correlation - low data null check', () async {
      final today = DateTime(2026, 6, 26);
      
      // Less than 3 matching days
      final reflections = [
        {'date': '2026-06-26', 'mood_score': 5},
        {'date': '2026-06-25', 'mood_score': 4},
      ];

      final m26 = DateTime(2026, 6, 26, 12).millisecondsSinceEpoch;
      final m25 = DateTime(2026, 6, 25, 12).millisecondsSinceEpoch;

      final moodLogs = [
        {'loggedAt': m26, 'valence': 5},
        {'loggedAt': m25, 'valence': 4},
      ];

      final input = ReflectionEngineInput(
        dailyReflections: reflections,
        dailyCheckins: [],
        energyLogs: [],
        moodLogs: moodLogs,
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.reflectionMoodCorrelation, isNull);
    });
  });
}
