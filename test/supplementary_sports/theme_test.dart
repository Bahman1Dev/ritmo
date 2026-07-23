import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

void main() {
  group('Supplementary Sports Theme Unit Tests', () {
    test('Font family should be Vazirmatn', () {
      expect(SupplementarySportsTheme.fontFamily, equals('Vazirmatn'));
    });

    test('Spacing and radius values are correct', () {
      expect(SupplementarySportsTheme.spacing4, equals(4.0));
      expect(SupplementarySportsTheme.spacing8, equals(8.0));
      expect(SupplementarySportsTheme.spacing16, equals(16.0));
      expect(SupplementarySportsTheme.spacing32, equals(32.0));
      expect(SupplementarySportsTheme.radiusCard, equals(16.0));
      expect(SupplementarySportsTheme.radiusButton, equals(12.0));
    });

    test('Workout Gradient returns correct colors for categories', () {
      final recoveryGradient = SupplementarySportsTheme.getWorkoutGradient('یوگا ریکاوری');
      expect(recoveryGradient.colors.first, equals(const Color(0xFF10B981)));

      final cardioGradient = SupplementarySportsTheme.getWorkoutGradient('تمرین هوازی');
      expect(cardioGradient.colors.first, equals(const Color(0xFFEC4899)));

      final defaultGradient = SupplementarySportsTheme.getWorkoutGradient('تمرین قدرتی');
      expect(defaultGradient.colors.first, equals(const Color(0xFFF59E0B)));
    });
  });
}
