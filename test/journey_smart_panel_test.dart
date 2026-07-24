import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_free_gaps_section.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_summary_section.dart';

void main() {
  group('Phase 2 Now Pill & Smart Panel Tests', () {
    final sampleItem = AgendaItem(
      id: 'test:current',
      domain: AgendaDomain.routine,
      sourceId: 'c1',
      title: 'Current Workout',
      dateStr: '2026-07-24',
      timeOfDay: '10:00',
      durationMinutes: 60,
      category: Category.fitness,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'c1'),
    );

    final nextItem = AgendaItem(
      id: 'test:next',
      domain: AgendaDomain.course,
      sourceId: 'n1',
      title: 'Study Session',
      dateStr: '2026-07-24',
      timeOfDay: '14:00',
      durationMinutes: 45,
      category: Category.learning,
      deepLink: const AgendaDeepLink(domain: AgendaDomain.course, targetId: 'n1'),
    );

    test('1. NowPillViewModel returns NOW status when current activity exists', () {
      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda(dateStr: '2026-07-24', items: [sampleItem]),
        completedCount: 0,
        remainingCount: 1,
        freeGaps: const [],
        conflicts: const [],
        overloadScore: 0.1,
        currentActivity: sampleItem,
        nextActivity: null,
        suggestions: const [],
      );

      final vm = NowPillViewModel.fromSnapshot(snapshot);
      expect(vm.isVisible, isTrue);
      expect(vm.isCurrent, isTrue);
      expect(vm.statusLabel, equals('NOW'));
      expect(vm.targetItem?.title, equals('Current Workout'));
    });

    test('2. NowPillViewModel returns NEXT status when only next activity exists', () {
      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda(dateStr: '2026-07-24', items: [nextItem]),
        completedCount: 0,
        remainingCount: 1,
        freeGaps: const [],
        conflicts: const [],
        overloadScore: 0.1,
        currentActivity: null,
        nextActivity: nextItem,
        suggestions: const [],
      );

      final vm = NowPillViewModel.fromSnapshot(snapshot);
      expect(vm.isVisible, isTrue);
      expect(vm.isCurrent, isFalse);
      expect(vm.statusLabel, equals('NEXT'));
      expect(vm.targetItem?.title, equals('Study Session'));
    });

    test('3. NowPillViewModel is hidden when neither current nor next activity exists', () {
      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda.empty('2026-07-24'),
        completedCount: 0,
        remainingCount: 0,
        freeGaps: const [],
        conflicts: const [],
        overloadScore: 0.0,
        currentActivity: null,
        nextActivity: null,
        suggestions: const [],
      );

      final vm = NowPillViewModel.fromSnapshot(snapshot);
      expect(vm.isVisible, isFalse);
    });

    testWidgets('4. JourneySummarySection renders rhythm score and metrics', (tester) async {
      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda(dateStr: '2026-07-24', items: [sampleItem], rhythmScore: 85),
        completedCount: 2,
        remainingCount: 3,
        freeGaps: const [TimeGap(startMinutes: 480, endMinutes: 540)],
        conflicts: const [],
        overloadScore: 0.45,
        suggestions: const [],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneySummarySection(snapshot: snapshot),
        ),
      ));

      expect(find.text('85'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('5. JourneyFreeGapsSection renders free time gaps', (tester) async {
      final snapshot = DayAgendaSnapshot(
        dayAgenda: DayAgenda.empty('2026-07-24'),
        completedCount: 0,
        remainingCount: 0,
        freeGaps: const [TimeGap(startMinutes: 600, endMinutes: 660)], // 10:00 - 11:00
        conflicts: const [],
        overloadScore: 0.0,
        suggestions: const [],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyFreeGapsSection(snapshot: snapshot),
        ),
      ));

      expect(find.text('10:00 - 11:00'), findsOneWidget);
      expect(find.text('60 min free'), findsOneWidget);
    });
  });
}
