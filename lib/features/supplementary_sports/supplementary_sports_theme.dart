import 'package:flutter/material.dart';

class SupplementarySportsTheme {
  // --- Colors ---
  static const Color bgLight = Color(0xFFFAFAF8);
  static const Color bgDark = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF0F0F0);

  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  static const Color successLight = Color(0xFF2E7D5B);
  static const Color successDark = Color(0xFF4CAF7D);

  static const Color warningLight = Color(0xFFC9822A);
  static const Color warningDark = Color(0xFFE0A75E);

  static const Color dangerLight = Color(0xFFC0392B);
  static const Color dangerDark = Color(0xFFE06C5C);

  // Dynamic getters based on brightness
  static Color getBackgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;

  static Color getSurfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color getSuccessColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? successDark : successLight;

  static Color getWarningColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warningDark : warningLight;

  static Color getDangerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dangerDark : dangerLight;

  // --- Typography ---
  static const String fontFamily = 'Vazirmatn';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500, // Medium
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
  );

  // --- Spacing Scale ---
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // --- Corner Radius ---
  static const double radiusButton = 12;
  static const double radiusField = 12;
  static const double radiusCard = 16;
  static const double radiusBottomSheet = 20;

  static const BorderRadius borderRadiusButton = BorderRadius.all(Radius.circular(radiusButton));
  static const BorderRadius borderRadiusField = BorderRadius.all(Radius.circular(radiusField));
  static const BorderRadius borderRadiusCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius borderRadiusBottomSheet = BorderRadius.only(
    topLeft: Radius.circular(radiusBottomSheet),
    topRight: Radius.circular(radiusBottomSheet),
  );

  // --- Touch Target Size ---
  static const double minimumTouchTarget = 48;

  // --- Premium UI Helpers ---
  static BoxDecoration glassyCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
      borderRadius: borderRadiusCard,
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static LinearGradient getWorkoutGradient(String workoutName) {
    final nameLower = workoutName.toLowerCase();
    if (nameLower.contains('recovery') || nameLower.contains('yoga') || nameLower.contains('stretch') || nameLower.contains('کشش') || nameLower.contains('یوگا') || nameLower.contains('ریکاوری')) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF047857)], // Teal green recovery
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (nameLower.contains('cardio') || nameLower.contains('run') || nameLower.contains('hiit') || nameLower.contains('هوازی') || nameLower.contains('دویدن') || nameLower.contains('سرعتی')) {
      return const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFBE185D)], // Pink cardio
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Strength / weight lifting / default
    return const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Energetic amber/orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
