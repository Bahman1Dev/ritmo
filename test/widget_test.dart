import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

void main() {
  testWidgets('RitmoColors extension correctly resolves light and dark themes', (tester) async {
    // 1. Test Light Theme Resolution
    late RitmoColors resolvedLightColors;
    await tester.pumpWidget(
      Theme(
        data: RitmoTheme.lightTheme,
        child: Builder(
          builder: (context) {
            resolvedLightColors = Theme.of(context).extension<RitmoColors>()!;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolvedLightColors.bg, RitmoColors.light.bg);
    expect(resolvedLightColors.card, RitmoColors.light.card);
    expect(resolvedLightColors.textPrimary, RitmoColors.light.textPrimary);

    // 2. Test Dark Theme Resolution
    late RitmoColors resolvedDarkColors;
    await tester.pumpWidget(
      Theme(
        data: RitmoTheme.darkTheme,
        child: Builder(
          builder: (context) {
            resolvedDarkColors = Theme.of(context).extension<RitmoColors>()!;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolvedDarkColors.bg, RitmoColors.dark.bg);
    expect(resolvedDarkColors.card, RitmoColors.dark.card);
    expect(resolvedDarkColors.textPrimary, RitmoColors.dark.textPrimary);
  });
}
