import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

void main() {
  testWidgets('ActionRouter opens confirmation sheet for Prayer domain', (WidgetTester tester) async {
    final item = AgendaItem(
      id: 'prayer_item_1',
      sourceId: 'p_1',
      domain: AgendaDomain.prayer,
      title: 'نماز ظهر',
      dateStr: '2026-07-26',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => ActionRouter.open(context, item: item),
                child: const Text('Open Prayer'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Prayer'));
    await tester.pumpAndSettle();

    expect(find.text('نماز ظهر'), findsOneWidget);
    expect(find.text('ثبت انجام'), findsOneWidget);
    expect(find.text('انصراف'), findsOneWidget);
  });
}
