import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/observability/ritmo_friendly_error_pane.dart';

void main() {
  group('RitmoFriendlyErrorPane Tests (R-5)', () {
    testWidgets('renders user friendly Persian error message and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RitmoFriendlyErrorPane(
            errorMessage: 'Test exception',
          ),
        ),
      );

      expect(find.text('مشکلی در پردازش این بخش پیش آمد'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_dissatisfied_rounded), findsOneWidget);
    });

    testWidgets('calls onRetry callback when retry button is tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RitmoFriendlyErrorPane(
            errorMessage: 'Test error',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      );

      expect(find.text('تلاش دوباره'), findsOneWidget);
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pump();

      expect(retried, true);
    });

    testWidgets('renders FlutterErrorDetails in debug mode', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('Widget render failed'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RitmoFriendlyErrorPane(
            details: details,
          ),
        ),
      );

      expect(find.text('مشکلی در پردازش این بخش پیش آمد'), findsOneWidget);
      if (kDebugMode) {
        expect(find.text('نمایش جزئیات فنی (Debug)'), findsOneWidget);
      }
    });
  });
}
