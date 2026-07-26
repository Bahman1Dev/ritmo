import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/onboarding/logic/day_arc_inferencer.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_draft.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_gate.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_module_map.dart';
import 'package:ritmo/features/onboarding/logic/starter_pack_catalog.dart';
import 'package:ritmo/features/onboarding/models/focus_area.dart';

void main() {
  group('Prompt 034 Onboarding Repair Unit Tests', () {
    test('1. FocusArea enum code roundtrip and legacy FA label parser', () {
      expect(FocusArea.fromCode('SPORT'), equals(FocusArea.sport));
      expect(FocusArea.fromCode('HEALTH'), equals(FocusArea.health));
      expect(FocusArea.fromLegacyFaLabel('سلامتی'), equals(FocusArea.health));
      expect(FocusArea.parse('ورزش'), equals(FocusArea.sport));
      expect(FocusArea.parse('STRESS'), equals(FocusArea.stress));
    });

    test('2. OnboardingModuleMap resolves correct keys and sets all canonical keys', () {
      final states = OnboardingModuleMap.resolveModuleStates(
        chosenAreas: {FocusArea.sport, FocusArea.sleep, FocusArea.health},
        isFemale: false,
      );

      expect(states['module_supplementary_sports_enabled'], equals('true'));
      expect(states['module_sleep_enabled'], equals('true'));
      expect(states['module_medicine_enabled'], equals('true'));
      expect(states['module_sports_enabled'], isNull); // Removed dead key
      expect(states['module_goals_enabled'], equals('false'));
    });

    test('3. OnboardingModuleMap handles female cycle module selection', () {
      final statesFemale = OnboardingModuleMap.resolveModuleStates(
        chosenAreas: {FocusArea.health},
        isFemale: true,
        enableCycle: true,
      );

      expect(statesFemale['module_cycle_enabled'], equals('true'));

      final statesMale = OnboardingModuleMap.resolveModuleStates(
        chosenAreas: {FocusArea.health},
        isFemale: false,
        enableCycle: true,
      );

      expect(statesMale['module_cycle_enabled'], equals('false'));
    });

    test('4. StarterPackCatalog suggests relevant templates', () {
      final sportTemplates = StarterPackCatalog.suggestFor({FocusArea.sport});
      expect(sportTemplates.any((t) => t.id == 'morning_stretch'), isTrue);

      final emptyTemplates = StarterPackCatalog.suggestFor({});
      expect(emptyTemplates.length, equals(3));
    });

    test('5. DayArcInferencer fallback behavior without city settings', () async {
      final suggestion = await DayArcInferencer.suggest();
      expect(suggestion.wakeTime, equals('07:00'));
      expect(suggestion.sleepTime, equals('23:00'));
      expect(suggestion.isInferred, isFalse);
    });

    test('6. OnboardingDraft serialization and deserialization', () {
      final draft = OnboardingDraft(
        stepIndex: 3,
        state: {
          'userName': 'علی',
          'gender': 'MALE',
          'focusAreas': ['SPORT', 'HEALTH'],
        },
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final json = draft.toJson();
      final restored = OnboardingDraft.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.stepIndex, equals(3));
      expect(restored.state['userName'], equals('علی'));
      expect(restored.state['focusAreas'], equals(['SPORT', 'HEALTH']));
    });

    test('7. OnboardingGate constants check', () {
      expect(OnboardingGate.currentVersion, equals(1));
    });
  });
}
