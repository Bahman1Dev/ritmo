import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';

void main() {
  test('NowPillViewModel handles 23:30 to 05:00 tomorrow without negative diff', () {
    final now = DateTime(2026, 7, 26, 23, 30);
    final tomorrowItem = AgendaItem(
      id: 'item_tomorrow',
      sourceId: 'r_tom',
      domain: AgendaDomain.routine,
      title: 'نماز صبح',
      dateStr: '2026-07-27',
      timeOfDay: '05:00',
      category: Category.religious,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r_tom'),
    );

    final snapshot = DayAgendaSnapshot(
      dayAgenda: DayAgenda(dateStr: '2026-07-26', items: [tomorrowItem], rhythmScore: 100),
      completedCount: 0,
      remainingCount: 1,
      freeGaps: const [],
      conflicts: const [],
      overloadScore: 0,
      nextActivity: tomorrowItem,
      suggestions: const [],
    );

    final vm = NowPillViewModel.fromSnapshot(snapshot, now: now, isToday: true);

    expect(vm.isVisible, isTrue);
    expect(vm.isCurrent, isFalse);
    expect(vm.timeLabel, equals('فردا ساعت ۰۵:۰۰'));
  });
}
