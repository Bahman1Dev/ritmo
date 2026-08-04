import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';

void main() {
  testWidgets('RoutineNiyyahSheet triggers onCompleteInstantly on instant log tap', (WidgetTester tester) async {
    final routine = Routine(
      id: 'test_r2',
      title: 'مطالعه کتاب',
      targetDurationMinutes: 30,
      category: Category.learning,
      routineType: RoutineType.timeBased,
      notificationLevel: NotificationLevel.normal,
      isEssential: true,
      energyRule: EnergyRule.none,
    );

    String? completedMode;
    int? completedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineNiyyahSheet(
            routine: routine,
            onStartTimer: (_) async {},
            onCompleteInstantly: (mode, duration) async {
              completedMode = mode;
              completedDuration = duration;
            },
            onSnooze: () async {},
            onEdit: () async {},
            onViewDetails: () async {},
          ),
        ),
      ),
    );

    expect(find.text('ثبت فوری بدون تایمر'), findsOneWidget);

    await tester.tap(find.text('ثبت فوری بدون تایمر'));
    await tester.pump();

    expect(completedMode, equals('FULL'));
    expect(completedDuration, equals(30));
  });
}
