import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/models/timeline_view_models.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_date_formatter.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_navigation_helper.dart';

void main() {
  group('Calendar Support Track - Domain Coverage & Utilities Tests', () {
    test('1. AgendaQueryOptions worship debt default exclusion & domain filtering', () {
      const defaultOpts = AgendaQueryOptions();
      expect(defaultOpts.includeWorshipDebt, isFalse);
      expect(defaultOpts.wants(AgendaDomain.worshipDebt), isFalse);

      expect(defaultOpts.wants(AgendaDomain.routine), isTrue);
      expect(defaultOpts.wants(AgendaDomain.prayer), isTrue);
      expect(defaultOpts.wants(AgendaDomain.mustahab), isTrue);
      expect(defaultOpts.wants(AgendaDomain.course), isTrue);
      expect(defaultOpts.wants(AgendaDomain.goalStep), isTrue);
      expect(defaultOpts.wants(AgendaDomain.konkur), isTrue);
      expect(defaultOpts.wants(AgendaDomain.cycle), isTrue);
      expect(defaultOpts.wants(AgendaDomain.sport), isTrue);
      expect(defaultOpts.wants(AgendaDomain.medicine), isTrue);

      const explicitOpts = AgendaQueryOptions(
        includeWorshipDebt: true,
        domains: {AgendaDomain.sport, AgendaDomain.medicine},
      );
      expect(explicitOpts.wants(AgendaDomain.sport), isTrue);
      expect(explicitOpts.wants(AgendaDomain.medicine), isTrue);
      expect(explicitOpts.wants(AgendaDomain.routine), isFalse);
    });

    test('2. SleepWindowResolver handles nulls, same-day, and overnight windows', () {
      const resolver = SleepWindowResolver();

      // Missing data -> null
      expect(resolver.resolveFromTimes(bedtime: null, wakeTime: '07:00'), isNull);
      expect(resolver.resolveFromTimes(bedtime: 'invalid', wakeTime: '07:00'), isNull);

      // Same-day window (e.g. 01:00 to 07:00)
      final sameDay = resolver.resolveFromTimes(bedtime: '01:00', wakeTime: '07:00');
      expect(sameDay, isNotNull);
      expect(sameDay!.crossesMidnight, isFalse);
      expect(sameDay.startMinutes, equals(60));
      expect(sameDay.endMinutes, equals(420));
      expect(sameDay.durationMinutes, equals(360));

      // Overnight window (e.g. 23:30 to 07:00)
      final overnight = resolver.resolveFromTimes(
        bedtime: '23:30',
        wakeTime: '07:00',
        label: 'خواب شبانه',
      );
      expect(overnight, isNotNull);
      expect(overnight!.crossesMidnight, isTrue);
      expect(overnight.startMinutes, equals(1410)); // 23 * 60 + 30
      expect(overnight.endMinutes, equals(1860)); // 7 * 60 + 1440
      expect(overnight.durationMinutes, equals(450)); // 7.5 hours
      expect(overnight.label, equals('خواب شبانه'));

      // From settings disabled -> null
      final disabledBlock = resolver.resolveFromSettings({'module_sleep_enabled': 'false'});
      expect(disabledBlock, isNull);

      // From settings enabled -> block
      final enabledBlock = resolver.resolveFromSettings({
        'module_sleep_enabled': 'true',
        'sleep_target_bedtime': '23:00',
        'sleep_target_wake': '06:30',
      });
      expect(enabledBlock, isNotNull);
      expect(enabledBlock!.startMinutes, equals(1380));
      expect(enabledBlock.crossesMidnight, isTrue);
    });

    test('3. CalendarDateFormatter relative labeling and Persian digit formatting', () {
      final now = DateTime(2026, 7, 24);
      final today = DateTime(2026, 7, 24);
      final yesterday = DateTime(2026, 7, 23);
      final tomorrow = DateTime(2026, 7, 25);
      final other = DateTime(2026, 7, 28);

      expect(CalendarDateFormatter.getDayRelativeLabel(today, relativeTo: now), equals('امروز'));
      expect(CalendarDateFormatter.getDayRelativeLabel(yesterday, relativeTo: now), equals('دیروز'));
      expect(CalendarDateFormatter.getDayRelativeLabel(tomorrow, relativeTo: now), equals('فردا'));
      expect(CalendarDateFormatter.getDayRelativeLabel(other, relativeTo: now), isNull);

      final title = CalendarDateFormatter.formatSelectedDateTitle(today, relativeTo: now);
      expect(title.contains('امروز'), isTrue);

      final hourLabel = CalendarDateFormatter.formatHourLabel(8, usePersianDigits: true);
      expect(hourLabel, equals('۰۸:۰۰'));
    });

    test('4. CalendarNavigationHelper date math and scroll anchor calculations', () {
      final date = DateTime(2026, 7, 24);
      expect(CalendarNavigationHelper.previousDay(date), equals(DateTime(2026, 7, 23)));
      expect(CalendarNavigationHelper.nextDay(date), equals(DateTime(2026, 7, 25)));
      expect(CalendarNavigationHelper.isToday(date, now: DateTime(2026, 7, 24)), isTrue);
      expect(CalendarNavigationHelper.isToday(date, now: DateTime(2026, 7, 25)), isFalse);

      // Today at 10:00 AM (600 minutes) -> anchor 60 minutes prior (540 mins) -> 540 * 1.2 = 648.0 px
      final now10AM = DateTime(2026, 7, 24, 10, 0);
      final offset = CalendarNavigationHelper.calculateInitialScrollOffset(
        date: date,
        now: now10AM,
        pxPerMinute: 1.2,
      );
      expect(offset, equals(648.0));

      // Non-today date -> defaults to waking hour 7 AM (420 mins) -> 420 * 1.2 = 504.0 px
      final nonTodayOffset = CalendarNavigationHelper.calculateInitialScrollOffset(
        date: DateTime(2026, 7, 25),
        now: now10AM,
        wakingHour: 7,
        pxPerMinute: 1.2,
      );
      expect(nonTodayOffset, equals(504.0));
    });

    test('5. DayAgendaSnapshotBuilder hardened current/next activity resolution', () {
      const builder = DayAgendaSnapshotBuilder();
      final now1030 = DateTime(2026, 7, 24, 10, 30); // 630 mins

      final itemCurrent = AgendaItem(
        id: 'test:current',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Morning Meeting',
        dateStr: '2026-07-24',
        timeOfDay: '10:00', // 600 to 660 mins
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final itemDoneNext = AgendaItem(
        id: 'test:done_next',
        domain: AgendaDomain.course,
        sourceId: '2',
        title: 'Finished Lesson',
        dateStr: '2026-07-24',
        timeOfDay: '11:00', // 660 mins
        durationMinutes: 30,
        completion: AgendaCompletion.done,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: '2'),
      );

      final itemPendingNext = AgendaItem(
        id: 'test:pending_next',
        domain: AgendaDomain.sport,
        sourceId: '3',
        title: 'Gym Session',
        dateStr: '2026-07-24',
        timeOfDay: '12:00', // 720 mins
        durationMinutes: 45,
        completion: AgendaCompletion.pending,
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.sport, targetId: '3'),
      );

      // Purposefully pass in reverse order to verify sorting logic
      final dayAgenda = DayAgenda(
        dateStr: '2026-07-24',
        items: [itemPendingNext, itemDoneNext, itemCurrent],
      );

      const sleepBlock = SleepWindowBlock(
        startMinutes: 1410,
        endMinutes: 1860,
        crossesMidnight: true,
      );

      final snapshot = builder.buildSnapshot(
        dayAgenda,
        now: now1030,
        sleepWindow: sleepBlock,
      );

      expect(snapshot.currentActivity?.id, equals('test:current'));
      expect(snapshot.nextActivity?.id, equals('test:pending_next'));
      expect(snapshot.sleepWindow, equals(sleepBlock));
    });

    test('6. DailyTimelineViewModel separates timed vs untimed items', () {
      final timed = AgendaItem(
        id: 'test:timed',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Timed Routine',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        category: Category.custom,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final untimed = AgendaItem(
        id: 'test:untimed',
        domain: AgendaDomain.goalStep,
        sourceId: '2',
        title: 'Untimed Goal Step',
        dateStr: '2026-07-24',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.goalStep, targetId: '2'),
      );

      final agenda = DayAgenda(dateStr: '2026-07-24', items: [timed, untimed]);
      final vm = DailyTimelineViewModel.fromAgenda(agenda, now: DateTime(2026, 7, 24, 9, 30));

      expect(vm.hasTimedItems, isTrue);
      expect(vm.hasUntimedItems, isTrue);
      expect(vm.timedItems.length, equals(1));
      expect(vm.untimedItems.length, equals(1));
      expect(vm.currentTimeMinutes, equals(570));
    });
  });
}
