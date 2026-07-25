import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';

void main() {
  test('NowPillViewModel displays review mode for past day', () {
    final now = DateTime(2026, 7, 26, 12, 0);
    final pastDate = DateTime(2026, 7, 20);

    final pastItem = AgendaItem(
      id: 'item_past',
      sourceId: 'r_past',
      domain: AgendaDomain.routine,
      title: 'برنامه گذشته',
      dateStr: '2026-07-20',
      timeOfDay: '08:00',
    );

    final snapshot = DayAgendaSnapshot(
      dayAgenda: DayAgenda(dateStr: '2026-07-20', items: [pastItem], rhythmScore: 100),
      completedCount: 1,
      remainingCount: 0,
      freeGaps: const [],
      conflicts: const [],
      overloadScore: 0,
      suggestions: const [],
    );

    final vm = NowPillViewModel.fromSnapshot(
      snapshot,
      now: now,
      isToday: false,
      selectedDate: pastDate,
    );

    expect(vm.isVisible, isTrue);
    expect(vm.statusLabel, equals('REVIEW'));
    expect(vm.timeLabel, equals('۱ از ۱ انجام شد'));
  });
}
