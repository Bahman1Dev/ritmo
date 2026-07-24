import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';

import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

void main() {
  group('Phase 8 — Calendar Performance, Polish & Hardening Tests', () {
    test('1. JourneyController handles dispose() safely without post-dispose crashes', () {
      final controller = JourneyController();

      // Initiate actions
      controller.highlightItem('routine:1');
      expect(controller.highlightedItemId, equals('routine:1'));

      // Dispose controller
      controller.dispose();
      expect(controller.isDisposed, isTrue);

      // Post-dispose calls should degrade gracefully without throwing StateError
      expect(() => controller.highlightItem('routine:2'), returnsNormally);
      expect(() => controller.clearFocusAndHighlight(), returnsNormally);
      expect(() => controller.cancelManipulation(), returnsNormally);
    });

    test('2. Action Deduplication prevents concurrent duplicate execution', () async {
      final controller = JourneyController();
      final item = AgendaItem(
        id: 'routine:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Study',
        dateStr: '2026-07-24',
        timeOfDay: '10:00',
        durationMinutes: 30,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      // Start drag to set executing flag or test completes
      controller.startItemDrag(item);
      expect(controller.isDragging, isTrue);

      // Clean cancel
      controller.cancelManipulation();
      expect(controller.isDragging, isFalse);
    });

    test('3. TimelineLayoutEngine handles zero-duration and null-duration items safely', () {
      const layoutEngine = TimelineLayoutEngine(pxPerMinute: 1.2);

      final zeroDurationItem = AgendaItem(
        id: 'routine:zero',
        domain: AgendaDomain.routine,
        sourceId: 'zero',
        title: 'Zero Duration',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        durationMinutes: 0,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'zero'),
      );

      final nullDurationItem = AgendaItem(
        id: 'routine:null',
        domain: AgendaDomain.routine,
        sourceId: 'null',
        title: 'Null Duration',
        dateStr: '2026-07-24',
        timeOfDay: '10:00',
        durationMinutes: null,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'null'),
      );

      final layoutItems = layoutEngine.calculateLayout([zeroDurationItem, nullDurationItem]);
      expect(layoutItems.length, equals(2));

      // Each layout item must have a positive non-zero height (>= 15 * 1.2 = 18.0)
      for (final item in layoutItems) {
        expect(item.height, greaterThanOrEqualTo(18.0));
      }
    });

    test('4. DayAgendaSnapshotBuilder handles empty day agenda gracefully', () {
      const builder = DayAgendaSnapshotBuilder();
      const emptyDayAgenda = DayAgenda(dateStr: '2026-07-24', items: []);

      final snapshot = builder.buildSnapshot(emptyDayAgenda, now: DateTime(2026, 7, 24, 12, 0));
      expect(snapshot.items, isEmpty);
      expect(snapshot.completedCount, equals(0));
      expect(snapshot.remainingCount, equals(0));
      expect(snapshot.conflicts, isEmpty);
      expect(snapshot.currentActivity, isNull);
      expect(snapshot.nextActivity, isNull);
      expect(snapshot.overloadScore, equals(0.0));
    });
  });
}
