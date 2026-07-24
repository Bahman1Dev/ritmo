import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_overload_detector.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  group('Calendar Foundation & Domain Contract Tests', () {
    test('1. AgendaItemType and derived timing getters behave as expected', () {
      final timedItem = AgendaItem(
        id: 'test:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Morning Exercise',
        dateStr: '2026-07-24',
        timeOfDay: '08:00',
        durationMinutes: 45,
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      expect(timedItem.isTimed, isTrue);
      expect(timedItem.isAllDay, isFalse);
      expect(timedItem.isFixed, isTrue);
      expect(timedItem.isOvernight, isFalse);

      final untimedItem = AgendaItem(
        id: 'test:2',
        domain: AgendaDomain.sport,
        sourceId: '2',
        title: 'Walk in park',
        dateStr: '2026-07-24',
        category: Category.fitness,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.sport, targetId: '2'),
      );

      expect(untimedItem.isTimed, isFalse);
      expect(untimedItem.isAllDay, isTrue);
      expect(untimedItem.isFlexible, isTrue);

      final overnightItem = AgendaItem(
        id: 'test:3',
        domain: AgendaDomain.routine,
        sourceId: '3',
        title: 'Night Shift',
        dateStr: '2026-07-24',
        timeOfDay: '23:30',
        durationMinutes: 120,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '3'),
      );

      expect(overnightItem.isOvernight, isTrue);
    });

    test('2. AgendaConflictDetector finds overlaps and same-start conflicts', () {
      const detector = AgendaConflictDetector();

      final itemA = AgendaItem(
        id: 'test:A',
        domain: AgendaDomain.routine,
        sourceId: 'A',
        title: 'Task A',
        dateStr: '2026-07-24',
        timeOfDay: '10:00',
        durationMinutes: 60,
        category: Category.work,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'A'),
      );

      final itemB = AgendaItem(
        id: 'test:B',
        domain: AgendaDomain.course,
        sourceId: 'B',
        title: 'Task B',
        dateStr: '2026-07-24',
        timeOfDay: '10:00',
        durationMinutes: 30,
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: 'B'),
      );

      final conflicts = detector.detectConflicts([itemA, itemB]);
      expect(conflicts.length, equals(1));
      expect(conflicts.first.type, equals(ConflictType.sameStart));
    });

    test('3. AgendaGapCalculator computes free slots within waking hours', () {
      const calculator = AgendaGapCalculator(wakingStartMinutes: 480, wakingEndMinutes: 720); // 08:00 to 12:00

      final item = AgendaItem(
        id: 'test:1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'Study',
        dateStr: '2026-07-24',
        timeOfDay: '09:00',
        durationMinutes: 60, // 09:00 to 10:00
        category: Category.learning,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      final gaps = calculator.calculateFreeGaps([item]);
      expect(gaps.length, equals(2));
      expect(gaps[0].startTimeStr, equals('08:00'));
      expect(gaps[0].endTimeStr, equals('09:00'));
      expect(gaps[1].startTimeStr, equals('10:00'));
      expect(gaps[1].endTimeStr, equals('12:00'));
    });

    test('4. AgendaOverloadDetector computes score correctly', () {
      const detector = AgendaOverloadDetector(wakingWindowMinutes: 600); // 10 hours

      final items = [
        AgendaItem(
          id: 'test:1',
          domain: AgendaDomain.routine,
          sourceId: '1',
          title: 'Heavy Routine',
          dateStr: '2026-07-24',
          timeOfDay: '08:00',
          durationMinutes: 300,
          category: Category.work,
          deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
        ),
      ];

      final score = detector.calculateOverloadScore(items);
      expect(score, equals(0.5));
    });

    test('5. DayAgendaSnapshotBuilder composes derived snapshot', () {
      const builder = DayAgendaSnapshotBuilder();

      final dayAgenda = DayAgenda(
        dateStr: '2026-07-24',
        items: [
          AgendaItem(
            id: 'test:1',
            domain: AgendaDomain.medicine,
            sourceId: '1',
            title: 'Vitamin D',
            dateStr: '2026-07-24',
            category: Category.medical,
            deepLink: const AgendaDeepLink(domain: AgendaDomain.medicine, targetId: '1'),
          ),
        ],
      );

      final snapshot = builder.buildSnapshot(dayAgenda);
      expect(snapshot.remainingCount, equals(1));
      expect(snapshot.completedCount, equals(0));
      expect(snapshot.dayAgenda.items.first.domain, equals(AgendaDomain.medicine));
    });

    test('6. Worship debt policy flag excludes worship debt by default', () {
      const defaultOptions = AgendaQueryOptions();
      expect(defaultOptions.wants(AgendaDomain.worshipDebt), isFalse);

      const explicitOptions = AgendaQueryOptions(includeWorshipDebt: true);
      expect(explicitOptions.wants(AgendaDomain.worshipDebt), isTrue);
    });
  });
}
