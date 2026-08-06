import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
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
              children: weekHeadersRtl.map((h) {
                return Expanded(
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: CalendarTokens.textLabel,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                      color: colors.textSecondary,
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
                  childAspectRatio: 0.82,
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
                  final items = snapshot?.items ?? [];
                  final overload = snapshot?.overloadScore ?? 0.0;
                  final hasConflicts = (snapshot?.conflicts.length ?? 0) > 0;

                  // Unique domain colors (up to 4)
                  final presentDomains = <AgendaDomain>{};
                  for (final item in items) {
                    presentDomains.add(item.domain);
                    if (presentDomains.length >= 4) break;
                  }

                  final tintAlpha = isCurrentMonth ? (overload.clamp(0.0, 1.0) * 0.22) : 0.0;
                  final cellBgColor = isSelected
                      ? colors.primaryContainer
                      : (tintAlpha > 0
                          ? colors.primary.withValues(alpha: tintAlpha)
                          : (isCurrentMonth ? colors.surface : colors.sunken));

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
                          // Day Number
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2, top: 2),
                              child: Text(
                                dayNumStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentMonth
                                      ? (isSelected ? colors.primary : colors.textPrimary)
                                      : colors.disabled,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
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
          ],
        ),
      ),
    );
  }
}
