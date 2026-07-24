import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class JourneySummarySection extends StatelessWidget {
  const JourneySummarySection({
    super.key,
    required this.snapshot,
    this.onSelectActivity,
  });

  final DayAgendaSnapshot snapshot;
  final ValueChanged<AgendaItem>? onSelectActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: CalendarTokens.spacingS),
              Text(
                'خلاصه روز (${toPersianDigits(snapshot.dateStr)})',
                style: const TextStyle(
                  fontSize: CalendarTokens.textTitle,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: CalendarTokens.spacingM),

          // 3 Metric Tiles Row
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'تکمیل‌شده',
                  value: toPersianDigits('${snapshot.completedCount}'),
                  icon: Icons.task_alt_rounded,
                  color: CalendarTokens.emerald,
                ),
              ),
              const SizedBox(width: CalendarTokens.spacingS),
              Expanded(
                child: _MetricCard(
                  label: 'باقی‌مانده',
                  value: toPersianDigits('${snapshot.remainingCount}'),
                  icon: Icons.pending_actions_rounded,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: CalendarTokens.spacingS),
              Expanded(
                child: _MetricCard(
                  label: 'زمان آزاد',
                  value: toPersianDigits('${snapshot.freeGaps.length}'),
                  icon: Icons.event_available_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: CalendarTokens.spacingL),

          // Spotlight rows for Current / Next activity
          if (snapshot.currentActivity != null) ...[
            _SpotlightActivityCard(
              label: 'فعالیت جاری',
              item: snapshot.currentActivity!,
              accentColor: theme.colorScheme.primary,
              isCurrent: true,
              onTap: () => onSelectActivity?.call(snapshot.currentActivity!),
            ),
            const SizedBox(height: CalendarTokens.spacingS),
          ],
          if (snapshot.nextActivity != null) ...[
            _SpotlightActivityCard(
              label: 'فعالیت بعدی',
              item: snapshot.nextActivity!,
              accentColor: Colors.amber.shade800,
              isCurrent: false,
              onTap: () => onSelectActivity?.call(snapshot.nextActivity!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(CalendarTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: CalendarTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazirmatn',
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: CalendarTokens.textLabel,
              fontFamily: 'Vazirmatn',
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightActivityCard extends StatelessWidget {
  const _SpotlightActivityCard({
    required this.label,
    required this.item,
    required this.accentColor,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final AgendaItem item;
  final Color accentColor;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(CalendarTokens.spacingM),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
            const SizedBox(width: CalendarTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: CalendarTokens.textLabel,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: CalendarTokens.textBody,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
