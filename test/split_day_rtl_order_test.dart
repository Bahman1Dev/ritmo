import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_split_day_view.dart';

void main() {
  testWidgets('TimelineSplitDayView renders Morning column on the right side in RTL', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimelineSplitDayView(
            items: [],
            isToday: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final morningHeader = find.text('صبح');
    final afternoonHeader = find.text('بعدازظهر');

    expect(morningHeader, findsOneWidget);
    expect(afternoonHeader, findsOneWidget);

    final morningPos = tester.getTopLeft(morningHeader);
    final afternoonPos = tester.getTopLeft(afternoonHeader);

    // In RTL, the first child in Row is rendered on the RIGHT (higher X coordinate).
    // So morningPos.dx should be greater than afternoonPos.dx.
    expect(morningPos.dx > afternoonPos.dx, isTrue);
  });
}
