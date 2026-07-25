import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

void main() {
  test('Item 11:30–12:30 appears in both morning and afternoon columns with correct clipping flags', () {
    final item = AgendaItem(
      id: 'test_cross_boundary',
      domain: AgendaDomain.routine,
      sourceId: 'routine_1',
      title: 'Cross Boundary Meeting',
      dateStr: '2026-07-25',
      timeOfDay: '11:30',
      durationMinutes: 60,
      category: Category.work,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'routine_1'),
      itemType: AgendaItemType.fixed,
    );

    // Morning Engine (0..720)
    const morningEngine = TimelineLayoutEngine(
      rangeStartMinutes: 0,
      rangeEndMinutes: 720,
      pxPerMinute: 1.0,
    );
    final morningLayout = morningEngine.calculateLayout([item]);

    expect(morningLayout.length, 1);
    final morningItem = morningLayout.first;
    expect(morningItem.startMinutes, 690);
    expect(morningItem.durationMinutes, 60);
    expect(morningItem.isClippedAtStart, false);
    expect(morningItem.isClippedAtEnd, true);

    // Afternoon Engine (720..1440)
    const afternoonEngine = TimelineLayoutEngine(
      rangeStartMinutes: 720,
      rangeEndMinutes: 1440,
      pxPerMinute: 1.0,
    );
    final afternoonLayout = afternoonEngine.calculateLayout([item]);

    expect(afternoonLayout.length, 1);
    final afternoonItem = afternoonLayout.first;
    expect(afternoonItem.startMinutes, 690);
    expect(afternoonItem.durationMinutes, 60);
    expect(afternoonItem.isClippedAtStart, true);
    expect(afternoonItem.isClippedAtEnd, false);
  });
}
