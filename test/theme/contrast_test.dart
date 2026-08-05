import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

double _luminance(Color c) {
  double r = c.r;
  double g = c.g;
  double b = c.b;

  r = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
  g = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
  b = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void _checkContrast({
  required String paletteName,
  required String modeName,
  required String tokenA,
  required Color colorA,
  required String tokenB,
  required Color colorB,
  required double minRatio,
}) {
  final ratio = _contrastRatio(colorA, colorB);
  expect(
    ratio >= minRatio,
    isTrue,
    reason: 'Contrast check failed for [$paletteName - $modeName]: $tokenA ($colorA) vs $tokenB ($colorB). Expected >= $minRatio, got ${ratio.toStringAsFixed(2)}',
  );
}

void main() {
  group('WCAG Contrast Ratio Tests for 10 Color Sets (5 Palettes x 2 Modes)', () {
    for (final palette in RitmoPalette.all) {
      for (final brightness in Brightness.values) {
        final modeName = brightness == Brightness.dark ? 'dark' : 'light';
        final paletteName = palette.nameFa;
        final colors = palette.forBrightness(brightness);

        test('Contrast test: $paletteName ($modeName)', () {
          // 1. textPrimary on surface >= 4.5:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'textPrimary',
            colorA: colors.textPrimary,
            tokenB: 'surface',
            colorB: colors.surface,
            minRatio: 4.5,
          );

          // 2. textPrimary on background >= 4.5:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'textPrimary',
            colorA: colors.textPrimary,
            tokenB: 'background',
            colorB: colors.background,
            minRatio: 4.5,
          );

          // 3. onPrimary on primary >= 4.5:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'onPrimary',
            colorA: colors.onPrimary,
            tokenB: 'primary',
            colorB: colors.primary,
            minRatio: 4.5,
          );

          // 4. textSecondary on surface >= 3.0:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'textSecondary',
            colorA: colors.textSecondary,
            tokenB: 'surface',
            colorB: colors.surface,
            minRatio: 3.0,
          );

          // 5. textOnColor on error, success, warning >= 4.5:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'textOnColor',
            colorA: colors.textOnColor,
            tokenB: 'error',
            colorB: colors.error,
            minRatio: 4.5,
          );
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'textOnColor',
            colorA: colors.textOnColor,
            tokenB: 'success',
            colorB: colors.success,
            minRatio: 4.5,
          );

          // 6. primary on surface >= 3.0:1
          _checkContrast(
            paletteName: paletteName,
            modeName: modeName,
            tokenA: 'primary',
            colorA: colors.primary,
            tokenB: 'surface',
            colorB: colors.surface,
            minRatio: 3.0,
          );

          // 7. Each module color on surface >= 3.0:1
          for (int slot = 0; slot < 8; slot++) {
            final moduleColor = colors.modules.bySlot(slot);
            _checkContrast(
              paletteName: paletteName,
              modeName: modeName,
              tokenA: 'moduleSlot($slot)',
              colorA: moduleColor,
              tokenB: 'surface',
              colorB: colors.surface,
              minRatio: 3.0,
            );
          }
        });
      }
    }
  });
}
