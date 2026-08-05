// Ritmo SegmentedControl — نوار انتخاب چندگزینه‌ای متصل به سیستم توکن
// جایگزین تب‌ها و کلیدهای داینامیک دستی

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoSegmentedControl<T> extends StatelessWidget {
  const RitmoSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(RitmoRadius.field),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: segments.entries.map((entry) {
          final isSelected = entry.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                RitmoHapticsPolicy.selection();
                onSelected(entry.key);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: RitmoMotion.state,
                curve: RitmoMotion.enter,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(RitmoRadius.field - 2),
                  boxShadow: isSelected && !context.isDark ? RitmoElevation.cardLight : RitmoElevation.none,
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
