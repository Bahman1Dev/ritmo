import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/features/profile/presentation/theme_settings_screen.dart';

void main() {
  testWidgets('ThemeSettingsScreen renders 5 preview cards and triggers palette selection', (tester) async {
    final themeRepo = ThemeRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: RitmoTheme.build(
          palette: RitmoPalette.jadeNoir,
          brightness: Brightness.dark,
        ),
        home: ThemeSettingsScreen(themeRepository: themeRepo),
      ),
    );

    // Verify Title
    expect(find.text('ظاهر و تم'), findsOneWidget);

    // Verify 5 Palette Preview Cards exist by name
    expect(find.text('یشم شب · آرام و طبیعی'), findsOneWidget);
    expect(find.text('مس غروب · گرم و لوکس'), findsOneWidget);
    expect(find.text('رز چوبی · شخصی و صمیمی'), findsOneWidget);
    expect(find.text('زیتون و شن · مینیمال و تمرکزمحور'), findsOneWidget);
    expect(find.text('گرافیت و شامپاینی · خنثی و رسمی'), findsOneWidget);

    // Tap on second palette (Copper Dusk)
    await tester.ensureVisible(find.text('مس غروب · گرم و لوکس'));
    await tester.tap(find.text('مس غروب · گرم و لوکس'));
    await tester.pumpAndSettle();

    // Verify selection notifier updated to copperDusk
    expect(themeRepo.preferencesNotifier.value.paletteId, equals(RitmoPaletteId.copperDusk));
  });
}
