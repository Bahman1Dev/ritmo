import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

void main() {
  group('TimelineLayoutEngine Max Height & Truncation Tests', () {
    test('Items longer than 240 mins get truncated visual height (maxRenderMinutes)', () {
      final engine = const TimelineLayoutEngine(pxPerMinute: 1.2);
      final item = AgendaItem(
        id: 'routine:long_sleep',
        domain: AgendaDomain.routine,
        sourceId: 'long_sleep',
        title: 'خواب بلند',
        dateStr: '2026-07-25',
        timeOfDay: '00:00',
        durationMinutes: 480, // 8 hours real duration
        category: Category.personal,
      );

      final layout = engine.calculateLayout([item]);
      expect(layout.length, 1);

      final layoutItem = layout.first;
      expect(layoutItem.durationMinutes, 480);
      expect(layoutItem.renderDurationMinutes, DurationBounds.maxRenderMinutes);
      expect(layoutItem.isTruncated, isTrue);
      expect(layoutItem.height, closeTo(DurationBounds.maxRenderMinutes * 1.2, 0.1));
    });
  });
}
