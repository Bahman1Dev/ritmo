import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_motion.dart';

void main() {
  testWidgets('CalendarMotion.d returns Duration.zero when userReduceMotion is enabled', (tester) async {
    CalendarMotion.setReduceMotion(true);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final d = CalendarMotion.d(context, const Duration(milliseconds: 300));
            expect(d, Duration.zero);
            return const SizedBox();
          },
        ),
      ),
    );

    CalendarMotion.setReduceMotion(false);
  });
}
