import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

void main() {
  test('4 overlapping items with maxLanes=2 creates 1 main item card and 1 overflow item card with overflowCount == 3', () {
    final items = [
      AgendaItem(
        id: 'item1',
        domain: AgendaDomain.routine,
        sourceId: 's1',
        title: 'Item 1',
        dateStr: '2026-07-25',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 's1'),
        itemType: AgendaItemType.fixed,
      ),
      AgendaItem(
        id: 'item2',
        domain: AgendaDomain.routine,
        sourceId: 's2',
        title: 'Item 2',
        dateStr: '2026-07-25',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 's2'),
        itemType: AgendaItemType.fixed,
      ),
      AgendaItem(
        id: 'item3',
        domain: AgendaDomain.routine,
        sourceId: 's3',
        title: 'Item 3',
        dateStr: '2026-07-25',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 's3'),
        itemType: AgendaItemType.fixed,
      ),
      AgendaItem(
        id: 'item4',
        domain: AgendaDomain.routine,
        sourceId: 's4',
        title: 'Item 4',
        dateStr: '2026-07-25',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 's4'),
        itemType: AgendaItemType.fixed,
      ),
    ];

    const engine = TimelineLayoutEngine(
      rangeStartMinutes: 0,
      rangeEndMinutes: 720,
      maxLanes: 2,
    );

    final layout = engine.calculateLayout(items);

    expect(layout.length, 2);
    expect(layout[0].overflowCount, 0);
    expect(layout[1].overflowCount, 3);
    expect(layout[1].overflowItems.length, 3);
  });
}
