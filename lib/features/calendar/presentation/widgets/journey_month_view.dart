import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:shamsi_date/shamsi_date.dart';

class JourneyMonthView extends StatelessWidget {
  const JourneyMonthView({
    super.key,
    required this.selectedDate,
    required this.rangeSnapshots,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final Map<String, DayAgendaSnapshot> rangeSnapshots;
  final ValueChanged<DateTime> onSelectDate;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    final jalaliSelected = Jalali.fromDateTime(selectedDate);
    final jalaliFirst = Jalali(jalaliSelected.year, jalaliSelected.month, 1);
    final monthLength = jalaliFirst.monthLength;

    final firstOfMonthDate = jalaliFirst.toDateTime();
    final lastOfMonthDate = Jalali(jalaliSelected.year, jalaliSelected.month, monthLength).toDateTime();

    final firstGridDay = CourseScheduler.getSaturdayOfWeek(firstOfMonthDate);
    final totalDays = lastOfMonthDate.difference(firstGridDay).inDays + 1;
    final gridDayCount = (totalDays / 7).ceil() * 7;

    final gridDays = List.generate(gridDayCount, (i) => firstGridDay.add(Duration(days: i)));

    // RTL Weekday headers order
    const weekHeadersRtl = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(CalendarTokens.spacingL),
        child: Column(
          children: [
            // Weekday Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (idx) {
                final isFridayHeader = idx == 6;
                return Expanded(
                  child: Text(
                    weekHeadersRtl[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: CalendarTokens.textLabel,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                      color: isFridayHeader ? colors.error : colors.textSecondary,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: CalendarTokens.spacingS),

            // Month Grid Cells
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.82,
                ),
                itemCount: gridDays.length,
                itemBuilder: (context, index) {
                  final day = gridDays[index];
                  final jDay = Jalali.fromDateTime(day);
                  final isCurrentMonth = jDay.year == jalaliSelected.year && jDay.month == jalaliSelected.month;
                  final isSelected = _isSameDay(day, selectedDate);
                  final isToday = _isSameDay(day, now);
                  final isFriday = index % 7 == 6; // Friday is 7th column

                  final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final snapshot = rangeSnapshots[dateKey];
                  final items = snapshot?.items ?? [];
                  final overload = snapshot?.overloadScore ?? 0.0;
                  final hasConflicts = (snapshot?.conflicts.length ?? 0) > 0;

                  // Unique domain colors (up to 4, includes task)
                  final presentDomains = <AgendaDomain>{};
                  for (final item in items) {
                    presentDomains.add(item.domain);
                    if (presentDomains.length >= 4) break;
                  }

                  // K26: 3-step Workload Heatmap Tint
                  double tintAlpha = 0.0;
                  if (isCurrentMonth) {
                    if (overload > 0.6) {
                      tintAlpha = 0.22; // heavy
                    } else if (overload > 0.2) {
                      tintAlpha = 0.12; // normal
                    } else if (items.isNotEmpty) {
                      tintAlpha = 0.05; // light
                    }
                  }

                  final cellBgColor = isSelected
                      ? colors.primaryContainer
                      : (tintAlpha > 0
                          ? colors.primary.withValues(alpha: tintAlpha)
                          : (isCurrentMonth ? colors.surface : colors.surfaceSunken));

                  final dayNumStr = toPersianDigits(jDay.day.toString());

                  return InkWell(
                    onTap: () => onSelectDate(day),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellBgColor,
                        borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                        border: isToday
                            ? Border.all(color: colors.primary, width: 1.5)
                            : (isSelected ? Border.all(color: colors.primary, width: 1.0) : null),
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Day Number + Holiday Dot Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isFriday)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 3, top: 3),
                                  decoration: BoxDecoration(
                                    color: colors.error,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 2, top: 2),
                                child: Text(
                                  dayNumStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday || isSelected || isFriday ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentMonth
                                        ? (isSelected
                                            ? colors.primary
                                            : (isFriday ? colors.error : colors.textPrimary))
                                        : colors.disabled,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Domain Dots (up to 4)
                          if (presentDomains.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: presentDomains.map((d) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                  decoration: BoxDecoration(
                                    color: domainColor(context, d),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),

                          // Conflict Underline
                          if (hasConflicts)
                            Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: colors.warning,
                            )
                          else
                            const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // K26: Workload Legend Row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WorkloadLegendDot(color: colors.primary.withValues(alpha: 0.05), label: 'سبک'),
                  const SizedBox(width: 16),
                  _WorkloadLegendDot(color: colors.primary.withValues(alpha: 0.12), label: 'عادی'),
                  const SizedBox(width: 16),
                  _WorkloadLegendDot(color: colors.primary.withValues(alpha: 0.22), label: 'شلوغ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkloadLegendDot extends StatelessWidget {
  const _WorkloadLegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: CalendarTokens.textLabel,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}
