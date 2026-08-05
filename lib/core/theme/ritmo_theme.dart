// سیستم تم مرکزی Ritmo — تنها منبع حقیقت طراحی بصری اپ
// شامل توکن‌های فاصله، رادیوس، تایپوگرافی، تم دینامیک و اکستنشن‌های دسترسی

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_behavior.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

export 'package:ritmo/core/theme/ritmo_behavior.dart';
export 'package:ritmo/core/theme/ritmo_colors.dart';
export 'package:ritmo/core/theme/ritmo_module_colors.dart';
export 'package:ritmo/core/theme/ritmo_palette.dart';

/// توکن‌های فاصله‌گذاری — فقط ۷ مقدار مجاز (سند طراحی §۳.۲)
abstract final class RitmoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // فاصلهٔ استاندارد لبهٔ صفحه
  static const double xl = 24; // فاصلهٔ بین بخش‌های صفحه
  static const double xxl = 32;
  static const double xxxl = 48; // فضای تنفس Hero و Empty state

  static const double section = 16;
}

/// توکن‌های رادیوس — سند طراحی §۳.۳
abstract final class RitmoRadius {
  static const double field = 14; // TextField و دکمه
  static const double card = 16; // کارت معمولی
  static const double hero = 20; // کارت Hero
  static const double sheet = 28; // BottomSheet — فقط دو گوشهٔ بالا
  static const double iconButton = 12;
  static const double pill = 999; // چیپ و برچسب
  static const double badge = 8; // نشان عددی کوچک

  // Backward compatibility aliases
  static const double chip = iconButton;
  static const double cardLarge = hero;

  /// گوشه‌ی پیوسته‌ی سبک اپل (squircle) برای کارت‌های کلیدی
  static ShapeBorder squircle(double radius, {BorderSide side = BorderSide.none}) {
    return ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius * 2.35),
      side: side,
    );
  }
}

/// توکن‌های حرکت — سند طراحی §۳.۷
abstract final class RitmoMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration state = Duration(milliseconds: 200);
  static const Duration sheet = Duration(milliseconds: 320);
  static const Duration themeSwap = Duration(milliseconds: 200);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const double pressScale = 0.97;

  // Backward compatibility aliases
  static const Duration fast = press;
  static const Duration normal = state;
  static const Duration slow = sheet;
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = enter;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration effective(BuildContext context, [Duration base = state]) =>
      reduceMotion(context) ? Duration.zero : base;
}

/// هپتیک — یک قرارداد واحد (سند طراحی §۳.۸)
abstract final class RitmoHapticsPolicy {
  static void selection() => HapticFeedback.selectionClick();
  static void tap() => HapticFeedback.lightImpact();
  static void success() => HapticFeedback.mediumImpact();
  static void warning() => HapticFeedback.heavyImpact();
  static void error() => HapticFeedback.vibrate();
}

abstract final class RitmoTextStyles {
  static TextStyle heroNumber(Color color) => TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.1,
      );

  static TextStyle pageTitle(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.3,
      );

  static TextStyle sectionHeadline(Color color) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.4,
      );

  static TextStyle cardTitle(Color color) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.4,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.5,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.6,
      );

  static TextStyle label(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.3,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.6,
      );

  static TextStyle badge(Color color) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: 'Vazirmatn',
        height: 1.3,
      );
}

/// تایپوگرافی کامل و متناسب با Vazirmatn (سند طراحی §۳.۴)
abstract final class RitmoTypography {
  static TextTheme textTheme(RitmoColors colors) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
        fontFamily: 'Vazirmatn',
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
        fontFamily: 'Vazirmatn',
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
        fontFamily: 'Vazirmatn',
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
        fontFamily: 'Vazirmatn',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.5,
        fontFamily: 'Vazirmatn',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
        fontFamily: 'Vazirmatn',
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.6,
        fontFamily: 'Vazirmatn',
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.6,
        fontFamily: 'Vazirmatn',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textTertiary,
        height: 1.5,
        fontFamily: 'Vazirmatn',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        height: 1.3,
        fontFamily: 'Vazirmatn',
      ),
    );
  }
}

/// کلاس توکن‌های سایه و خط دور کارت (سند طراحی §۳.۶)
abstract final class RitmoElevation {
  static const List<BoxShadow> cardLight = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> elevatedLight = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> none = <BoxShadow>[];
  static const double borderWidthDark = 1.0;
}

class RitmoTheme {
  @Deprecated('از RitmoTheme.build استفاده کن')
  static ThemeData get darkTheme => build(
        palette: RitmoPalette.jadeNoir,
        brightness: Brightness.dark,
      );

  @Deprecated('از RitmoTheme.build استفاده کن')
  static ThemeData get lightTheme => build(
        palette: RitmoPalette.jadeNoir,
        brightness: Brightness.light,
      );

