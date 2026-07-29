import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onSnooze callback', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r3',
      title: 'پیاده‌روی',
      category: Category.fitness,
      routineType: RoutineType.timeBased,
      notificationLevel: NotificationLevel.normal,
      isEssential: true,
      energyRule: EnergyRule.none,
    );

    bool snoozeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) async {},
            onCompleteInstantly: (_, __) async {},
            onSnooze: () async {
              snoozeCalled = true;
            },
            onEdit: () async {},
            onViewDetails: () async {},
          ),
        ),
      ),
    );

    expect(find.text('تعویق روتین'), findsOneWidget);

    await tester.tap(find.text('تعویق روتین'));
    await tester.pump();

    expect(snoozeCalled, isTrue);
  });
}
