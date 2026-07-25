import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';

void main() {
  test('NowPillViewModel displays summary mode for future day', () {
    final now = DateTime(2026, 7, 26, 12, 0);
    final futureDate = DateTime(2026, 8, 5);

    final futureItem = AgendaItem(
      id: 'item_future',
      sourceId: 'r_fut',
      domain: AgendaDomain.routine,
      title: 'برنامه آینده',
      dateStr: '2026-08-05',
      timeOfDay: '06:30',
    );

    final snapshot = DayAgendaSnapshot(
      dayAgenda: DayAgenda(dateStr: '2026-08-05', items: [futureItem], rhythmScore: 100),
      completedCount: 0,
      remainingCount: 1,
      freeGaps: const [],
      conflicts: const [],
      overloadScore: 0,
      nextActivity: futureItem,
      suggestions: const [],
    );

    final vm = NowPillViewModel.fromSnapshot(
      snapshot,
      now: now,
      isToday: false,
      selectedDate: futureDate,
    );

    expect(vm.isVisible, isTrue);
    expect(vm.statusLabel, equals('SUMMARY'));
    expect(vm.timeLabel, contains('۱ برنامه'));
  });
}
