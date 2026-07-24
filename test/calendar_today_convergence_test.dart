import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/logic/today_calendar_convergence_helper.dart';

void main() {
  group('Phase 9 — Calendar + Today Convergence & Cross-Feature Integration Tests', () {
    test('1. TodayCalendarConvergenceHelper resolves unified current/next context', () async {
      final helper = TodayCalendarConvergenceHelper();

      final snapshot = await helper.fetchTodaySnapshot(
        now: DateTime(2026, 7, 24, 10, 30),
      );

      expect(snapshot, isNotNull);
      expect(snapshot.dayAgenda.dateStr, equals('2026-07-24'));
    });

    testWidgets('2. openCalendarInContext fires navigate_tab event with target parameters', (tester) async {
      final eventBus = RitmoEventBus();
      final helper = TodayCalendarConvergenceHelper(eventBus: eventBus);

      RitmoEvent? receivedEvent;
      final sub = eventBus.onEvents.listen((event) {
        if (event.type == 'navigate_tab') {
          receivedEvent = event;
        }
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final testDate = DateTime(2026, 7, 24);
              helper.openCalendarInContext(
                context,
                date: testDate,
                itemId: 'routine:study',
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.payload['index'], equals(4));
      expect(receivedEvent!.payload['itemId'], equals('routine:study'));

      await sub.cancel();
    });

    test('3. Quick action execution via AgendaActionHandler fires AgendaItemToggled event', () async {
      final eventBus = RitmoEventBus();

      final item = AgendaItem(
        id: 'mustahab:1',
        domain: AgendaDomain.mustahab,
        sourceId: '1',
        title: 'زیارت عاشورا',
        dateStr: '2026-07-24',
        timeOfDay: '07:00',
        category: Category.religious,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.mustahab, targetId: '1'),
      );

      RitmoEvent? toggledEvent;
      final sub = eventBus.onEvents.listen((event) {
        if (event.type == 'AgendaItemToggled') {
          toggledEvent = event;
        }
      });

      // Complete item via AgendaActionHandler
      await AgendaActionHandler.instance.toggleAgendaItem(item: item, isDone: true);

      expect(toggledEvent, isNotNull);
      expect(toggledEvent!.payload['domain'], equals('mustahab'));
      expect(toggledEvent!.payload['isDone'], isTrue);

      await sub.cancel();
    });
  });
}
