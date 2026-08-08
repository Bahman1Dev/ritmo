import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// Central Design System tokens for Ritmo Calendar UI.
/// لایه نگاشت توکن‌های تقویم به سیستم توکن مرکزی Ritmo
class CalendarTokens {
  const CalendarTokens._();

  // Colors
  static const Color emerald = Color(0xFF10B981);
  static Color getEmerald(BuildContext context) => context.modules.planner;

  // Corner Radii mapped to RitmoRadius
  static const double radiusCard = RitmoRadius.card;
  static const double radiusSheet = RitmoRadius.sheet;
  static const double radiusSegment = RitmoRadius.field;
  static const double radiusSegPill = RitmoRadius.iconButton;
  static const double radiusPill = RitmoRadius.pill;
  static const double radiusBadge = RitmoRadius.badge;

  // Spacing Rhythm mapped to RitmoSpacing
  static const double spacingXs = RitmoSpacing.xs;
  static const double spacingS = RitmoSpacing.sm;
  static const double spacingM = RitmoSpacing.md;
  static const double spacingL = RitmoSpacing.lg;
  static const double spacingXl = 20.0;
  static const double spacing2xl = RitmoSpacing.xl;
  static const double spacing3xl = RitmoSpacing.xxl;

  // Surface Opacities
  static const double alphaDomainFill = 0.10;
  static const double alphaDomainActive = 0.16;
  static const double alphaCurrentTime = 0.12;
  static const double alphaPastDim = 0.04;
  static const double alphaCardBorder = 0.08;

  // Timeline Geometry (Keep layout geometry intact)
  static const double pxPerMinute = 1.2;
  static const double hourAxisWidth = 44.0;
  static const double accentBarWidth = 3.0;
  static const double nowLineThickness = 2.0;

  // ─── Registry Screen Tokens ───
  static const double radiusCardLg = RitmoRadius.hero;
  static const double registryCardHeight = 92.0;
  static const double registryCardGap = 10.0;
  static const double iconContainerSize = 40.0;
  static const double iconContainerRadius = 12.0;
  static const double searchBarHeight = 48.0;
  static const double chipHeight = 36.0;
  static const double fabHeight = 54.0;
  static const double fabRadius = 18.0;

  // ─── Split Day Layout ───
  static const int splitBoundaryMinutes = 720;
  static const double pxPerMinuteSplit = 1.6;
  static const double hourAxisWidthSplit = 40.0;
  static const double columnGap = 12.0;
  static const int maxLanesSplit = 2;
  static const double splitMinScreenWidth = 340.0;
  static const double columnHeaderHeight = 62.0;
  static const double textTitleSplit = 13.0;
  static const double textMetaSplit = 10.0;

  // Motion Parameters
  static const Duration durationMicro = RitmoMotion.press;
  static const Duration durationStandard = RitmoMotion.state;
  static const Duration durationEmphasis = RitmoMotion.sheet;
  static const Curve curveDefault = RitmoMotion.enter;
  static const Curve curveEmphasis = RitmoMotion.enter;

  // Typography Sizes
  static const double textHero = 26.0;
  static const double textTitle = 15.0;
  static const double textBody = 14.0;
  static const double textMeta = 12.0;
  static const double textLabel = 11.0;
  static const double textSection = 13.0;

  // ─── Agenda View ───
  /// Fixed row height for agenda list items — prevents scroll jitter
  static const double agendaRowHeight = 52.0;
  static const double agendaBucketHeaderHeight = 36.0;
}
