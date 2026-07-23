import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_agenda_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: RitmoTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('PrayerAgendaCard Widget & State Flow Tests', () {
    testWidgets('Renders correct title and time string', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PrayerAgendaCard(
            title: 'نماز ظهر',
            timeStr: '12:15',
            isDone: false,
            isSkipped: false,
            isSnoozed: false,
            deferCount: 0,
            hasReminder: false,
          ),
        ),
      );

      expect(find.text('نماز ظهر'), findsOneWidget);
      expect(find.text('12:15'), findsOneWidget);
      
      // Ensure checkbox is unchecked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('Tapping Checkbox triggers onToggle callback', (tester) async {
      bool? toggledVal;
      await tester.pumpWidget(
        buildTestableWidget(
          PrayerAgendaCard(
            title: 'نماز عصر',
            timeStr: '15:30',
            isDone: false,
            isSkipped: false,
            isSnoozed: false,
            deferCount: 0,
            hasReminder: false,
            onToggle: (val) {
              toggledVal = val;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(toggledVal, true);
    });

    testWidgets('Disable controls disables checkbox interaction', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        buildTestableWidget(
          PrayerAgendaCard(
            title: 'نماز مغرب',
            timeStr: '19:45',
            isDone: false,
            isSkipped: false,
            isSnoozed: false,
            deferCount: 0,
            hasReminder: false,
            disableControls: true,
            onToggle: (val) {
              toggled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(toggled, false);
    });

    testWidgets('Skipped state disables checkbox and styles differently', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PrayerAgendaCard(
            title: 'نماز عشا',
            timeStr: '21:00',
            isDone: false,
            isSkipped: true,
            isSnoozed: false,
            deferCount: 0,
            hasReminder: false,
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('Renders warning background when expiring soon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PrayerAgendaCard(
            title: 'نماز صبح',
            timeStr: '04:30',
            isDone: false,
            isSkipped: false,
            isSnoozed: false,
            deferCount: 0,
            hasReminder: false,
            isExpiringSoon: true,
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNotNull);
    });
  });
}
