import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';

void main() {
  test('NowPillViewModel marks overdue item correctly', () {
    final now = DateTime(2026, 7, 26, 12, 30);

    final overdueItem = AgendaItem(
      id: 'item_overdue',
      sourceId: 'r_overdue',
      domain: AgendaDomain.routine,
      title: 'تمرین عقب‌افتاده',
      dateStr: '2026-07-26',
      timeOfDay: '12:00',
      isCompleted: false,
    );

    final snapshot = DayAgendaSnapshot(
      dayAgenda: DayAgenda(dateStr: '2026-07-26', items: [overdueItem], rhythmScore: 100),
      completedCount: 0,
      remainingCount: 1,
      freeGaps: const [],
      conflicts: const [],
      overloadScore: 0,
      nextActivity: overdueItem,
      suggestions: const [],
    );

    final vm = NowPillViewModel.fromSnapshot(
      snapshot,
      now: now,
      isToday: true,
    );

    expect(vm.isVisible, isTrue);
    expect(vm.isOverdue, isTrue);
    expect(vm.timeLabel, equals('۳۰ دقیقه پیش'));
  });
}
