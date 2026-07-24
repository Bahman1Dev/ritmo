import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class TimelineUntimedSection extends StatelessWidget {
  const TimelineUntimedSection({
    super.key,
    required this.untimedItems,
    this.onItemTap,
  });

  final List<AgendaItem> untimedItems;
  final ValueChanged<AgendaItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (untimedItems.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingL,
          vertical: CalendarTokens.spacingS,
        ),
        padding: const EdgeInsets.all(CalendarTokens.spacingM),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.60)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: CalendarTokens.spacingS),
                Text(
                  'بدون زمانبندی (${toPersianDigits(untimedItems.length.toString())})',
                  style: TextStyle(
                    fontSize: CalendarTokens.textMeta,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: CalendarTokens.spacingS),
            Wrap(
              spacing: CalendarTokens.spacingS,
              runSpacing: CalendarTokens.spacingS,
              children: untimedItems.map((item) {
                final isDone = item.isCompleted;
                final domainColor = _getDomainColor(item.domain);

                return InkWell(
                  onTap: () => onItemTap?.call(item),
                  borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: isDone
                          ? theme.disabledColor.withValues(alpha: 0.12)
                          : domainColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                      border: Border.all(
                        color: domainColor.withValues(alpha: isDone ? 0.2 : 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? theme.disabledColor
                                : domainColor,
                          ),
                        ),
                        const SizedBox(width: CalendarTokens.spacingXs),
                        if (isDone)
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: CalendarTokens.textMeta,
                            fontWeight: isDone ? FontWeight.w400 : FontWeight.w600,
                            color: isDone
                                ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45)
                                : theme.textTheme.bodyLarge?.color,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getDomainColor(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return Colors.teal;
      case AgendaDomain.prayer:
        return Colors.indigo;
      case AgendaDomain.mustahab:
        return Colors.blueGrey;
      case AgendaDomain.course:
        return Colors.amber.shade800;
      case AgendaDomain.goalStep:
        return Colors.deepPurple;
      case AgendaDomain.konkur:
        return Colors.red;
      case AgendaDomain.cycle:
        return Colors.pink;
      case AgendaDomain.worshipDebt:
        return Colors.brown;
      case AgendaDomain.sport:
        return Colors.green;
      case AgendaDomain.medicine:
        return Colors.orange.shade800;
    }
  }
}
