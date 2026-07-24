import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_overload_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_suggestion_ranker.dart';
import 'package:ritmo/core/domain/agenda/analysis/models/suggestion_signal_bundle.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  group('Phase 7 — Calendar Intelligence & Suggestion Quality Upgrade Tests', () {
    final flexibleRoutine = AgendaItem(
      id: 'routine:flex_study',
      domain: AgendaDomain.routine,
      sourceId: 'flex_study',
      title: 'مطالعه برنامه نویسی',
      dateStr: '2026-07-24',
      timeOfDay: '10:00',
      durationMinutes: 45,
      category: Category.learning,
      itemType: AgendaItemType.flexible,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'flex_study'),
    );

    final fixedPrayer = AgendaItem(
      id: 'prayer:dhuhr',
      domain: AgendaDomain.prayer,
      sourceId: 'dhuhr',
      title: 'نماز ظهر',
      dateStr: '2026-07-24',
      timeOfDay: '10:00',
      durationMinutes: 30,
      category: Category.religious,
      itemType: AgendaItemType.fixed,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.prayer, targetId: 'dhuhr'),
    );

    final fixedMeeting = AgendaItem(
      id: 'routine:fixed_meeting',
      domain: AgendaDomain.prayer, // Fixed non-movable domain
      sourceId: 'fixed_meeting',
      title: 'جلسه کاری ثابت',
      dateStr: '2026-07-24',
      timeOfDay: '10:00',
      durationMinutes: 30,
      category: Category.work,
      itemType: AgendaItemType.fixed,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.prayer, targetId: 'fixed_meeting'),
    );

    test('1. Conflict Reasoning distinguishes hard fixed-fixed vs flexible resolvable conflicts', () {
      const detector = AgendaConflictDetector();

      // Flexible vs Fixed conflict
      final resolvableConflicts = detector.detectConflicts([flexibleRoutine, fixedPrayer]);
      expect(resolvableConflicts.length, equals(1));
      expect(resolvableConflicts.first.isHardConflict, isFalse);
      expect(resolvableConflicts.first.isResolvable, isTrue);

      // Fixed vs Fixed conflict
      final hardConflicts = detector.detectConflicts([fixedMeeting, fixedPrayer]);
      expect(hardConflicts.length, equals(1));
      expect(hardConflicts.first.isHardConflict, isTrue);
      expect(hardConflicts.first.isResolvable, isFalse);
      expect(hardConflicts.first.severity, equals(1.0));
    });

    test('2. Free Gap Quality scoring penalizes short/sleep gaps and prefers daytime gaps', () {
      const gapCalculator = AgendaGapCalculator(wakingStartMinutes: 420, wakingEndMinutes: 1380);

      final items = [
        AgendaItem(
          id: '1',
          domain: AgendaDomain.routine,
          sourceId: '1',
          title: 'Work Block',
          dateStr: '2026-07-24',
          timeOfDay: '08:00',
          durationMinutes: 240, // 08:00 to 12:00
          category: Category.work,
          deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
        ),
      ];

      final gaps = gapCalculator.calculateFreeGaps(items);
      expect(gaps.isNotEmpty, isTrue);

      // Top gap should be usable and have high quality score
      final topGap = gaps.first;
      expect(topGap.isUsable, isTrue);
      expect(topGap.qualityScore, greaterThan(0.5));
      expect(topGap.qualityTag, contains('فرصت'));
    });

    test('3. Overload Detector identifies peak overloaded hour blocks correctly', () {
      const overloadDetector = AgendaOverloadDetector();

      final items = [
        AgendaItem(
          id: '1',
          domain: AgendaDomain.routine,
          sourceId: '1',
          title: 'Task A',
          dateStr: '2026-07-24',
          timeOfDay: '14:00',
          durationMinutes: 30,
          category: Category.work,
          deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
        ),
        AgendaItem(
          id: '2',
          domain: AgendaDomain.routine,
          sourceId: '2',
          title: 'Task B',
          dateStr: '2026-07-24',
          timeOfDay: '14:30',
          durationMinutes: 30,
          category: Category.work,
          deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '2'),
        ),
      ];

      final overloadedHours = overloadDetector.findOverloadedHourBlocks(items);
      expect(overloadedHours.contains(14), isTrue); // Hour 14 is 100% booked (60 mins)
      expect(overloadedHours.contains(10), isFalse);
    });

    test('4. Suggestion Ranker filters unactionable hard conflicts and ranks resolvable suggestions', () {
      const ranker = AgendaSuggestionRanker();
      const detector = AgendaConflictDetector();
      const gapCalculator = AgendaGapCalculator();

      // Case A: Hard conflict produces warning, not fake move action
      final hardConflicts = detector.detectConflicts([fixedMeeting, fixedPrayer]);
      final hardSuggestions = ranker.generateSuggestions(
        items: [fixedMeeting, fixedPrayer],
        conflicts: hardConflicts,
        freeGaps: const [TimeGap(startMinutes: 720, endMinutes: 780)],
        overloadScore: 0.5,
      );

      final hardMoveSuggestions = hardSuggestions.where((s) => s.categoryTag == 'conflictResolution' && s.isActionable);
      expect(hardMoveSuggestions.isEmpty, isTrue);

      // Case B: Flexible conflict produces actionable move suggestion into free gap
      final resolvableConflicts = detector.detectConflicts([flexibleRoutine, fixedPrayer]);
      final freeGaps = gapCalculator.calculateFreeGaps([flexibleRoutine, fixedPrayer]);
      final resolvableSuggestions = ranker.generateSuggestions(
        items: [flexibleRoutine, fixedPrayer],
        conflicts: resolvableConflicts,
        freeGaps: freeGaps,
        overloadScore: 0.5,
      );

      final moveSuggestion = resolvableSuggestions.firstWhere((s) => s.categoryTag == 'conflictResolution');
      expect(moveSuggestion.isActionable, isTrue);
      expect(moveSuggestion.targetItemId, equals(flexibleRoutine.id));
      expect(moveSuggestion.explanationReason, contains('ترمیم'));
    });

    test('5. Suggestion Signal Bundle cleanly encapsulates context signals', () {
      final bundle = SuggestionSignalBundle(
        items: [flexibleRoutine, fixedPrayer],
        conflicts: const [],
        freeGaps: const [TimeGap(startMinutes: 600, endMinutes: 660)],
        overloadScore: 0.4,
        now: DateTime(2026, 7, 24, 10, 15),
      );

      expect(bundle.completedCount, equals(0));
      expect(bundle.pendingCount, equals(2));
      expect(bundle.currentMinutes, equals(615));
    });
  });
}
