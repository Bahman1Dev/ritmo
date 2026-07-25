import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class SplitDayRange {
  const SplitDayRange({
    required this.startMinutes,
    required this.endMinutes,
    required this.titleFa,
    required this.rangeLabel,
    required this.icon,
  });

  final int startMinutes;
  final int endMinutes;
  final String titleFa;
  final String rangeLabel;
  final IconData icon;

  static const morning = SplitDayRange(
    startMinutes: 0,
    endMinutes: CalendarTokens.splitBoundaryMinutes,
    titleFa: 'صبح',
    rangeLabel: '۰۰:۰۰ – ۱۲:۰۰',
    icon: Icons.wb_twilight_rounded,
  );

  static const afternoon = SplitDayRange(
    startMinutes: CalendarTokens.splitBoundaryMinutes,
    endMinutes: 1440,
    titleFa: 'بعدازظهر',
    rangeLabel: '۱۲:۰۰ – ۲۴:۰۰',
    icon: Icons.wb_sunny_rounded,
  );
}

class TimelineColumnHeader extends StatelessWidget {
  const TimelineColumnHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.rangeLabel,
    required this.isActive,
  });

  final String title;
  final IconData icon;
  final String rangeLabel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: CalendarTokens.durationStandard,
      height: CalendarTokens.columnHeaderHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingM,
        vertical: CalendarTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? CalendarTokens.emerald.withValues(alpha: CalendarTokens.alphaDomainFill)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CalendarTokens.radiusCard),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: CalendarTokens.alphaCardBorder),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CalendarTokens.spacingXs + 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? CalendarTokens.emerald.withValues(alpha: CalendarTokens.alphaDomainActive)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? CalendarTokens.emerald : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: CalendarTokens.spacingS),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                    color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  toPersianDigits(rangeLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: CalendarTokens.textLabel,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
