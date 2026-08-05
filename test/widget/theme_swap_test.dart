import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_preferences.dart';
import 'package:ritmo/core/theme/theme_repository.dart';

void main() {
  testWidgets('Theme swap rebuilds app and changes primary color dynamically', (tester) async {
    final themeRepo = ThemeRepository();

    await tester.pumpWidget(
      ValueListenableBuilder<ThemePreferences>(
        valueListenable: themeRepo.preferencesNotifier,
        builder: (context, prefs, _) {
          final palette = RitmoPalette.byId(prefs.paletteId);
          return MaterialApp(
            theme: RitmoTheme.build(
              palette: palette,
              brightness: Brightness.light,
            ),
            home: Scaffold(
              body: Builder(
                builder: (innerContext) {
                  final color = innerContext.colors.primary;
                  return Container(
                    key: const ValueKey('sample_card'),
                    color: color,
                    child: Text(
                      'Primary: ${color.toARGB32().toRadixString(16)}',
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    const initialPalette = RitmoPalette.jadeNoir;
    expect(find.text('Primary: ${initialPalette.light.primary.toARGB32().toRadixString(16)}'), findsOneWidget);

    // Swap palette to copperDusk
    await themeRepo.updatePalette(RitmoPaletteId.copperDusk);
    await tester.pumpAndSettle();

    const newPalette = RitmoPalette.copperDusk;
    expect(find.text('Primary: ${newPalette.light.primary.toARGB32().toRadixString(16)}'), findsOneWidget);
  });
}
