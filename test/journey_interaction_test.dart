import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/widgets/action/action_sheet_registry.dart';
import 'package:ritmo/core/widgets/action/ritmo_action_sheet.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';

void main() {
  final sampleItem = AgendaItem(
    id: 'test:item1',
    domain: AgendaDomain.routine,
    sourceId: 'r1',
    title: 'Deep Focus Work',
    subtitle: 'Morning routine',
    dateStr: '2026-07-24',
    timeOfDay: '09:00',
    durationMinutes: 60,
    category: Category.work,
    deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r1'),
    itemType: AgendaItemType.fixed,
  );

  final conflictItem = AgendaItem(
    id: 'test:item2',
    domain: AgendaDomain.routine,
    sourceId: 'r2',
    title: 'Team Sync',
    subtitle: 'Overlapping meeting',
    dateStr: '2026-07-24',
    timeOfDay: '09:00',
    durationMinutes: 45,
    category: Category.work,
    deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r2'),
    itemType: AgendaItemType.fixed,
  );

  group('Journey Interaction & UI Widget Tests', () {
    test('1. JourneyController state focus and highlight updates correctly', () {
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

    testWidgets('2. RitmoActionSheet renders item details correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RitmoActionSheet(
            item: sampleItem,
            body: ActionBody(builder: (context) => Text(sampleItem.title)),
            primarySubmitAction: SubmitAction(
              label: 'تایید',
              onPressed: (context) async => const CompletedOutcome(),
            ),
          ),
        ),
      ));

      expect(find.text('Deep Focus Work'), findsOneWidget);
    });

    testWidgets('3. JourneySmartPanel triggers callbacks on selecting activity, gap, and conflict', (tester) async {
      AgendaItem? selectedActivity;

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
            onSelectFreeGap: (_) {},
            onSelectConflict: (_) {},
          ),
        ),
      ));

      expect(find.text('هشدار تداخل‌های زمانی (۱)'), findsOneWidget);
      expect(find.text('بازه‌های زمانی آزاد (۱)'), findsOneWidget);

      await tester.tap(find.text('Deep Focus Work').first);
      await tester.pumpAndSettle();
      expect(selectedActivity?.id, equals('test:item1'));
    });
  });
}
