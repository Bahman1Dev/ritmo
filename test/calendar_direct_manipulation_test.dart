import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';

void main() {
  group('Calendar Direct Manipulation MVP Tests', () {
    test('1. DirectManipulationEligibility rules verify item eligibility correctly', () {
      final movableRoutine = AgendaItem(
        id: 'routine:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Exercise',
        dateStr: '2026-07-24',
        timeOfDay: '08:00',
        durationMinutes: 30,
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final fixedPrayer = AgendaItem(
        id: 'prayer:fajr',
        domain: AgendaDomain.prayer,
        sourceId: 'fajr',
        title: 'نماز صبح',
        dateStr: '2026-07-24',
        timeOfDay: '04:30',
        category: Category.religious,
        itemType: AgendaItemType.fixed,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.prayer, targetId: 'fajr'),
      );

      final allDayItem = AgendaItem(
        id: 'goalStep:1',
        domain: AgendaDomain.goalStep,
        sourceId: '1',
        title: 'Untimed Goal',
        dateStr: '2026-07-24',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.goalStep, targetId: '1'),
      );

      final cycleItem = AgendaItem(
        id: 'cycle:2026-07-24',
        domain: AgendaDomain.cycle,
        sourceId: '2026-07-24',
        title: 'Cycle',
        dateStr: '2026-07-24',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.cycle, targetId: '2026-07-24'),
      );

      expect(DirectManipulationEligibility.isDraggable(movableRoutine), isTrue);
      expect(DirectManipulationEligibility.isResizable(movableRoutine), isTrue);

      expect(DirectManipulationEligibility.isDraggable(fixedPrayer), isFalse);
      expect(DirectManipulationEligibility.isResizable(fixedPrayer), isFalse);

      expect(DirectManipulationEligibility.isDraggable(allDayItem), isFalse);
      expect(DirectManipulationEligibility.isResizable(allDayItem), isFalse);

      expect(DirectManipulationEligibility.isDraggable(cycleItem), isFalse);
      expect(DirectManipulationEligibility.isResizable(cycleItem), isFalse);
    });

    test('2. TimelineSnappingHelper snaps times and durations to 15-minute intervals', () {
      // 08:07 (487 mins) -> snaps to 08:00 (480 mins)
      expect(TimelineSnappingHelper.snapStartMinutes(487), equals(480));

      // 08:09 (489 mins) -> snaps to 08:15 (495 mins)
      expect(TimelineSnappingHelper.snapStartMinutes(489), equals(495));

      // Duration < 15 mins -> snaps to min 15 mins
      expect(TimelineSnappingHelper.snapDurationMinutes(5), equals(15));
      expect(TimelineSnappingHelper.snapDurationMinutes(23), equals(30));

      // Time string conversions
      expect(TimelineSnappingHelper.minutesToTimeString(480), equals('08:00'));
      expect(TimelineSnappingHelper.minutesToTimeString(630), equals('10:30'));
      expect(TimelineSnappingHelper.parseTimeToMinutes('10:30'), equals(630));
    });

    test('3. JourneyController tracks drag and resize state correctly', () {
      final controller = JourneyController();
      final item = AgendaItem(
        id: 'routine:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Study Session',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        durationMinutes: 45,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      // Start Drag
      controller.startItemDrag(item);
      expect(controller.isDragging, isTrue);
      expect(controller.isResizing, isFalse);
      expect(controller.manipulatingItemId, equals('routine:1'));
      expect(controller.previewTimeOfDay, equals('09:00'));

      // Update Drag preview
      controller.updateDragPreview('09:15');
      expect(controller.previewTimeOfDay, equals('09:15'));

      // Start Resize
      controller.startItemResize(item);
      expect(controller.isDragging, isFalse);
      expect(controller.isResizing, isTrue);
      expect(controller.previewDurationMinutes, equals(45));

      // Update Resize preview
      controller.updateResizePreview(60);
      expect(controller.previewDurationMinutes, equals(60));

      // Cancel manipulation
      controller.cancelManipulation();
      expect(controller.isDragging, isFalse);
      expect(controller.isResizing, isFalse);
      expect(controller.manipulatingItemId, isNull);
    });
  });
}
