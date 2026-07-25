import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onEdit callback', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r4',
      title: 'مدیتیشن',
      frequencyType: 'DAILY',
      createdAt: 0,
      updatedAt: 0,
    );

    bool editCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) {},
            onCompleteInstantly: (_, __) {},
            onSnooze: () {},
            onEdit: () {
              editCalled = true;
            },
            onViewDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('ویرایش'), findsOneWidget);

    await tester.tap(find.text('ویرایش'));
    await tester.pump();

    expect(editCalled, isTrue);
  });
}
