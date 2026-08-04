import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  final testRoutine = Routine(
    id: 'r_niyyah_test',
    title: 'تست نیت انجام',
    category: Category.work,
    routineType: RoutineType.timeBased,
    notificationLevel: NotificationLevel.normal,
    targetDurationMinutes: 30,
    lightDurationMinutes: 20,
    minimalDurationMinutes: 10,
    isEssential: false,
    energyRule: EnergyRule.none,
  );

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('RoutineNiyyahSheet Intent Return Tests (Section 5)', () {
    testWidgets('Tapping Start Focus Timer pops NiyyahIntent.startTimer', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      NiyyahIntent? resultIntent;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final intent = await showModalBottomSheet<NiyyahIntent>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RoutineNiyyahSheet(routine: testRoutine),
                );
                resultIntent = intent;
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('تست نیت انجام'), findsOneWidget);

      await tester.tap(find.text('شروع تایمر تمرکز'));
      await tester.pumpAndSettle();

      expect(resultIntent, isNotNull);
      expect(resultIntent!.action, equals(NiyyahAction.startTimer));
    });

    testWidgets('Tapping Instant Completion pops NiyyahIntent.completeInstantly', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      NiyyahIntent? resultIntent;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final intent = await showModalBottomSheet<NiyyahIntent>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RoutineNiyyahSheet(routine: testRoutine),
                );
                resultIntent = intent;
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ثبت فوری بدون تایمر'));
      await tester.pumpAndSettle();

      expect(resultIntent, isNotNull);
      expect(resultIntent!.action, equals(NiyyahAction.completeInstantly));
    });

    testWidgets('Tapping Edit pops NiyyahIntent.edit', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      NiyyahIntent? resultIntent;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final intent = await showModalBottomSheet<NiyyahIntent>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RoutineNiyyahSheet(routine: testRoutine),
                );
                resultIntent = intent;
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ویرایش'));
      await tester.pumpAndSettle();

      expect(resultIntent, isNotNull);
      expect(resultIntent!.action, equals(NiyyahAction.edit));
    });
  });
}
