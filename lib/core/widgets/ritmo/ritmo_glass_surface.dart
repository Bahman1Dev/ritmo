// Ritmo GlassSurface — پیاده‌سازی واحد و مرکزی سطوح شیشه‌ای Ritmo
// جایگزین RitmoGlassCard, RitmoGlassCardLight, FrostedGlassCard و _buildGlassCard

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoGlassSurface extends StatelessWidget {
  const RitmoGlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 24.0,
    this.borderRadius,
    this.padding,
    this.border,
  });

  final Widget child;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final behavior = context.behavior;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final isDark = context.isDark;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(RitmoRadius.card);

    if (behavior.reduceTransparency || highContrast) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: effectiveRadius,
          border: border ??
              Border.all(
                color: highContrast
                    ? colors.textPrimary
                    : (isDark ? colors.border : colors.divider),
                width: highContrast ? 2.0 : 1.0,
              ),
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.glassTint,
            borderRadius: effectiveRadius,
            border: border ??
                Border.all(
                  color: isDark
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
