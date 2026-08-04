import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo_swipeable_row.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: RitmoTheme(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child,
          ),
        ),
      ),
    );
  }

  group('RitmoSwipeableRow Swipe Tests (F-13)', () {
    testWidgets('Swipe Right triggers onSwipeComplete callback', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          RitmoSwipeableRow(
            itemId: 'r_test1',
            onSwipeComplete: () => completed = true,
            child: const SizedBox(height: 60, width: 300, child: Text('Test Routine')),
          ),
        ),
      );

      // In RTL, dragging from left to right is endToStart, dragging from right to left is startToEnd
      await tester.drag(find.text('Test Routine'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
