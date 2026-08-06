import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/assistant_engine.dart';
import 'package:ritmo/core/settings/settings_flags.dart';

void main() {
  group('Rule M-12 & SettingsFlags Privacy Gates', () {
    test('1. Male user => canShowCycle is false', () {
      final flags = SettingsFlags.fromMap({
        'user_gender': 'MALE',
        'cycle_consent': 'true',
        'module_cycle_enabled': 'true',
      });
      expect(flags.canShowCycle, isFalse);
    });

    test('2. Female user without consent => canShowCycle is false', () {
      final flags = SettingsFlags.fromMap({
        'user_gender': 'FEMALE',
        'cycle_consent': 'false',
        'module_cycle_enabled': 'true',
      });
      expect(flags.canShowCycle, isFalse);
    });

    test('3. Female user with consent and enabled module => canShowCycle is true', () {
      final flags = SettingsFlags.fromMap({
        'user_gender': 'FEMALE',
        'cycle_consent': 'true',
        'module_cycle_enabled': 'true',
      });
      expect(flags.canShowCycle, isTrue);
    });
  });

  group('Rule M-14 & AssistantEngine Gate', () {
    test('4. AssistantEngine with proactive disabled => returns empty suggestions', () async {
      final engine = AssistantEngine();
      final input = AssistantEngineInput(
        routines: [],
        routineCompletions: [],
        sleepLogs: [],
        energyLogs: [],
        moodLogs: [],
        goals: [],
        goalSteps: [],
        konkurStudySessions: [],
        today: DateTime(2026, 3, 20),
        isProactiveEnabled: false,
      );

      final output = await engine.calculate(input);
      expect(output.dynamicSuggestions, isEmpty);
      expect(output.systemHighlights, isEmpty);
    });
  });
}
