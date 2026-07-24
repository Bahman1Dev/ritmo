import 'dart:ui';
import 'package:flutter/material.dart';

/// توکن‌های فاصله‌گذاری — مضارب ۴/۸ (سند طراحی §۲)
abstract final class RitmoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// فاصله‌ی عمودی استاندارد بین کارت‌های داشبورد
  static const double section = 16;
}

/// توکن‌های رادیوس — چیپ ۱۲ · کارت ۱۶/۲۰ · شیت ۲۴ (سند طراحی §۲)
abstract final class RitmoRadius {
  static const double chip = 12;
  static const double card = 16;
  static const double cardLarge = 20;
  static const double sheet = 24;

  /// گوشه‌ی پیوسته‌ی سبک اپل (squircle) برای کارت‌های کلیدی — Liquid Glass §۱۰
  static ShapeBorder squircle(double radius, {BorderSide side = BorderSide.none}) {
    return ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius * 2.35),
      side: side,
    );
  }
}

/// توکن‌های حرکت — گذار ۲۰۰ms، فنری ملایم، احترام به Reduced Motion (a11y)
abstract final class RitmoMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = Curves.easeOutCubic;

  /// آیا کاربر کاهش حرکت را فعال کرده؟ (تنظیم سیستم)
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// مدت مؤثر با احترام به Reduced Motion
  static Duration effective(BuildContext context, [Duration base = normal]) =>
      reduceMotion(context) ? Duration.zero : base;
}

/// استایل‌های متنی استاندارد — Vazirmatn (عنوان بزرگ ۲۸ · عنوان کارت ۱۸ · بدنه ۱۵ · فرعی ۱۳ · هیرو ۴۴)
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
      );

  static TextStyle cardTitle(Color color) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: 'Vazirmatn',
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 15,
        color: color,
        fontFamily: 'Vazirmatn',
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 13,
        color: color,
        fontFamily: 'Vazirmatn',
      );
}

@immutable
class RitmoColors extends ThemeExtension<RitmoColors> {

  const RitmoColors({
    required this.bg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.success,
    required this.warning,
    required this.medicalRed,
    required this.border,
    required this.energyGradient,
    required this.goldAccent,
    required this.goldGradient,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.cardBorder,
    required this.inputBackground,
    required this.glassBorder,
    required this.sectionTitle,
    required this.warningText,
    required this.successText,
    required this.cardFill,
    required this.sheetBackground,
    required this.iconSecondary,
    required this.shadowColor,
  });
  final Color bg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color success;
  final Color warning;
  final Color medicalRed;
  final Color border;
  final List<Color> energyGradient;
  final Color goldAccent;
  final List<Color> goldGradient;
  
  // Theme Tokens
  final Color cardTitle;
  final Color cardSubtitle;
  final Color cardBorder;
  final Color inputBackground;
  final Color glassBorder;
  final Color sectionTitle;
  final Color warningText;
  final Color successText;
  final Color cardFill;
  final Color sheetBackground;
  final Color iconSecondary;
  final Color shadowColor;

  Color get onSurface => textPrimary;
  Color get onSurfaceVariant => textSecondary;
  Color get surfaceVariant => cardFill;
  Color get outlineVariant => border;
  Color get secondary => primary;
  Color get surface => card;
  Color get background => bg;
  Color get onBackground => textPrimary;

