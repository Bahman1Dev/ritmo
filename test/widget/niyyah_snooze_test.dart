import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onSnooze callback', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r3',
      title: 'پیاده‌روی',
      frequencyType: 'DAILY',
      createdAt: 0,
      updatedAt: 0,
    );

    bool snoozeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) {},
            onCompleteInstantly: (_, __) {},
            onSnooze: () {
              snoozeCalled = true;
            },
            onEdit: () {},
            onViewDetails: () {},
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
