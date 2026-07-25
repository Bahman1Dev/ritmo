import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';

void main() {
  group('DirectManipulationEligibility tests', () {
    test('cycle, worshipDebt and prayer domains are not schedulable via drag', () {
      final cycleItem = AgendaItem(
        id: 'cycle1',
        domain: AgendaDomain.cycle,
        sourceId: 'c1',
        title: 'Cycle Item',
        dateStr: '2026-07-25',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.cycle, targetId: 'c1'),
        itemType: AgendaItemType.flexible,
      );

      final worshipDebtItem = AgendaItem(
        id: 'worshipDebt1',
        domain: AgendaDomain.worshipDebt,
        sourceId: 'wd1',
        title: 'Worship Debt',
        dateStr: '2026-07-25',
        category: Category.religious,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.worshipDebt, targetId: 'wd1'),
        itemType: AgendaItemType.flexible,
      );

      final prayerItem = AgendaItem(
        id: 'prayer1',
        domain: AgendaDomain.prayer,
        sourceId: 'p1',
        title: 'Fajr Prayer',
        dateStr: '2026-07-25',
        category: Category.religious,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.prayer, targetId: 'p1'),
        itemType: AgendaItemType.fixed,
      );

      expect(DirectManipulationEligibility.isSchedulable(cycleItem), false);
      expect(DirectManipulationEligibility.isSchedulable(worshipDebtItem), false);
      expect(DirectManipulationEligibility.isSchedulable(prayerItem), false);
    });

    test('routine, course and goalStep items are schedulable when untimed', () {
      final routineItem = AgendaItem(
        id: 'routine1',
        domain: AgendaDomain.routine,
        sourceId: 'r1',
        title: 'Read Book',
        dateStr: '2026-07-25',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r1'),
        itemType: AgendaItemType.flexible,
      );

      final courseItem = AgendaItem(
        id: 'course1',
        domain: AgendaDomain.course,
        sourceId: 'course1',
        title: 'Math Study',
        dateStr: '2026-07-25',
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: 'course1'),
        itemType: AgendaItemType.flexible,
      );

      expect(DirectManipulationEligibility.isSchedulable(routineItem), true);
      expect(DirectManipulationEligibility.isSchedulable(courseItem), true);
    });
  });
}
