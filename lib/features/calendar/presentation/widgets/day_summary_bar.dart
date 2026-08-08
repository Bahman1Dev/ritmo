import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

/// K24 — Day summary bar: single line above timeline with 3 numbers derived from snapshot.
/// - remainingCount ("مانده")
/// - completedCount ("انجام‌شده")
/// - free time derived from freeGaps sum ("وقت آزاد")
class DaySummaryBar extends StatelessWidget {
  const DaySummaryBar({
    super.key,
    required this.snapshot,
    required this.onTapFreeGaps,
  });

  final DayAgendaSnapshot snapshot;
  final VoidCallback onTapFreeGaps;

  int get _freeMinutes {
    int total = 0;
    for (final gap in snapshot.freeGaps) {
      total += gap.durationMinutes;
    }
    return total;
  }

  String _formatFreeTime(int totalMinutes) {
    if (totalMinutes <= 0) return '۰ دقیقه';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${toPersianDigits(hours)} ساعت و ${toPersianDigits(mins)} دقیقه';
    } else if (hours > 0) {
      return '${toPersianDigits(hours)} ساعت';
    } else {
      return '${toPersianDigits(mins)} دقیقه';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingXl,
        vertical: CalendarTokens.spacingXs + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Remaining count
          _SummaryChip(
            label: 'مانده: ${toPersianDigits(snapshot.remainingCount)}',
            color: theme.colorScheme.primary,
          ),

          // Completed count
          _SummaryChip(
            label: 'انجام‌شده: ${toPersianDigits(snapshot.completedCount)}',
            color: CalendarTokens.emerald,
          ),

          // Free time (tappable)
          InkWell(
            onTap: onTapFreeGaps,
            borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 13,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Text(
                    'آزاد: ${_formatFreeTime(_freeMinutes)}',
                    style: TextStyle(
                      fontSize: CalendarTokens.textMeta,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: CalendarTokens.textMeta,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Vazirmatn',
        ),
      ),
    );
  }
}
