import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class JourneyScaleSwitcher extends StatelessWidget {
  const JourneyScaleSwitcher({
    super.key,
    required this.activeScale,
    required this.onScaleChanged,
  });

  final JourneyScale activeScale;
  final ValueChanged<JourneyScale> onScaleChanged;

  static const List<JourneyScale> _scalesInRtlOrder = [
    JourneyScale.day,
    JourneyScale.week,
    JourneyScale.month,
    JourneyScale.year,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(CalendarTokens.spacingXs),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
          ),
        ),
        child: Row(
          children: _scalesInRtlOrder.map((scale) {
            final isSelected = scale == activeScale;
            final label = _getScaleLabel(scale);

            return Expanded(
              child: Semantics(
                selected: isSelected,
                label: 'نمای $label',
                button: true,
                child: GestureDetector(
                  onTap: () => onScaleChanged(scale),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: CalendarTokens.durationStandard,
                    curve: CalendarTokens.curveEmphasis,
                    height: 40.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? theme.colorScheme.surfaceContainerHigh : theme.cardColor)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(CalendarTokens.radiusSegPill),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                        fontFamily: 'Vazirmatn',
                      ),
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
