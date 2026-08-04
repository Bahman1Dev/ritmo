import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  final testRoutine = Routine(
    id: 'r_edit_stay_test',
    title: 'ویرایش روتین ماندگار',
    category: Category.work,
    routineType: RoutineType.timeBased,
    notificationLevel: NotificationLevel.normal,
    targetDurationMinutes: 30,
    isEssential: false,
    energyRule: EnergyRule.none,
  );

  final agendaItem = AgendaItem(
    id: 'r_edit_stay_test',
    sourceId: 'r_edit_stay_test',
    title: 'ویرایش روتین ماندگار',
    dateStr: '2026-08-04',
    timeOfDay: '10:00',
    durationMinutes: 30,
    category: Category.work,
    domain: AgendaDomain.routine,
    itemType: AgendaItemType.flexible,
    meta: {'routine': testRoutine.toMap()},
    deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r_edit_stay_test'),
  );

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: RitmoTheme.lightTheme,
      darkTheme: RitmoTheme.darkTheme,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Niyyah Edit Sheet Stays Open Tests (Main Bug Guard Test)', () {
    testWidgets('Tapping Edit opens UniversalPlannerSheet and keeps it open on Navigator stack', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Suppress expected overflow exceptions from planner date picker in constrained test environment
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('overflowed') || details.toString().contains('databaseFactory')) {
          return; // suppress known test-environment-only issues
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ActionRouter.open(context, item: agendaItem),
              child: const Text('Open Niyyah'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Niyyah'));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineNiyyahSheet), findsOneWidget);

      await tester.tap(find.text('ویرایش'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      // Verify that RoutineNiyyahSheet closed AND UniversalPlannerSheet is OPEN on the stack!
      expect(find.byType(RoutineNiyyahSheet), findsNothing);
      expect(find.byType(UniversalPlannerSheet), findsOneWidget);
    });
  });
}
