import 'package:flutter/material.dart';

/// Central Design System tokens for Ritmo Calendar Premium UI 2026.
class CalendarTokens {
  const CalendarTokens._();

  // Colors
  static const Color emerald = Color(0xFF10B981);

  // Corner Radii
  static const double radiusCard = 16.0;
  static const double radiusSheet = 24.0;
  static const double radiusSegment = 14.0;
  static const double radiusSegPill = 10.0;
  static const double radiusPill = 100.0;
  static const double radiusBadge = 8.0;

  // Spacing Rhythm (Multiples of 4)
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 20.0;
  static const double spacing2xl = 24.0;
  static const double spacing3xl = 32.0;

  // Surface Opacities
  static const double alphaDomainFill = 0.08;
  static const double alphaDomainActive = 0.14;
  static const double alphaCurrentTime = 0.12;
  static const double alphaPastDim = 0.04;
  static const double alphaCardBorder = 0.08;

  // Timeline Geometry
  static const double pxPerMinute = 1.2;
  static const double hourAxisWidth = 44.0;
  static const double accentBarWidth = 3.0;
  static const double nowLineThickness = 2.0;

  // ─── Split Day Layout ───
  /// مرز تقسیم روز به دو ستون (بر حسب دقیقه از نیمه‌شب). ۷۲۰ = ساعت ۱۲:۰۰
  static const int splitBoundaryMinutes = 720;
  /// ارتفاع هر دقیقه در نمای دو ستونی.
  static const double pxPerMinuteSplit = 1.0;
  /// عرض محور ساعت در نمای دو ستونی.
  static const double hourAxisWidthSplit = 36.0;
  /// فاصلهٔ بین دو ستون.
  static const double columnGap = 10.0;
  /// حداکثر تعداد لِین هم‌پوشان در هر ستون.
  static const int maxLanesSplit = 2;
  /// حداقل عرض صفحه برای نمای دو ستونی؛ کمتر از این، تک‌ستونی fallback.
  static const double splitMinScreenWidth = 340.0;
  /// ارتفاع هدر هر ستون.
  static const double columnHeaderHeight = 62.0;
  static const double textTitleSplit = 13.0;
  static const double textMetaSplit = 10.0;

  // Motion Parameters
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationStandard = Duration(milliseconds: 220);
  static const Duration durationEmphasis = Duration(milliseconds: 300);
  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveEmphasis = Curves.easeInOut;

  // Typography Sizes
  static const double textHero = 26.0;
  static const double textTitle = 15.0;
  static const double textBody = 14.0;
  static const double textMeta = 12.0;
  static const double textLabel = 11.0;
  static const double textSection = 13.0;
}
