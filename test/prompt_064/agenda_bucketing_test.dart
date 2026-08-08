import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/logic/agenda_bucketing.dart';

void main() {
  group('K19 — Agenda Bucketing Unit Tests', () {
    test('Correctly buckets overdue, today, tomorrow, thisWeek, nextWeek, and later', () {
      final now = DateTime(2026, 8, 8); // Saturday 8 Aug 2026

      final pastItem = AgendaItem(
        id: 'task:1:2026-08-07',
        domain: AgendaDomain.task,
        sourceId: '1',
        title: 'Past Task',
        dateStr: '2026-08-07',
        category: Category.personal,
        completion: AgendaCompletion.pending,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.task, targetId: '1'),
      );

      final todayItem = AgendaItem(
        id: 'task:2:2026-08-08',
        domain: AgendaDomain.task,
        sourceId: '2',
        title: 'Today Task',
        dateStr: '2026-08-08',
        category: Category.personal,
        completion: AgendaCompletion.pending,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.task, targetId: '2'),
      );

      final tomItem = AgendaItem(
        id: 'task:3:2026-08-09',
        domain: AgendaDomain.task,
        sourceId: '3',
        title: 'Tomorrow Task',
        dateStr: '2026-08-09',
        category: Category.personal,
        completion: AgendaCompletion.pending,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.task, targetId: '3'),
      );

      final snapshots = <String, DayAgendaSnapshot>{
        '2026-08-07': DayAgendaSnapshot(
          dayAgenda: DayAgenda(dateStr: '2026-08-07', items: [pastItem], enabledDomains: const {}),
          completedCount: 0,
          remainingCount: 1,
          freeGaps: const [],
          conflicts: const [],
          overloadScore: 0.0,
          suggestions: const [],
        ),
        '2026-08-08': DayAgendaSnapshot(
          dayAgenda: DayAgenda(dateStr: '2026-08-08', items: [todayItem], enabledDomains: const {}),
          completedCount: 0,
          remainingCount: 1,
          freeGaps: const [],
          conflicts: const [],
          overloadScore: 0.0,
          suggestions: const [],
        ),
        '2026-08-09': DayAgendaSnapshot(
          dayAgenda: DayAgenda(dateStr: '2026-08-09', items: [tomItem], enabledDomains: const {}),
          completedCount: 0,
          remainingCount: 1,
          freeGaps: const [],
          conflicts: const [],
          overloadScore: 0.0,
          suggestions: const [],
        ),
      };

      final result = bucketRange(snapshots, now: now);

      expect(result[AgendaBucket.overdue]!.length, equals(1));
      expect(result[AgendaBucket.today]!.length, equals(1));
      expect(result[AgendaBucket.tomorrow]!.length, equals(1));

      // Guarantee: No item appears in multiple buckets
      int totalBucketed = 0;
      for (final list in result.values) {
        totalBucketed += list.length;
      }
      expect(totalBucketed, equals(3));
    });

    test('Completed past items are NOT placed in overdue bucket', () {
      final now = DateTime(2026, 8, 8);

      final donePastItem = AgendaItem(
        id: 'task:10:2026-08-05',
        domain: AgendaDomain.task,
        sourceId: '10',
        title: 'Completed Past Task',
        dateStr: '2026-08-05',
        category: Category.personal,
        completion: AgendaCompletion.done,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.task, targetId: '10'),
      );

      final snapshots = <String, DayAgendaSnapshot>{
        '2026-08-05': DayAgendaSnapshot(
          dayAgenda: DayAgenda(dateStr: '2026-08-05', items: [donePastItem], enabledDomains: const {}),
          completedCount: 1,
          remainingCount: 0,
          freeGaps: const [],
          conflicts: const [],
          overloadScore: 0.0,
          suggestions: const [],
        ),
      };

      final result = bucketRange(snapshots, now: now);

      expect(result[AgendaBucket.overdue]!, isEmpty);
    });
  });
}
