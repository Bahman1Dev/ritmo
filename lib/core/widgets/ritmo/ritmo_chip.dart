// Ritmo Chip — چیپ/برچسب‌های فیلتر و وضعیت
// جایگزین Chip و Container های کپسولی دستی

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoChip extends StatelessWidget {
  const RitmoChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = color ?? colors.primary;

    return GestureDetector(
      onTap: () {
        RitmoHapticsPolicy.selection();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: RitmoMotion.state,
        padding: const EdgeInsets.symmetric(horizontal: RitmoSpacing.md, vertical: RitmoSpacing.xs + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.16)
              : colors.surfaceSunken,
          borderRadius: BorderRadius.circular(RitmoRadius.pill),
          border: Border.all(
            color: isSelected ? activeColor : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? activeColor : colors.textSecondary),
              const SizedBox(width: RitmoSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? activeColor : colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
