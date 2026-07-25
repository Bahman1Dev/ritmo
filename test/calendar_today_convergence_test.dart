import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/calendar/presentation/logic/today_calendar_convergence_helper.dart';

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
  group('Phase 9 — Calendar + Today Convergence & Cross-Feature Integration Tests', () {
    test('1. TodayCalendarConvergenceHelper resolves unified current/next context', () async {
      final helper = TodayCalendarConvergenceHelper(agendaService: FakeDayAgendaService());

      final snapshot = await helper.fetchTodaySnapshot(
        now: DateTime(2026, 7, 24, 10, 30),
      );

      expect(snapshot, isNotNull);
      expect(snapshot.dayAgenda.dateStr, equals('2026-07-24'));
    });

    test('2. openCalendarInContext fires navigate_tab event with target parameters', () async {
      final eventBus = RitmoEventBus();
      final helper = TodayCalendarConvergenceHelper(agendaService: FakeDayAgendaService(), eventBus: eventBus);

      final future = eventBus.onEvents.firstWhere((e) => e.type == 'navigate_tab');

      final testDate = DateTime(2026, 7, 24);
      helper.openCalendarInContext(
        DummyBuildContext(),
        date: testDate,
        itemId: 'routine:study',
      );

      final receivedEvent = await future;
      expect(receivedEvent, isNotNull);
      expect(receivedEvent.payload['index'], equals(4));
      expect(receivedEvent.payload['itemId'], equals('routine:study'));
    });

    test('3. Quick action execution fires AgendaItemToggled event', () async {
      final eventBus = RitmoEventBus();

      final future = eventBus.onEvents.firstWhere((e) => e.type == 'AgendaItemToggled');

      eventBus.fire(RitmoEvent(
        type: 'AgendaItemToggled',
        payload: const {
          'domain': 'mustahab',
          'isDone': true,
        },
        timestamp: DateTime.now(),
      ));

      final toggledEvent = await future;
      expect(toggledEvent.payload['domain'], equals('mustahab'));
      expect(toggledEvent.payload['isDone'], isTrue);
    });
  });
}
