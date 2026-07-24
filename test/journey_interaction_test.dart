import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/widgets/agenda_item_detail_sheet.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';

void main() {
  group('Phase 3 Actionable Interaction MVP Tests', () {
    final sampleItem = AgendaItem(
      id: 'test:item1',
      domain: AgendaDomain.routine,
      sourceId: 's1',
      title: 'Deep Focus Work',
      dateStr: '2026-07-24',
      timeOfDay: '09:00',
      durationMinutes: 90,
      category: Category.work,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 's1'),
    );

    final conflictItem = AgendaItem(
      id: 'test:item2',
      domain: AgendaDomain.course,
      sourceId: 's2',
      title: 'Math Lecture',
      dateStr: '2026-07-24',
      timeOfDay: '09:00',
      durationMinutes: 60,
      category: Category.learning,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: 's2'),
    );

    test('1. JourneyController manages highlight and focus state correctly', () {
      final controller = JourneyController();

      expect(controller.highlightedItemId, isNull);
      expect(controller.focusedMinutes, isNull);

      controller.highlightItem('test:item1');
      expect(controller.highlightedItemId, equals('test:item1'));

      controller.focusMinutes(540);
      expect(controller.focusedMinutes, equals(540));

      controller.clearFocusAndHighlight();
      expect(controller.highlightedItemId, isNull);
      expect(controller.focusedMinutes, isNull);
    });

    testWidgets('2. AgendaItemDetailSheet renders item details and triggers complete callback', (tester) async {
      var completed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AgendaItemDetailSheet(
            item: sampleItem,
            onComplete: () => completed = true,
          ),
        ),
      ));

      expect(find.text('Deep Focus Work'), findsOneWidget);
      expect(find.text('روتین'), findsOneWidget);

      await tester.tap(find.text('تکمیل'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('3. JourneySmartPanel triggers callbacks on selecting activity, gap, and conflict', (tester) async {
      AgendaItem? selectedActivity;
      TimeGap? selectedGap;
      AgendaConflict? selectedConflict;

      final conflict = AgendaConflict(
        itemA: sampleItem,
        itemB: conflictItem,
        type: ConflictType.sameStart,
        description: 'Collision at 09:00',
      );

      const gap = TimeGap(startMinutes: 720, endMinutes: 780);

      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda(dateStr: '2026-07-24', items: [sampleItem, conflictItem]),
        completedCount: 0,
        remainingCount: 2,
        freeGaps: [gap],
        conflicts: [conflict],
        overloadScore: 0.8,
        currentActivity: sampleItem,
        nextActivity: null,
        suggestions: const [],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneySmartPanel(
            snapshot: snapshot,
            onSelectActivity: (item) => selectedActivity = item,
            onSelectFreeGap: (g) => selectedGap = g,
            onSelectConflict: (c) => selectedConflict = c,
          ),
        ),
      ));

      // 1. Test Summary tab activity selection
      await tester.tap(find.text('Deep Focus Work'));
      await tester.pumpAndSettle();
      expect(selectedActivity?.id, equals(sampleItem.id));

      // 2. Test Suggestions / Conflicts tab conflict selection
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneySmartPanel(
            snapshot: snapshot,
            onSelectConflict: (c) => selectedConflict = c,
          ),
        ),
      ));
      await tester.tap(find.textContaining('پیشنهادها'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Collision at 09:00'));
      await tester.pumpAndSettle();
      expect(selectedConflict?.description, equals('Collision at 09:00'));

      // 3. Test Free Gaps tab gap selection
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneySmartPanel(
            snapshot: snapshot,
            onSelectFreeGap: (g) => selectedGap = g,
          ),
        ),
      ));
      await tester.tap(find.textContaining('زمان آزاد'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('۱۲:۰۰'));
      await tester.pumpAndSettle();
      expect(selectedGap?.startMinutes, equals(720));
    });
  });
}
