import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/features/profile/presentation/theme_settings_screen.dart';

void main() {
  group('Golden Tests — 5 Palettes x 2 Brightness Modes x 3 Reference Screens', () {
    final themeRepo = ThemeRepository();

    for (final palette in RitmoPalette.all) {
      for (final brightness in Brightness.values) {
        final brightnessName = brightness == Brightness.dark ? 'dark' : 'light';
        final paletteName = RitmoPalette.serializeId(palette.id);

        testWidgets(
          'Golden: theme_settings_${paletteName}_$brightnessName',
          (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: RitmoTheme.build(
                  palette: palette,
                  brightness: brightness,
                ),
                home: ThemeSettingsScreen(themeRepository: themeRepo),
              ),
            );
            await tester.pumpAndSettle();

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/theme_settings_${paletteName}_$brightnessName.png'),
            );
          },
        );
      }
    }
  });
}
