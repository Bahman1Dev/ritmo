import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onViewDetails callback', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r5',
      title: 'نوشیدن آب',
      category: Category.health,
      routineType: RoutineType.timeBased,
      notificationLevel: NotificationLevel.normal,
      isEssential: true,
      energyRule: EnergyRule.none,
    );

    bool detailsCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) async {},
            onCompleteInstantly: (_, __) async {},
            onSnooze: () async {},
            onEdit: () async {},
            onViewDetails: () async {
              detailsCalled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('جزئیات'), findsOneWidget);

    await tester.tap(find.text('جزئیات'));
    await tester.pump();

    expect(detailsCalled, isTrue);
  });
}
