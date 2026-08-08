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

  static const double miniPxPerMin = 0.35; // ~504px total timeline height

  static const List<String> weekDayShortFa = ['ش', '۱ش', '۲ش', '۳ش', '۴ش', '۵ش', 'ج'];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    final sat = CourseScheduler.getSaturdayOfWeek(selectedDate);
    final weekDays = List.generate(7, (i) => sat.add(Duration(days: i)));

    final nowMinutes = (now.hour * 60) + now.minute;
    final nowTop = nowMinutes * miniPxPerMin;

    int weekTotal = 0;
    int weekCompleted = 0;
    for (final day in weekDays) {
      final k = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final snap = rangeSnapshots[k];
      if (snap != null) {
        weekTotal += snap.completedCount + snap.remainingCount;
        weekCompleted += snap.completedCount;
      }
    }
    final weekRatio = weekTotal > 0 ? (weekCompleted / weekTotal).clamp(0.0, 1.0) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingM,
          vertical: CalendarTokens.spacingS,
        ),
        child: Column(
          children: [
            // K27 — Weekly Progress Bar
            Padding(
              padding: const EdgeInsets.only(bottom: CalendarTokens.spacingS),
              child: Row(
                children: [
                  Text(
                    'پیشرفت هفته: ${toPersianDigits(weekCompleted)} از ${toPersianDigits(weekTotal)}',
                    style: TextStyle(
                      fontSize: CalendarTokens.textMeta,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weekRatio,
                        minHeight: 4,
                        backgroundColor: colors.border.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          weekCompleted == weekTotal && weekTotal > 0
                              ? CalendarTokens.emerald
                              : colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Week Header Row (7 mini headers)
            Row(
              children: List.generate(7, (index) {
                final day = weekDays[index];
                final isSelected = _isSameDay(day, selectedDate);
                final isToday = _isSameDay(day, now);
                final jalali = Jalali.fromDateTime(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectDate(day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : (isToday ? colors.primaryContainer : colors.surface),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isSelected ? colors.primary : (isToday ? colors.primary : colors.border),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            weekDayShortFa[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? colors.onPrimary : colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            toPersianDigits(jalali.day.toString()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? colors.onPrimary : colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // 7 Mini Timeline Columns in a Single Scroll View
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                  border: Border.all(color: colors.border),
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 1440 * miniPxPerMin,
                    child: Row(
                      children: List.generate(7, (index) {
                        final day = weekDays[index];
                        final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                        final snapshot = rangeSnapshots[dateKey];
                        final isToday = _isSameDay(day, now);
                        final isSelected = _isSameDay(day, selectedDate);

                        final timedItems = (snapshot?.items ?? []).where((i) => i.isTimed).toList();

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onSelectDate(day),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? colors.primaryContainer.withValues(alpha: 0.15) : null,
                                border: Border(
                                  left: BorderSide(color: colors.divider, width: 0.5),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Grid Hour Lines (every 3 hours)
                                  for (int h = 3; h < 24; h += 3)
                                    Positioned(
                                      top: (h * 60) * miniPxPerMin,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 0.5,
                                        color: colors.divider.withValues(alpha: 0.3),
                                      ),
                                    ),

                                  // Mini Item Blocks (Compact tier - color block only)
                                  for (final item in timedItems) _buildMiniItemBlock(context, item),

                                  // Live Now Line (drawn ONLY on today's column)
                                  if (isToday)
                                    Positioned(
                                      top: nowTop,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 1.5,
                                        color: colors.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniItemBlock(BuildContext context, AgendaItem item) {
    final colors = context.colors;
    final parts = item.timeOfDay!.split(':');
    final startM = (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    final durM = item.durationMinutes ?? 30;

    final top = startM * miniPxPerMin;
    final height = (durM * miniPxPerMin).clamp(4.0, 1440 * miniPxPerMin);

    final color = domainColor(context, item.domain);

    return Positioned(
      top: top,
      left: 1.5,
      right: 1.5,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: item.isCompleted ? colors.disabled : color,
          borderRadius: BorderRadius.circular(3.0),
        ),
      ),
    );
  }
}
