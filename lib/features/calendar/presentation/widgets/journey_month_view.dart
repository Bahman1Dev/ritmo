import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

    // RTL Weekday headers order: ج · پ · چ · س · د · ی · ش (Right to Left)
    const weekHeadersRtl = ['ج', 'پ', 'چ', 'س', 'د', 'ی', 'ش'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(CalendarTokens.spacingL),
        child: Column(
          children: [
            // Weekday Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekHeadersRtl.map((h) {
                return Expanded(
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: CalendarTokens.textLabel,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: CalendarTokens.spacingS),

            // Month Grid Cells
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.85,
                ),
                itemCount: gridDays.length,
                itemBuilder: (context, index) {
                  final day = gridDays[index];
                  final jDay = Jalali.fromDateTime(day);
                  final isCurrentMonth = jDay.year == jalaliSelected.year && jDay.month == jalaliSelected.month;
                  final isSelected = _isSameDay(day, selectedDate);
                  final isToday = _isSameDay(day, now);

                  final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final snapshot = rangeSnapshots[dateKey];
                  final totalItems = snapshot?.items.length ?? 0;

                  final dayNumStr = toPersianDigits(jDay.day.toString());

                  final dotCount = totalItems == 0 ? 0 : (totalItems <= 2 ? 1 : (totalItems <= 4 ? 2 : 3));

                  return InkWell(
                    onTap: () => onSelectDate(day),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12)
                            : (isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : (isCurrentMonth
                                    ? (isDark
                                        ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
                                        : theme.cardColor)
                                    : Colors.transparent)),
                        borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isToday
                                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Day Number with Today Circle
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: isToday
                                ? BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(
                              dayNumStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Vazirmatn',
                                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? theme.colorScheme.onPrimary
                                    : (isCurrentMonth
                                        ? (isSelected
                                            ? theme.colorScheme.primary
                                            : theme.textTheme.bodyMedium?.color)
                                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.20)),
                              ),
                            ),
                          ),

                          // Activity Density Dots (1..3 dots)
                          if (dotCount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(dotCount, (i) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrentMonth
                                        ? theme.colorScheme.primary.withValues(alpha: 0.70)
                                        : theme.colorScheme.primary.withValues(alpha: 0.25),
                                  ),
                                );
                              }),
                            )
                          else
                            const SizedBox(height: 4),
                        ],
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
}
