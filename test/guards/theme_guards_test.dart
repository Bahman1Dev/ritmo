import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_glass_surface.dart';

void main() {
  group('Theme CI Guards — G1 to G7', () {
    test('G5: Palette count guard (5 palettes and all enum values covered)', () {
      expect(
        RitmoPalette.all.length,
        equals(5),
        reason: '[گارد تم] G5: تعداد پالت‌ها باید دقیقاً ۵ باشد.',
      );
      for (final id in RitmoPaletteId.values) {
        expect(
          RitmoPalette.all.any((p) => p.id == id),
          isTrue,
          reason: '[گارد تم] G5: شناسه $id در لیست پالت‌ها پوشش داده نشده است.',
        );
      }
    });

    test('G6: Palette completeness guard (all fields valid, brandGradient has 2 colors)', () {
      for (final palette in RitmoPalette.all) {
        for (final brightness in Brightness.values) {
          final colors = palette.forBrightness(brightness);
          expect(
            colors.brandGradient.length,
            equals(2),
            reason: '[گارد تم] G6: گرادیان برند در پالت ${palette.nameFa} باید دقیقاً ۲ رنگ باشد.',
          );
        }
      }
    });

    testWidgets('G3: Max live blur count guard (max 2 BackdropFilter widgets)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RitmoTheme.build(
            palette: RitmoPalette.jadeNoir,
            brightness: Brightness.dark,
          ),
          home: Scaffold(
            bottomNavigationBar: const RitmoGlassSurface(
              blurSigma: 24,
              child: Text('Nav'),
            ),
            body: RitmoGlassSurface(
              blurSigma: 24,
              child: const Text('Body Glass'),
            ),
          ),
        ),
      );

      final blurFinder = find.byType(BackdropFilter);
      expect(
        blurFinder.evaluate().length <= 2,
        isTrue,
        reason: '[گارد تم] G3: تعداد BackdropFilter زنده در این درخت بیشتر از ۲ است.',
      );
    });
  });
}
