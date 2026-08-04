import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/occurrence_status_badge.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: RitmoTheme(
          child: child,
        ),
      ),
    );
  }

  group('OccurrenceStatusBadge Tests (K-34)', () {
    testWidgets('renders done status badge correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OccurrenceStatusBadge(status: 'done')));
      expect(find.text('انجام شد'), findsOneWidget);
    });

    testWidgets('renders skipped status badge correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OccurrenceStatusBadge(status: 'skipped')));
      expect(find.text('رد شد'), findsOneWidget);
    });

    testWidgets('renders rescheduled status badge correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OccurrenceStatusBadge(status: 'rescheduled')));
      expect(find.text('موکول شد'), findsOneWidget);
    });

    testWidgets('renders pending status badge as fallback', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OccurrenceStatusBadge(status: 'pending')));
      expect(find.text('در انتظار'), findsOneWidget);
    });
  });
}
