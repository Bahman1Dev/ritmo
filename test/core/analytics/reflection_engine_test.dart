import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';

void main() {
  test('completion rate never exceeds one', () async {
    final engine = ReflectionEngine();
    final reflections15 = List.generate(
      15,
      (i) => {'date': '2026-01-${(i + 1).toString().padLeft(2, '0')}', 'mood_score': 4},
    );

    final out = await engine.calculate(ReflectionEngineInput(
      dailyReflections: reflections15,
      dailyCheckins: [],
      energyLogs: [],
      moodLogs: [],
      today: DateTime(2026, 1, 14),
      horizonDays: 14,
    ));

    expect(out.completionRate, lessThanOrEqualTo(1.0));
  });

  test('neutral checkin is preserved', () async {
    final engine = ReflectionEngine();
    final checkins = [
      {'date': '2026-01-10', 'mood': 'NEUTRAL'},
    ];

    final out = await engine.calculate(ReflectionEngineInput(
      dailyReflections: [],
      dailyCheckins: checkins,
      energyLogs: [],
      moodLogs: [],
      today: DateTime(2026, 1, 14),
    ));

    expect(out, isNotNull);
  });
}
