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

    final activeGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        CalendarTokens.emerald.withValues(alpha: 0.22),
        CalendarTokens.emerald.withValues(alpha: 0.08),
      ],
    );

    final inactiveGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      ],
    );

    return AnimatedContainer(
      duration: CalendarTokens.durationStandard,
      height: CalendarTokens.columnHeaderHeight - 6.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingM,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        gradient: isActive ? activeGradient : inactiveGradient,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isActive
              ? CalendarTokens.emerald.withValues(alpha: 0.65)
              : colorScheme.outlineVariant.withValues(alpha: 0.22),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: CalendarTokens.emerald.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? CalendarTokens.emerald.withValues(alpha: 0.30)
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? CalendarTokens.emerald : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: CalendarTokens.spacingS),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                        color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CalendarTokens.emerald,
                          boxShadow: [
                            BoxShadow(
                              color: CalendarTokens.emerald,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  toPersianDigits(rangeLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: CalendarTokens.textLabel,
                    color: isActive
                        ? CalendarTokens.emerald.withValues(alpha: 0.90)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.70),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
