import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/features/calendar/presentation/logic/today_calendar_convergence_helper.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_date_formatter.dart';

class DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDayAgendaService implements DayAgendaService {
  @override
  Future<DayAgenda> agendaForDate(DateTime date, {AgendaQueryOptions? options}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return DayAgenda(dateStr: dateStr, items: []);
  }

  @override
  Future<Map<String, DayAgenda>> agendaForRange(DateTime start, DateTime end, {AgendaQueryOptions? options}) async {
    final map = <String, DayAgenda>{};
    var current = start;
    while (!current.isAfter(end)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      map[key] = DayAgenda(dateStr: key, items: []);
      current = current.add(const Duration(days: 1));
    }
    return map;
  }

  @override
  void invalidateDate(String dateStr) {}

  @override
  void invalidateAll() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 10 — Release Candidate Closure & Production Readiness Tests', () {
    test('1. Navigation & Period Offset Math is consistent across scales', () {
      final controller = JourneyController(agendaService: FakeDayAgendaService());
      final baseDate = DateTime(2026, 7, 24);
      controller.selectDate(baseDate, scaleToSet: JourneyScale.day);

      // Navigate Day (+1)
      controller.navigatePeriod(1);
      expect(controller.selectedDate, equals(DateTime(2026, 7, 25)));

      // Switch to Week and Navigate (+1 week)
      controller.setScale(JourneyScale.week);
      controller.navigatePeriod(1);
      expect(controller.selectedDate, equals(DateTime(2026, 8, 1)));

      // Switch to Month and Navigate (+1 month)
      controller.setScale(JourneyScale.month);
      controller.navigatePeriod(1);
      expect(controller.selectedDate.month, equals(9));

      controller.dispose();
    });

    test('2. Calendar Date Formatter converts dates to Shamsi Persian titles cleanly', () {
      final date = DateTime(2026, 7, 24); // 3 Mordad 1405
      final title = CalendarDateFormatter.formatSelectedDateTitle(date, includeYear: true);

      expect(title, contains('مرداد'));
      expect(title, contains('۱۴۰۵'));
    });

    test('3. Open-in-Context deep-linking resolves target dates and items safely', () async {
      final eventBus = RitmoEventBus();
      final helper = TodayCalendarConvergenceHelper(agendaService: FakeDayAgendaService(), eventBus: eventBus);

      final future = eventBus.onEvents.firstWhere((e) => e.type == 'navigate_tab');

      helper.openCalendarInContext(
        DummyBuildContext(),
        date: DateTime(2026, 7, 24),
        itemId: 'routine:exercise',
      );

      final capturedEvent = await future;
      expect(capturedEvent, isNotNull);
      expect(capturedEvent.payload['index'], equals(4));
      expect(capturedEvent.payload['itemId'], equals('routine:exercise'));
    });

    test('4. Full Snapshot Pipeline remains resilient under sparse and dense inputs', () {
      const builder = DayAgendaSnapshotBuilder();

      final denseItems = List.generate(
        12,
        (index) => AgendaItem(
          id: 'routine:$index',
          domain: AgendaDomain.routine,
          sourceId: '$index',
          title: 'Routine Item $index',
          dateStr: '2026-07-24',
          timeOfDay: '${(8 + (index ~/ 2)).toString().padLeft(2, '0')}:${(index % 2 == 0 ? '00' : '30')}',
          durationMinutes: 30,
          category: Category.personal,
          deepLink: AgendaDeepLink(domain: AgendaDomain.routine, targetId: '$index'),
        ),
      );

      final snapshot = builder.buildSnapshot(
        DayAgenda(dateStr: '2026-07-24', items: denseItems),
        now: DateTime(2026, 7, 24, 10, 15),
      );

      expect(snapshot.items.length, equals(12));
      expect(snapshot.overloadScore, greaterThan(0.0));
      expect(snapshot.currentActivity, isNotNull);
      expect(snapshot.currentActivity!.id, equals('routine:4')); // 10:00 - 10:30
    });

    test('5. Direct Manipulation eligibility and snapping helper enforce domain safety', () {
      final movable = AgendaItem(
        id: 'sport:1',
        domain: AgendaDomain.sport,
        sourceId: '1',
        title: 'Workout',
        dateStr: '2026-07-24',
        timeOfDay: '17:00',
        durationMinutes: 60,
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.sport, targetId: '1'),
      );

      final unmovablePrayer = AgendaItem(
        id: 'prayer:maghrib',
        domain: AgendaDomain.prayer,
        sourceId: 'maghrib',
        title: 'نماز مغرب',
        dateStr: '2026-07-24',
        timeOfDay: '19:30',
        category: Category.religious,
        itemType: AgendaItemType.fixed,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.prayer, targetId: 'maghrib'),
      );

      expect(DirectManipulationEligibility.isDraggable(movable), isTrue);
      expect(DirectManipulationEligibility.isResizable(movable), isTrue);

      expect(DirectManipulationEligibility.isDraggable(unmovablePrayer), isFalse);
      expect(DirectManipulationEligibility.isResizable(unmovablePrayer), isFalse);
    });
  });
}
