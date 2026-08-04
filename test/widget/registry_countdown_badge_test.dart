import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_countdown_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registry Countdown Badge Widget Tests', () {
    testWidgets('Renders floating badge when timeOfDay is null', (tester) async {
      final item = AgendaItem(
        id: 'rt_1',
        domain: AgendaDomain.routine,
        sourceId: '1',
        title: 'روتین تست',
        dateStr: '2026-08-05',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '1'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RegistryCountdownBadge(agendaItem: item),
            ),
          ),
        ),
      );

      expect(find.text('شناور'), findsOneWidget);
    });

    testWidgets('Renders countdown badge when timeOfDay is present', (tester) async {
      final item = AgendaItem(
        id: 'rt_2',
        domain: AgendaDomain.routine,
        sourceId: '2',
        title: 'روتین با زمان',
        dateStr: '2026-08-05',
        timeOfDay: '23:59',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '2'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RegistryCountdownBadge(agendaItem: item),
            ),
          ),
        ),
      );

      // Should show a countdown text (not "شناور")
      expect(find.text('شناور'), findsNothing);
      expect(find.byType(RegistryCountdownBadge), findsOneWidget);
    });

    testWidgets('Badge has no gradient decorations (simplified)', (tester) async {
      final item = AgendaItem(
        id: 'rt_3',
        domain: AgendaDomain.routine,
        sourceId: '3',
        title: 'تست ساده',
        dateStr: '2026-08-05',
        timeOfDay: '14:00',
        category: Category.personal,
        deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: '3'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RegistryCountdownBadge(agendaItem: item),
            ),
          ),
        ),
      );

      // Verify no BoxShadow or LinearGradient in the widget tree
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.gradient, isNull);
      expect(decoration?.boxShadow, isNull);
    });
  });
}
