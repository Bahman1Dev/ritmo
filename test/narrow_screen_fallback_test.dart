import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_split_day_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_grid.dart';

void main() {
  testWidgets('TimelineSplitDayView falls back to single-column TimelineGrid on narrow screen (<340px)', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
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

    // Morning and Afternoon column headers should NOT be present in fallback single column mode
    expect(find.text('صبح'), findsNothing);
    expect(find.text('بعدازظهر'), findsNothing);
    expect(find.byType(TimelineGrid), findsOneWidget);
  });
}
