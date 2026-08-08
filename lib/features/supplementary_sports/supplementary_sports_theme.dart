import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// لایه نگاشت تم تکمیلی ورزش و حرکت به توکن‌های مرکزی Ritmo
class SupplementarySportsTheme {
  const SupplementarySportsTheme({
    required this.bg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.emeraldPrimary,
    required this.surfaceVariant,
    required this.surfaceBackground,
    required this.cardBorder,
  });

  final Color bg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color emeraldPrimary;
  final Color surfaceVariant;
  final Color surfaceBackground;
  final Color cardBorder;

  /// Dynamic constructor from BuildContext using central RitmoTheme tokens
  factory SupplementarySportsTheme.of(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    return SupplementarySportsTheme(
      bg: colors.background,
      card: colors.surface,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      emeraldPrimary: context.modules.sports,
      surfaceVariant: colors.surfaceElevated,
      surfaceBackground: colors.background,
      cardBorder: colors.textPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
    );
  }

  /// Default fallback instance
  static const dark = SupplementarySportsTheme(
    bg: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFFA0A0A0),
    emeraldPrimary: Color(0xFF10B981),
    surfaceVariant: Color(0xFF262626),
    surfaceBackground: Color(0xFF171717),
    cardBorder: Color(0xFF404040),
  );

  // Dynamic getters mapped to Ritmo central tokens
  static Color getBackgroundColor(BuildContext context) => context.colors.background;
  static Color getSurfaceColor(BuildContext context) => context.colors.surface;
  static Color getTextPrimary(BuildContext context) => context.colors.textPrimary;
  static Color getTextSecondary(BuildContext context) => context.colors.textSecondary;
  static Color getSuccessColor(BuildContext context) => context.colors.success;
  static Color getWarningColor(BuildContext context) => context.colors.warning;
  static Color getDangerColor(BuildContext context) => context.colors.error;
  static Color getSportsAccent(BuildContext context) => context.modules.sports;

  // --- Typography ---
  static const String fontFamily = 'Vazirmatn';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // --- Spacing Scale ---
  static const double spacing4 = RitmoSpacing.xs;
  static const double spacing8 = RitmoSpacing.sm;
  static const double spacing12 = RitmoSpacing.md;
  static const double spacing16 = RitmoSpacing.lg;
  static const double spacing24 = RitmoSpacing.xl;
  static const double spacing32 = RitmoSpacing.xxl;
  static const double spacing48 = RitmoSpacing.xxxl;

  // --- Corner Radius ---
  static const double radiusButton = RitmoRadius.field;
  static const double radiusField = RitmoRadius.field;
  static const double radiusCard = RitmoRadius.card;
  static const double radiusBottomSheet = RitmoRadius.sheet;

  static const BorderRadius borderRadiusButton = BorderRadius.all(Radius.circular(radiusButton));
  static const BorderRadius borderRadiusField = BorderRadius.all(Radius.circular(radiusField));
  static const BorderRadius borderRadiusCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius borderRadiusBottomSheet = BorderRadius.only(
    topLeft: Radius.circular(radiusBottomSheet),
    topRight: Radius.circular(radiusBottomSheet),
  );

  static const double minimumTouchTarget = 48;

  static BoxDecoration glassyCardDecoration(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: borderRadiusCard,
      border: Border.all(color: colors.border),
      boxShadow: isDark ? RitmoElevation.none : RitmoElevation.cardLight,
    );
  }

  static LinearGradient getWorkoutGradient(String workoutName) {
    final nameLower = workoutName.toLowerCase();
    if (nameLower.contains('recovery') || nameLower.contains('yoga') || nameLower.contains('stretch') || nameLower.contains('کشش') || nameLower.contains('یوگا') || nameLower.contains('ریکاوری')) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (nameLower.contains('cardio') || nameLower.contains('run') || nameLower.contains('hiit') || nameLower.contains('هوازی') || nameLower.contains('دویدن') || nameLower.contains('سرعتی')) {
      return const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