  static ThemeData build({
    required RitmoPalette palette,
    required Brightness brightness,
    bool reduceTransparency = false,
    bool trueBlack = false,
  }) {
    var colors = palette.forBrightness(brightness);
    if (trueBlack && brightness == Brightness.dark) {
      colors = colors.copyWith(
        background: const Color(0xFF000000),
        systemNavBar: const Color(0xFF000000),
      );
    }

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Vazirmatn',
      scaffoldBackgroundColor: colors.background,
      colorScheme: _schemeFrom(colors, brightness),
      textTheme: RitmoTypography.textTheme(colors),
      extensions: <ThemeExtension<dynamic>>[
        colors,
        RitmoBehavior(reduceTransparency: reduceTransparency),
      ],
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.card),
          side: isDark
              ? BorderSide(color: colors.border, width: RitmoElevation.borderWidthDark)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSunken,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.field),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.field),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.field),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.field),
          borderSide: BorderSide(color: colors.disabled.withValues(alpha: 0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSunken,
        disabledColor: colors.disabled,
        selectedColor: colors.primaryContainer,
        secondarySelectedColor: colors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
        secondaryLabelStyle: TextStyle(color: colors.onPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
        brightness: brightness,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(RitmoRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RitmoRadius.field),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Vazirmatn'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontFamily: 'Vazirmatn'),
      ),
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: 24,
      ),
    );
  }

  static ColorScheme _schemeFrom(RitmoColors colors, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.accent,
        onSecondary: colors.textOnColor,
        secondaryContainer: colors.accentContainer,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceSunken,
        error: colors.error,
        onError: colors.textOnColor,
        outline: colors.border,
        outlineVariant: colors.divider,
      );
    }
    return ColorScheme.light(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.accent,
      onSecondary: colors.textOnColor,
      secondaryContainer: colors.accentContainer,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceSunken,
      error: colors.error,
      onError: colors.textOnColor,
      outline: colors.border,
      outlineVariant: colors.divider,
    );
  }

  /// گرادیان پس‌زمینه زمان‌محور: از توکن پالت فعال تغذیه می‌کند
  static List<Color> timeAwareGradient(Brightness brightness, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      if (hour >= 5 && hour < 9) {
        return const [Color(0xff060C0E), Color(0xff101D21)];
      } else if (hour >= 9 && hour < 17) {
        return const [Color(0xff0B0C10), Color(0xff161A22)];
      } else if (hour >= 17 && hour < 21) {
        return const [Color(0xff080B12), Color(0xff121824)];
      }
      return const [Color(0xff040407), Color(0xff0D0C15)];
    }

    if (hour >= 5 && hour < 9) {
      return const [Color(0xffF1F4FA), Color(0xffF8F6FC)];
    } else if (hour >= 9 && hour < 17) {
      return const [Color(0xffF4F6FB), Color(0xffFAF8F5)];
    } else if (hour >= 17 && hour < 21) {
      return const [Color(0xffF6F4FA), Color(0xffFCF6F2)];
    }
    return const [Color(0xffF0F2F9), Color(0xffF6F5FA)];
  }

  static Widget buildBackgroundContainer({
    required BuildContext context,
    required Widget child,
  }) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: timeAwareGradient(brightness),
        ),
      ),
      child: child,
    );
  }

  static Widget glassCard({
    required Widget child,
    double blurSigma = 10.0,
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return RitmoGlassCard(
      blurSigma: blurSigma,
      color: color,
      borderRadius: borderRadius,
      border: border,
      child: child,
    );
  }

  static Widget glassCardLight({
    required Widget child,
    double blurSigma = 15.0,
    double borderRadius = 24.0,
    Color? color,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return RitmoGlassCardLight(
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      color: color,
      border: border,
      shadows: shadows,
      child: child,
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final colors = context.colors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Vazirmatn'),
      prefixIcon: Icon(icon, color: colors.primary, size: 20),
      filled: true,
      fillColor: colors.surfaceSunken,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RitmoRadius.field),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RitmoRadius.field),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RitmoRadius.field),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }
}

class RitmoGlassCard extends StatelessWidget {
  const RitmoGlassCard({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.color,
    this.borderRadius,
    this.border,
  });

  final Widget child;
  final double blurSigma;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(RitmoRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? colors.glassTint,
            borderRadius: borderRadius ?? BorderRadius.circular(RitmoRadius.card),
            border: border ??
                Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.45),
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class RitmoGlassCardLight extends StatelessWidget {
  const RitmoGlassCardLight({
    super.key,
    required this.child,
    this.blurSigma = 15.0,
    this.borderRadius = 24.0,
    this.color,
    this.border,
    this.shadows,
  });

  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            (isDarkMode ? RitmoElevation.none : RitmoElevation.cardLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? colors.glassTint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

extension RitmoThemeExtension on BuildContext {
  RitmoColors get colors => Theme.of(this).extension<RitmoColors>()!;
  RitmoModuleColors get modules => colors.modules;
  RitmoBehavior get behavior =>
      Theme.of(this).extension<RitmoBehavior>() ?? const RitmoBehavior(reduceTransparency: false);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  TextTheme get t => Theme.of(this).textTheme;
}
