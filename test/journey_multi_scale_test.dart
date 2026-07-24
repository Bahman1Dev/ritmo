import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';

void main() {
  group('Phase 5 Multi-Scale Navigation MVP Tests', () {
    test('1. JourneyController scale switching and date navigation', () {
      final controller = JourneyController();
      expect(controller.activeScale, equals(JourneyScale.day));

      controller.setScale(JourneyScale.week);
      expect(controller.activeScale, equals(JourneyScale.week));

      final initialDate = controller.selectedDate;
      controller.navigatePeriod(1);
      expect(controller.selectedDate.difference(initialDate).inDays, equals(7));

      controller.setScale(JourneyScale.month);
      expect(controller.activeScale, equals(JourneyScale.month));

      controller.selectDate(DateTime(2026, 8, 15), scaleToSet: JourneyScale.day);
      expect(controller.selectedDate, equals(DateTime(2026, 8, 15)));
      expect(controller.activeScale, equals(JourneyScale.day));
    });

    testWidgets('2. JourneyScaleSwitcher renders 4 scale options and handles tap', (tester) async {
      JourneyScale? selectedScale;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyScaleSwitcher(
            activeScale: JourneyScale.day,
            onScaleChanged: (s) => selectedScale = s,
          ),
        ),
      ));

      expect(find.text('روز'), findsOneWidget);
      expect(find.text('هفته'), findsOneWidget);
      expect(find.text('ماه'), findsOneWidget);
      expect(find.text('سال'), findsOneWidget);

      await tester.tap(find.text('هفته'));
      await tester.pumpAndSettle();

      expect(selectedScale, equals(JourneyScale.week));
    });

    testWidgets('3. JourneyWeekView renders 7 days and triggers date selection', (tester) async {
      DateTime? tappedDate;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyWeekView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectDate: (d) => tappedDate = d,
          ),
        ),
      ));

      expect(find.text('Week Overview'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);

      await tester.tap(find.text('Sat'));
      await tester.pumpAndSettle();

      expect(tappedDate, isNotNull);
    });

    testWidgets('4. JourneyMonthView renders month grid and handles tap', (tester) async {
      DateTime? tappedDate;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyMonthView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectDate: (d) => tappedDate = d,
          ),
        ),
      ));

      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(tappedDate?.day, equals(15));
    });

    testWidgets('5. JourneyYearView renders 12 months and handles tap', (tester) async {
      DateTime? tappedMonth;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyYearView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectMonth: (d) => tappedMonth = d,
          ),
        ),
      ));

      expect(find.text('Year 2026 Overview'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);

      await tester.tap(find.text('May'));
      await tester.pumpAndSettle();

      expect(tappedMonth?.month, equals(5));
    });
  });
}
