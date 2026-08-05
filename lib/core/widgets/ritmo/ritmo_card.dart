// Ritmo Card — کارت استاندارد اپ (سطح surface)
// جایگزین Container های کارت‌مانند با رعایت سایه در روشن و خط دور در تاریک

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoCard extends StatelessWidget {
  const RitmoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RitmoSpacing.lg),
    this.margin,
    this.borderRadius,
    this.onTap,
    this.isSelected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(RitmoRadius.card);

    final cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: isSelected ? colors.primaryContainer : colors.surface,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: isSelected
              ? colors.primary
              : (isDark ? colors.border : colors.divider),
          width: isSelected ? 1.5 : (isDark ? RitmoElevation.borderWidthDark : 0.5),
        ),
        boxShadow: isDark ? RitmoElevation.none : RitmoElevation.cardLight,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          RitmoHapticsPolicy.tap();
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
