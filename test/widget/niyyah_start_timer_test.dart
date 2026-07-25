import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet displays timer modes and triggers onStartTimer', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r1',
      title: 'تمرین روزانه',
      targetDurationMinutes: 30,
      lightDurationMinutes: 15,
      minimalDurationMinutes: 5,
      frequencyType: 'DAILY',
      createdAt: 0,
      updatedAt: 0,
    );

    String? startedMode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (mode) {
              startedMode = mode;
            },
            onCompleteInstantly: (_, __) {},
            onSnooze: () {},
            onEdit: () {},
            onViewDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('تمرین روزانه'), findsOneWidget);
    expect(find.text('شروع تایمر تمرکز'), findsOneWidget);

    await tester.tap(find.text('شروع تایمر تمرکز'));
    await tester.pump();

    expect(startedMode, equals('FULL'));
  });
}