  @override
  RitmoColors copyWith({
    Color? bg,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? success,
    Color? warning,
    Color? medicalRed,
    Color? border,
    List<Color>? energyGradient,
    Color? goldAccent,
    List<Color>? goldGradient,
    Color? cardTitle,
    Color? cardSubtitle,
    Color? cardBorder,
    Color? inputBackground,
    Color? glassBorder,
    Color? sectionTitle,
    Color? warningText,
    Color? successText,
    Color? cardFill,
    Color? sheetBackground,
    Color? iconSecondary,
    Color? shadowColor,
  }) {
    return RitmoColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      medicalRed: medicalRed ?? this.medicalRed,
      border: border ?? this.border,
      energyGradient: energyGradient ?? this.energyGradient,
      goldAccent: goldAccent ?? this.goldAccent,
      goldGradient: goldGradient ?? this.goldGradient,
      cardTitle: cardTitle ?? this.cardTitle,
      cardSubtitle: cardSubtitle ?? this.cardSubtitle,
      cardBorder: cardBorder ?? this.cardBorder,
      inputBackground: inputBackground ?? this.inputBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      warningText: warningText ?? this.warningText,
      successText: successText ?? this.successText,
      cardFill: cardFill ?? this.cardFill,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  RitmoColors lerp(ThemeExtension<RitmoColors>? other, double t) {
    if (other is! RitmoColors) return this;
    return RitmoColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      medicalRed: Color.lerp(medicalRed, other.medicalRed, t)!,
      border: Color.lerp(border, other.border, t)!,
      energyGradient: t < 0.5 ? energyGradient : other.energyGradient,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t)!,
      goldGradient: t < 0.5 ? goldGradient : other.goldGradient,
      cardTitle: Color.lerp(cardTitle, other.cardTitle, t)!,
      cardSubtitle: Color.lerp(cardSubtitle, other.cardSubtitle, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      sectionTitle: Color.lerp(sectionTitle, other.sectionTitle, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      sheetBackground: Color.lerp(sheetBackground, other.sheetBackground, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }

  // Light Theme Instance
  static const light = RitmoColors(
    bg: Color(0xffF2F3F8),
    card: Color(0xffFFFFFF),
    textPrimary: Color(0xff0F172A),
    textSecondary: Color(0xff475569),
    primary: Color(0xff6366F1),
    success: Color(0xff10B981),
    warning: Color(0xffF59E0B),
    medicalRed: Color(0xffEF4444),
    border: Color(0x0f000000),
    energyGradient: [
      Color(0xff5B8AF5),
      Color(0xff9B89FF),
    ],
    goldAccent: Color(0xffD4A843),
    goldGradient: [
      Color(0xffE5BA5A),
      Color(0xffD4A843),
    ],
    cardTitle: Color(0xff0F172A),
    cardSubtitle: Color(0xff475569),
    cardBorder: Color(0x0f000000),
    inputBackground: Color(0xffF8FAFC),
    glassBorder: Color(0x0f000000),
    sectionTitle: Color(0xff0F172A),
    warningText: Color(0xffEA580C),
    successText: Color(0xff16A34A),
    cardFill: Color(0x08000000),
    sheetBackground: Color(0xffFFFFFF),
    iconSecondary: Color(0xff475569),
    shadowColor: Color(0x0a000000),
  );

  // Dark Theme Instance
  static const dark = RitmoColors(
    bg: Color(0xff08090C),
    card: Color(0xff111319),
    textPrimary: Color(0xffECEEF3),
    textSecondary: Color(0xff9AA0AE),
    primary: Color(0xff5B8AF5),
    success: Color(0xff34D399),
    warning: Color(0xffF5B95B),
    medicalRed: Color(0xffE5736B),
    border: Color(0xff1C1E24),
    energyGradient: [
      Color(0xff6B9EFF),
      Color(0xff9B89FF),
    ],
    goldAccent: Color(0xffE5BA5A),
    goldGradient: [
      Color(0xffF5B95B),
      Color(0xffE5BA5A),
    ],
    cardTitle: Color(0xffFFFFFF),
    cardSubtitle: Color(0xffECEEF3),
    cardBorder: Color(0xff1C1E24),
    inputBackground: Color(0x0affffff),
    glassBorder: Color(0x14ffffff),
    sectionTitle: Color(0xffFFFFFF),
    warningText: Color(0xffF5B95B),
    successText: Color(0xff34D399),
    cardFill: Color(0x0affffff),
    sheetBackground: Color(0xff0E1015),
    iconSecondary: Color(0xffECEEF3),
    shadowColor: Color(0x66000000),
  );
}

class RitmoTheme {
  static const Color primaryBg = Color(0xFF0F172A);
  static const Color accent = Color(0xFF38BDF8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RitmoColors.dark.bg,
      cardColor: RitmoColors.dark.card,
      primaryColor: RitmoColors.dark.primary,
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: RitmoColors.dark.textPrimary),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RitmoColors.dark.textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: RitmoColors.dark.textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: RitmoColors.dark.textSecondary),
      ),
      colorScheme: ColorScheme.dark(
        primary: RitmoColors.dark.primary,
        surface: RitmoColors.dark.card,
        error: RitmoColors.dark.medicalRed,
        onPrimary: Colors.white,
        onSurface: RitmoColors.dark.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: RitmoColors.dark.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xff2C3147)),
        ),
        elevation: 0,
      ),
      extensions: const [
        RitmoColors.dark,
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: RitmoColors.light.bg,
      cardColor: RitmoColors.light.card,
      primaryColor: RitmoColors.light.primary,
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: RitmoColors.light.textPrimary),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RitmoColors.light.textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: RitmoColors.light.textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: RitmoColors.light.textSecondary),
      ),
      colorScheme: ColorScheme.light(
        primary: RitmoColors.light.primary,
        surface: RitmoColors.light.card,
        error: RitmoColors.light.medicalRed,
        onSurface: RitmoColors.light.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: RitmoColors.light.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x0f000000)),
        ),
        elevation: 0,
      ),
      extensions: const [
        RitmoColors.light,
      ],
    );
  }

  /// گرادیان پس‌زمینه‌ی زمان‌محور: رنگ‌مایه با ساعت روز به‌آرامی تغییر می‌کند
  /// (سحر/روز/غروب/شب) — بدون انیمیشن دائمی، فقط انتخاب پالت هنگام build.
  static List<Color> timeAwareGradient(Brightness brightness, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      if (hour >= 5 && hour < 9) {
        // سحرگاه: شفق قطبی تیره با تن مایل به آبی-سبز ملایم (Teal slate)
        return const [Color(0xff060C0E), Color(0xff101D21)];
      } else if (hour >= 9 && hour < 17) {
        // روز: گرافیتی مدرن و فضای عمیق خنثی (Deep Graphite)
        return const [Color(0xff0B0C10), Color(0xff161A22)];
      } else if (hour >= 17 && hour < 21) {
        // غروب: سرمه‌ای-خاکستری ملایم و تیره (Twilight Slate Blue)
        return const [Color(0xff080B12), Color(0xff121824)];
      }
      // شب: مشکی مخملی عمیق با هاله بسیار ملایم کیهانی (Velvet Cosmic Indigo)
      return const [Color(0xff040407), Color(0xff0D0C15)];
    }

    if (hour >= 5 && hour < 9) {
      // سحرگاه: سفید سحری ملایم
      return const [Color(0xffF1F4FA), Color(0xffF8F6FC)];
    } else if (hour >= 9 && hour < 17) {
      // روز: سفید و خنثی با هاله گرم
      return const [Color(0xffF4F6FB), Color(0xffFAF8F5)];
    } else if (hour >= 17 && hour < 21) {
      // غروب: سفید صورتی ملایم
      return const [Color(0xffF6F4FA), Color(0xffFCF6F2)];
    }
    // شب: سفید خاکستری آرام
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
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: colors.primary, size: 20),
      filled: true,
      fillColor: colors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
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
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? colors.card.withValues(alpha: 0.4),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border ?? Border.all(
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.04 : 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? (isDarkMode ? Colors.black.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.65)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
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
  RitmoColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return Theme.of(this).extension<RitmoColors>() ?? (isDark ? RitmoColors.dark : RitmoColors.light);
  }
}
