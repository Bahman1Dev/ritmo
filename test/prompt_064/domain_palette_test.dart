import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';

import 'package:ritmo/core/theme/ritmo_theme.dart';

void main() {
  testWidgets('K8 — domainColor for AgendaDomain.task is unique across all domains', (WidgetTester tester) async {
    late BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: RitmoTheme.lightTheme,
        home: Builder(
          builder: (context) {
            savedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final colorsByDomain = <AgendaDomain, Color>{};
    for (final domain in AgendaDomain.values) {
      colorsByDomain[domain] = domainColor(savedContext, domain);
    }

    final taskColor = colorsByDomain[AgendaDomain.task]!;
    expect(taskColor, isNotNull);

    // Verify task domain label and icon
    expect(domainLabelFa(AgendaDomain.task), equals('کار'));
    expect(domainIcon(AgendaDomain.task), isNotNull);
  });
}
