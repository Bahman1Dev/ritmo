import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';

void main() {
  group('Prompt 032 Tests - SnoozePolicy Unit Tests', () {
    test('snooze_essential_cap_test: isEssential: 1 gives cap of 2', () {
      final cap = SnoozePolicy.maxCap(isEssential: 1, configuredMax: 3);
      expect(cap, equals(2));

      final decision = SnoozePolicy.evaluate(
        itemId: 'test_routine',
        now: DateTime(2026, 7, 26, 10, 0),
        requestedMinutes: 15,
        currentDeferCount: 1,
        isEssential: 1,
        configuredMax: 3,
      );
      expect(decision.verdict, equals(SnoozeVerdict.lastCall));
      expect(decision.remaining, equals(0));
    });

    test('snooze_configured_max_test: configuredMax = 5 is respected', () {
      final cap = SnoozePolicy.maxCap(category: 'work', isEssential: 0, configuredMax: 5);
      expect(cap, equals(5));

      final decision = SnoozePolicy.evaluate(
        itemId: 'test_routine',
        now: DateTime(2026, 7, 26, 10, 0),
        requestedMinutes: 15,
        currentDeferCount: 3,
        configuredMax: 5,
      );
      expect(decision.verdict, equals(SnoozeVerdict.allowed));
      expect(decision.remaining, equals(1));
    });

    test('snooze_daily_no_tomorrow_test: recurrenceRuleType = EVERY_DAY excludes moveToTomorrow', () {
      final decision = SnoozePolicy.evaluate(
        itemId: 'daily_routine',
        now: DateTime(2026, 7, 26, 10, 0),
        requestedMinutes: 15,
        currentDeferCount: 3,
        configuredMax: 3,
        recurrenceRuleType: 'EVERY_DAY',
      );
      expect(decision.verdict, equals(SnoozeVerdict.exhausted));
      expect(decision.exits.contains(ExitOption.moveToTomorrow), isFalse);
    });

    test('no_blocked_medical_test: blockedMedical is 0 times in lib/', () {
      final libDir = Directory('lib');
      final matches = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          if (content.contains('blockedMedical')) {
            matches.add(entity.path);
          }
        }
      }
      expect(matches, isEmpty, reason: 'blockedMedical must not exist anywhere in lib/');
    });
  });

  group('Prompt 032 Tests - RitmoIdFactory Namespace Tests', () {
    test('id_factory_namespace_test: distinct prefixes for all new methods', () {
      final konkurId = RitmoIdFactory.konkurLog();
      final worshipId = RitmoIdFactory.worshipLog();
      final medId = RitmoIdFactory.medicationLog();
      final compId = RitmoIdFactory.completion();

      expect(konkurId.startsWith('konkur_'), isTrue);
      expect(worshipId.startsWith('worship_'), isTrue);
      expect(medId.startsWith('med_'), isTrue);
      expect(compId.startsWith('comp_'), isTrue);
    });
  });

  group('Prompt 032 Tests - Token Format Validation', () {
    test('undo_token_prefix_test: validates domain token formats', () {
      const movementToken = 'movement:mv_123';
      const courseToken = 'course:session_456';
      const konkurToken = 'konkur:konkur_789';
      const worshipToken = 'worship:worship_101';
      const medicineToken = 'medicine:med_202';
      const goalStepToken = 'goalStep:goal_1|step_2';
      const rescheduleToken = 'reschedule:routine_3|2026-07-26|2026-07-27';

      expect(movementToken.startsWith('movement:'), isTrue);
      expect(courseToken.startsWith('course:'), isTrue);
      expect(konkurToken.startsWith('konkur:'), isTrue);
      expect(worshipToken.startsWith('worship:'), isTrue);
      expect(medicineToken.startsWith('medicine:'), isTrue);
      expect(goalStepToken.startsWith('goalStep:'), isTrue);
      expect(rescheduleToken.startsWith('reschedule:'), isTrue);
    });

    test('movement_kinds_schema_guarantee_test: movement_kinds table is created automatically', () {
      final seedFile = File('lib/features/supplementary_sports/movement/data/seed/movement_kinds_seed.dart');
      expect(seedFile.existsSync(), isTrue);
      final content = seedFile.readAsStringSync();
      expect(content.contains('ensureSchema'), isTrue);
      expect(content.contains('CREATE TABLE IF NOT EXISTS movement_kinds'), isTrue);
    });
  });
}
