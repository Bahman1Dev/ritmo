import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/domain/models/duration_variants.dart';

void main() {
  group('CompletionResult Tests', () {
    test('fromDb converts values correctly', () {
      expect(CompletionResult.fromDb('FULL'), CompletionResult.full);
      expect(CompletionResult.fromDb('COMPLETED'), CompletionResult.full);
      expect(CompletionResult.fromDb('LIGHT'), CompletionResult.light);
      expect(CompletionResult.fromDb('MINIMAL'), CompletionResult.minimal);
      expect(CompletionResult.fromDb('PARTIAL'), CompletionResult.partial);
      expect(CompletionResult.fromDb('SKIPPED'), CompletionResult.skipped);
    });

    test('rhythmWeight returns expected values', () {
      expect(CompletionResult.full.rhythmWeight(), 1.0);
      expect(CompletionResult.light.rhythmWeight(), 0.7);
      expect(CompletionResult.minimal.rhythmWeight(), 0.3);
      expect(CompletionResult.skipped.rhythmWeight(), 0.0);
      expect(CompletionResult.partial.rhythmWeight(0.6), 0.6);
    });

    test('streak and progression properties', () {
      expect(CompletionResult.full.keepsStreak, true);
      expect(CompletionResult.full.advancesProgression, true);

      expect(CompletionResult.light.keepsStreak, true);
      expect(CompletionResult.light.advancesProgression, false);

      expect(CompletionResult.minimal.keepsStreak, true);
      expect(CompletionResult.minimal.advancesProgression, false);

      expect(CompletionResult.skipped.keepsStreak, false);
      expect(CompletionResult.skipped.advancesProgression, false);
    });
  });

  group('DurationVariants Tests', () {
    test('calculates light (50%) and minimal (15%) with caps', () {
      expect(DurationVariants.light(20), 10);
      expect(DurationVariants.minimal(20), 3);

      expect(DurationVariants.light(60), 30);
      expect(DurationVariants.minimal(60), 9);

      expect(DurationVariants.light(120), 60);
      expect(DurationVariants.minimal(120), 10); // Capped at 10
    });

    test('supportsVariants requires target > 5', () {
      expect(DurationVariants.supportsVariants(5), false);
      expect(DurationVariants.supportsVariants(6), true);
    });
  });

  group('SnoozePolicy Tests', () {
    test('maxCap limits medical and essential items to 2', () {
      expect(SnoozePolicy.maxCap(category: 'medical'), 2);
      expect(SnoozePolicy.maxCap(isEssential: 1), 2);
      expect(SnoozePolicy.maxCap(category: 'general'), 3);
    });

    test('evaluates allowed snooze', () {
      final now = DateTime(2026, 7, 25, 10, 0);
      final decision = SnoozePolicy.evaluate(
        itemId: 'item_1',
        now: now,
        requestedMinutes: 15,
        currentDeferCount: 0,
      );

      expect(decision.verdict, SnoozeVerdict.allowed);
      expect(decision.remaining, 2);
    });

    test('evaluates exhausted snooze', () {
      final now = DateTime(2026, 7, 25, 10, 0);
      final decision = SnoozePolicy.evaluate(
        itemId: 'item_1',
        now: now,
        requestedMinutes: 15,
        currentDeferCount: 3,
      );

      expect(decision.verdict, SnoozeVerdict.exhausted);
      expect(decision.exits.isNotEmpty, true);
    });

    test('blocks snooze past midnight', () {
      final now = DateTime(2026, 7, 25, 23, 50);
      final decision = SnoozePolicy.evaluate(
        itemId: 'item_1',
        now: now,
        requestedMinutes: 20,
        currentDeferCount: 0,
      );

      expect(decision.verdict, SnoozeVerdict.blockedMidnight);
    });
  });
}
