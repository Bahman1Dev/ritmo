import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_details_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  final testRoutine = Routine(
    id: 'r_completed_test',
    title: 'روتین انجام شده',
    category: Category.work,
    routineType: RoutineType.timeBased,
    notificationLevel: NotificationLevel.normal,
    targetDurationMinutes: 30,
    isEssential: false,
    energyRule: EnergyRule.none,
  );

  final completedItem = AgendaItem(
    id: 'r_completed_test',
    sourceId: 'r_completed_test',
    title: 'روتین انجام شده',
    dateStr: '2026-08-04',
    timeOfDay: '10:00',
    durationMinutes: 30,
    category: Category.work,
    domain: AgendaDomain.routine,
    itemType: AgendaItemType.flexible,
    completion: AgendaCompletion.done,
    meta: {'routine': testRoutine.toMap()},
    deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r_completed_test'),
  );

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Completed Item Routing Tests', () {
    testWidgets('Completed item opens RoutineDetailsSheet and NOT RoutineNiyyahSheet', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ActionRouter.open(context, item: completedItem),
              child: const Text('Open Item'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Item'));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineDetailsSheet), findsOneWidget);
      expect(find.byType(RoutineNiyyahSheet), findsNothing);
    });
  });
}
