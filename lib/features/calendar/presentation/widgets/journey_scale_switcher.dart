import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';

class JourneyScaleSwitcher extends StatelessWidget {
  const JourneyScaleSwitcher({
    super.key,
    required this.activeScale,
    required this.onScaleChanged,
  });

  final JourneyScale activeScale;
  final ValueChanged<JourneyScale> onScaleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: JourneyScale.values.map((scale) {
            final isSelected = scale == activeScale;
            final label = _getScaleLabel(scale);

            return Semantics(
              selected: isSelected,
              label: 'نمای $label',
              child: GestureDetector(
                onTap: () => onScaleChanged(scale),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _getScaleLabel(JourneyScale scale) {
    switch (scale) {
      case JourneyScale.day:
        return 'روز';
      case JourneyScale.week:
        return 'هفته';
      case JourneyScale.month:
        return 'ماه';
      case JourneyScale.year:
        return 'سال';
    }
  }
}
