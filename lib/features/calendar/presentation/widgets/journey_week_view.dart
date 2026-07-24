import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:shamsi_date/shamsi_date.dart';

class JourneyWeekView extends StatelessWidget {
  const JourneyWeekView({
    super.key,
    required this.selectedDate,
    required this.rangeSnapshots,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final Map<String, DayAgendaSnapshot> rangeSnapshots;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sat = CourseScheduler.getSaturdayOfWeek(selectedDate);
    final weekDays = List.generate(7, (i) => sat.add(Duration(days: i)));
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingL,
          vertical: CalendarTokens.spacingS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: CalendarTokens.spacingS),
                Text(
                  'برنامه هفتگی',
                  style: TextStyle(
                    fontSize: CalendarTokens.textTitle,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: CalendarTokens.spacingM),
            Expanded(
              child: ListView.separated(
                itemCount: weekDays.length,
                separatorBuilder: (context, index) => const SizedBox(height: CalendarTokens.spacingS),
                itemBuilder: (context, index) {
                  final day = weekDays[index];
                  final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final snapshot = rangeSnapshots[dateKey];

                  final isSelected = _isSameDay(day, selectedDate);
                  final isToday = _isSameDay(day, now);

                  final items = snapshot?.items ?? [];
                  final completedCount = snapshot?.completedCount ?? 0;
                  final totalCount = items.length;
                  final rhythmScore = snapshot?.rhythmScore ?? 0;
                  final progressRatio = totalCount > 0 ? (completedCount / totalCount) : 0.0;

                  final jalali = Jalali.fromDateTime(day);
                  final dayNumStr = toPersianDigits(jalali.day.toString());

                  return InkWell(
                    onTap: () => onSelectDate(day),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.all(CalendarTokens.spacingM),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                            : (isDark
                                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.50)
                                : theme.cardColor),
                        borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isToday
                                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                                  : theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                        child: Row(
                          children: [
                            // Right Accent Border for Today (3px) in RTL
                            if (isToday)
                              Container(
                                width: CalendarTokens.accentBarWidth,
                                height: 60,
                                color: theme.colorScheme.primary,
                              ),
                            if (isToday) const SizedBox(width: CalendarTokens.spacingS),

                            // Day Badge
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getFarsiDayName(day),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                    fontFamily: 'Vazirmatn',
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : (isSelected
                                            ? theme.colorScheme.primaryContainer
                                            : theme.dividerColor.withValues(alpha: 0.15)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    dayNumStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Vazirmatn',
                                      color: isToday
                                          ? theme.colorScheme.onPrimary
                                          : (isSelected
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.textTheme.bodyMedium?.color),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: CalendarTokens.spacingM),

                            // Content Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${toPersianDigits(totalCount.toString())} برنامه (${toPersianDigits(completedCount.toString())} تکمیل)',
                                        style: TextStyle(
                                          fontSize: CalendarTokens.textBody,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Vazirmatn',
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      if (rhythmScore > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                                          ),
                                          child: Text(
                                            'ریتم: ${toPersianDigits(rhythmScore.toString())}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Completion Mini Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progressRatio,
                                      minHeight: 3,
                                      backgroundColor: theme.dividerColor.withValues(alpha: 0.12),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        completedCount == totalCount && totalCount > 0
                                            ? CalendarTokens.emerald
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Top Activity Chips
                                  if (items.isEmpty)
                                    Text(
                                      'اطلاعاتی برای این روز ثبت نشده',
                                      style: TextStyle(
                                        fontSize: CalendarTokens.textMeta,
                                        fontFamily: 'Vazirmatn',
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.50),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: items.take(3).map((item) {
                                        final domainColor = _getDomainColor(item.domain);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: item.isCompleted
                                                ? theme.disabledColor.withValues(alpha: 0.12)
                                                : domainColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: item.isCompleted ? theme.disabledColor : domainColor,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: item.isCompleted ? FontWeight.w400 : FontWeight.w600,
                                                  fontFamily: 'Vazirmatn',
                                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 20,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.40),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _getFarsiDayName(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.saturday:
        return 'شنبه';
      case DateTime.sunday:
        return '۱شنبه';
      case DateTime.monday:
        return '۲شنبه';
      case DateTime.tuesday:
        return '۳شنبه';
      case DateTime.wednesday:
        return '۴شنبه';
      case DateTime.thursday:
        return '۵شنبه';
      case DateTime.friday:
        return 'جمعه';
      default:
        return '';
    }
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
