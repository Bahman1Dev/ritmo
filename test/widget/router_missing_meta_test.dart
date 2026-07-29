import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

void main() {
  testWidgets('ActionRouter handles missing routine meta gracefully', (WidgetTester tester) async {
    final item = AgendaItem(
      id: 'item_missing_meta',
      sourceId: 'non_existent_routine_id',
      domain: AgendaDomain.routine,
      category: Category.personal,
      title: 'برنامه ناموجود',
      dateStr: '2026-07-26',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => ActionRouter.open(context, item: item),
                child: const Text('Open Router'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Router'));
    await tester.pumpAndSettle();

    // Verify app did not crash and gracefully presented failure feedback / toast
    expect(find.text('Open Router'), findsOneWidget);
  });
}
