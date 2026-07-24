import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_untimed_section.dart';

void main() {
  group('Timeline Layout Engine & MVP Component Tests', () {
    test('1. Overlapping items produce multiple lanes side by side', () {
      const engine = TimelineLayoutEngine(pxPerMinute: 1.0);

      final item1 = AgendaItem(
        id: 'test:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Meeting 1',
        dateStr: '2026-07-24',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final item2 = AgendaItem(
        id: 'test:2',
        domain: AgendaDomain.course,
        sourceId: '2',
        title: 'Meeting 2',
        dateStr: '2026-07-24',
        timeOfDay: '10:30',
        durationMinutes: 60,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: '2'),
      );

      final layout = engine.calculateLayout([item1, item2]);
      expect(layout.length, equals(2));
      expect(layout[0].totalLanes, equals(2));
      expect(layout[1].totalLanes, equals(2));
      expect(layout[0].laneIndex, isNot(equals(layout[1].laneIndex)));
    });

    test('2. Same start items share width correctly', () {
      const engine = TimelineLayoutEngine(pxPerMinute: 1.0);

      final item1 = AgendaItem(
        id: 'test:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Routine 1',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        durationMinutes: 30,
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final item2 = AgendaItem(
        id: 'test:2',
        domain: AgendaDomain.sport,
        sourceId: '2',
        title: 'Routine 2',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        durationMinutes: 30,
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.sport, targetId: '2'),
      );

      final layout = engine.calculateLayout([item1, item2]);
      expect(layout.length, equals(2));
      expect(layout[0].widthFraction, equals(0.5));
      expect(layout[1].widthFraction, equals(0.5));
    });

    test('3. Zero duration items get minimum visible height', () {
      const engine = TimelineLayoutEngine(pxPerMinute: 1.0, minItemHeight: 28.0);

      final item = AgendaItem(
        id: 'test:0',
        domain: AgendaDomain.routine,
        sourceId: '0',
        title: 'Quick Check-in',
        dateStr: '2026-07-24',
        timeOfDay: '12:00',
        durationMinutes: 0,
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '0'),
      );

      final layout = engine.calculateLayout([item]);
      expect(layout.length, equals(1));
      expect(layout.first.height, greaterThanOrEqualTo(28.0));
    });

    testWidgets('4. TimelineUntimedSection renders untimed tasks', (tester) async {
      final untimedItem = AgendaItem(
        id: 'test:untimed',
        domain: AgendaDomain.sport,
        sourceId: 'u1',
        title: 'Drink 2L Water',
        dateStr: '2026-07-24',
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.sport, targetId: 'u1'),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TimelineUntimedSection(untimedItems: [untimedItem]),
        ),
      ));

      expect(find.text('Drink 2L Water'), findsOneWidget);
    });
  });
}
