import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onViewDetails callback', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r5',
      title: 'نوشیدن آب',
      frequencyType: 'DAILY',
      createdAt: 0,
      updatedAt: 0,
    );

    bool detailsCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) {},
            onCompleteInstantly: (_, __) {},
            onSnooze: () {},
            onEdit: () {},
            onViewDetails: () {
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
