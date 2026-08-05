// توکن‌های رنگ مرکزی Ritmo — پیاده‌سازی ThemeExtension
// جایگزین تمام رنگ‌های هاردکد لایه presentation

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';
import 'package:ritmo/core/theme/palettes/jade_noir.dart';

@immutable
class RitmoColors extends ThemeExtension<RitmoColors> {
  const RitmoColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.primary,
    required this.primaryPressed,
    required this.primaryContainer,
    required this.onPrimary,
    required this.accent,
    required this.accentContainer,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnColor,
    required this.border,
    required this.divider,
    required this.disabled,
    required this.overlay,
    required this.glassTint,
    required this.shadow,
    required this.systemNavBar,
    required this.brandGradient,
    required this.modules,
  });

  final Color background; // پس‌زمینهٔ Scaffold
  final Color surface; // کارت معمولی
  final Color surfaceElevated; // کارت برجسته و شیت
  final Color surfaceSunken; // فیلد ورودی، ترک نوار پیشرفت
  final Color primary;
  final Color primaryPressed;
  final Color primaryContainer; // پس‌زمینهٔ ملایم حالت انتخاب‌شده
  final Color onPrimary; // متن و آیکن روی primary
  final Color accent; // طلایی شامپاینی
  final Color accentContainer;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary; // متن کم‌اهمیت، placeholder
  final Color textOnColor; // متن روی success/warning/error
  final Color border; // خط دور کارت (فقط حالت تاریک فعال است)
  final Color divider;
  final Color disabled;
  final Color overlay; // پشت شیت و دیالوگ
  final Color glassTint; // رنگ روی BackdropFilter
  final Color shadow; // سایه (فقط حالت روشن فعال است)
  final Color systemNavBar; // رنگ نوار ناوبری سیستم
  final List<Color> brandGradient; // دقیقاً دو رنگ
  final RitmoModuleColors modules;

  // ── Backward-Compatibility Getters ─────────────────────────
  Color get bg => background;
  Color get card => surface;
  Color get medicalRed => error;
  Color get goldAccent => accent;
  List<Color> get energyGradient => brandGradient;
  List<Color> get goldGradient => [accent, accentContainer];
  Color get cardTitle => textPrimary;
  Color get cardSubtitle => textSecondary;
  Color get cardBorder => border;
  Color get inputBackground => surfaceSunken;
  Color get glassBorder => border;
  Color get sectionTitle => textPrimary;
  Color get warningText => warning;
  Color get successText => success;
  Color get cardFill => primaryContainer;
  Color get sheetBackground => surfaceElevated;
  Color get iconSecondary => textSecondary;
  Color get shadowColor => shadow;
  Color get onSurface => textPrimary;
  Color get onSurfaceVariant => textSecondary;
  Color get surfaceVariant => primaryContainer;
  Color get outlineVariant => border;
  Color get secondary => primary;
  Color get onBackground => textPrimary;

  // ── Wellbeing Semantic Accent Tokens (T-0.4) ────────────────
  Color get sleepAccent => const Color(0xff8B5CF6);
  Color get energyAccent => const Color(0xffEC4899);
  Color get reflectionAccent => const Color(0xff06B6D4);
  Color get reflectionAccentAlt => const Color(0xff22D3EE);
  Color get cautionAccent => warning;
  Color get dangerAccent => error;

  static Color glassSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
  }

  static Color staticGlassBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10);
  }

  @override
  RitmoColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? primary,
    Color? primaryPressed,
    Color? primaryContainer,
    Color? onPrimary,
    Color? accent,
    Color? accentContainer,
    Color? success,
    Color? warning,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnColor,
    Color? border,
    Color? divider,
    Color? disabled,
    Color? overlay,
    Color? glassTint,
    Color? shadow,
    Color? systemNavBar,
    List<Color>? brandGradient,
    RitmoModuleColors? modules,
  }) {
    return RitmoColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnColor: textOnColor ?? this.textOnColor,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      disabled: disabled ?? this.disabled,
      overlay: overlay ?? this.overlay,
      glassTint: glassTint ?? this.glassTint,
      shadow: shadow ?? this.shadow,
      systemNavBar: systemNavBar ?? this.systemNavBar,
      brandGradient: brandGradient ?? this.brandGradient,
      modules: modules ?? this.modules,
    );
  }

  @override
  RitmoColors lerp(ThemeExtension<RitmoColors>? other, double t) {
    if (other is! RitmoColors) return this;
    return RitmoColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnColor: Color.lerp(textOnColor, other.textOnColor, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      systemNavBar: Color.lerp(systemNavBar, other.systemNavBar, t)!,
      brandGradient: [
        Color.lerp(brandGradient.first, other.brandGradient.first, t)!,
        Color.lerp(brandGradient.last, other.brandGradient.last, t)!,
      ],
      modules: RitmoModuleColors.lerp(modules, other.modules, t),
    );
  }

  // Pre-baked instances for default palette backward compatibility
  static const RitmoColors light = kJadeNoirLight;
  static const RitmoColors dark = kJadeNoirDark;
}
