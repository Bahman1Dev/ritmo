import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  final testRoutine = Routine(
    id: 'r_refresh_test',
    title: 'تست رفرش تقویم',
    category: RoutineCategory.WORK,
    routineType: RoutineType.ROUTINE,
    notificationLevel: NotificationLevel.MEDIUM,
    targetDurationMinutes: 30,
    displayOrder: 1,
    createdAt: 1000,
    updatedAt: 1000,
  );

  final agendaItem = AgendaItem(
    id: 'r_refresh_test',
    sourceId: 'r_refresh_test',
    title: 'تست رفرش تقویم',
    dateStr: '2026-08-04',
    timeOfDay: '10:00',
    durationMinutes: 30,
    domain: AgendaDomain.routine,
    itemType: AgendaItemType.flexible,
    meta: {'routine': testRoutine.toMap()},
    deepLink: const AgendaDeepLink(domain: AgendaDomain.routine, targetId: 'r_refresh_test'),
  );

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: RitmoTheme(
          child: child,
        ),
      ),
    );
  }

  group('Calendar Refresh After Action Tests', () {
    testWidgets('ActionRouter.open calls onChanged callback when action executes', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ActionRouter.open(
                context,
                item: agendaItem,
                onChanged: () => refreshed = true,
              ),
              child: const Text('Open Niyyah'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Niyyah'));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineNiyyahSheet), findsOneWidget);

      await tester.tap(find.text('ثبت فوری بدون تایمر'));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });
  });
}
