import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_date_formatter.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';

void main() {
  group('Calendar Journey Controller, Header & View Tests', () {
    test('1. JourneyController scale & navigation operations', () {
      final controller = JourneyController();
      final initialDate = DateTime(2026, 7, 24);
      controller.loadDate(initialDate);

      // setScale(week) changes activeScale to week
      controller.setScale(JourneyScale.week);
      expect(controller.activeScale, equals(JourneyScale.week));

      // navigatePeriod(1) in day scale moves selectedDate by 1 day
      controller.setScale(JourneyScale.day);
      controller.navigatePeriod(1);
      expect(controller.selectedDate.day, equals(25));

      // navigatePeriod(1) in week scale moves selectedDate by 7 days
      controller.setScale(JourneyScale.week);
      controller.navigatePeriod(1);
      expect(controller.selectedDate.day, equals(1)); // 25 + 7 = Aug 1

      // navigatePeriod(1) in month scale moves selectedDate by ~1 month
      controller.setScale(JourneyScale.month);
      controller.navigatePeriod(1);
      expect(controller.selectedDate.month, equals(9)); // Aug -> Sep

      // selectDate with scaleToSet switches scale and date together
      final targetDate = DateTime(2026, 10, 15);
      controller.selectDate(targetDate, scaleToSet: JourneyScale.year);
      expect(controller.selectedDate, equals(targetDate));
      expect(controller.activeScale, equals(JourneyScale.year));

      controller.dispose();
    });

    test('2. Header formatter tests for relative dates and Shamsi year', () {
      final now = DateTime(2026, 7, 24);
      final tomorrow = DateTime(2026, 7, 25);

      final todayTitle = CalendarDateFormatter.formatSelectedDateTitle(
        now,
        relativeTo: now,
        includeYear: false,
      );
      expect(todayTitle, contains('امروز'));

      final tomorrowTitle = CalendarDateFormatter.formatSelectedDateTitle(
        tomorrow,
        relativeTo: now,
        includeYear: false,
      );
      expect(tomorrowTitle, contains('فردا'));

      final yearTitle = CalendarDateFormatter.formatSelectedDateTitle(
        now,
        includeYear: true,
      );
      expect(yearTitle, contains('۱۴۰۵')); // 24 July 2026 is 2 Mordad 1405
    });

    testWidgets('3. Persian string smoke tests for Journey views', (tester) async {
      // Test JourneyScaleSwitcher
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyScaleSwitcher(
            activeScale: JourneyScale.day,
            onScaleChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('روز'), findsOneWidget);
      expect(find.text('هفته'), findsOneWidget);
      expect(find.text('ماه'), findsOneWidget);
      expect(find.text('سال'), findsOneWidget);

      // Test JourneyWeekView
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyWeekView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectDate: (_) {},
          ),
        ),
      ));

      expect(find.text('برنامه هفتگی'), findsOneWidget);
      expect(find.text('شنبه'), findsWidgets);
      expect(find.text('جمعه'), findsWidgets);

      // Test JourneyMonthView
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyMonthView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectDate: (_) {},
          ),
        ),
      ));

      expect(find.text('ش'), findsOneWidget);
      expect(find.text('ی'), findsOneWidget);
      expect(find.text('د'), findsOneWidget);
      expect(find.text('س'), findsOneWidget);
      expect(find.text('چ'), findsOneWidget);
      expect(find.text('پ'), findsOneWidget);
      expect(find.text('ج'), findsOneWidget);

      // Test JourneyYearView
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JourneyYearView(
            selectedDate: DateTime(2026, 7, 24),
            rangeSnapshots: const {},
            onSelectMonth: (_) {},
          ),
        ),
      ));

      expect(find.text('فروردین'), findsOneWidget);
      expect(find.text('اردیبهشت'), findsOneWidget);
      expect(find.text('مرداد'), findsOneWidget);
    });
  });
}
