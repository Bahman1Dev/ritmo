import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:shamsi_date/shamsi_date.dart';

class JourneyYearView extends StatelessWidget {
  const JourneyYearView({
    super.key,
    required this.selectedDate,
    required this.rangeSnapshots,
    required this.onSelectMonth,
  });

  final DateTime selectedDate;
  final Map<String, DayAgendaSnapshot> rangeSnapshots;
  final ValueChanged<DateTime> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final jalaliSelected = Jalali.fromDateTime(selectedDate);
    final jalaliYear = jalaliSelected.year;
    final jalaliYearStr = toPersianDigits(jalaliYear.toString());
    final jalaliNow = Jalali.fromDateTime(now);

    const jalaliMonthNames = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];

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
                Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: CalendarTokens.spacingS),
                Text(
                  'نمای سال $jalaliYearStr',
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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthNumber = index + 1;
                  final monthDate = Jalali(jalaliYear, monthNumber, 1).toDateTime();

                  final isSelectedMonth = jalaliSelected.year == jalaliYear && jalaliSelected.month == monthNumber;
                  final isCurrentMonth = jalaliNow.year == jalaliYear && jalaliNow.month == monthNumber;

                  int monthTaskCount = 0;
                  int monthCompletedCount = 0;

                  for (final entry in rangeSnapshots.entries) {
                    final dt = DateTime.tryParse(entry.key);
                    if (dt != null) {
                      final j = Jalali.fromDateTime(dt);
                      if (j.year == jalaliYear && j.month == monthNumber) {
                        monthTaskCount += entry.value.items.length;
                        monthCompletedCount += entry.value.completedCount;
                      }
                    }
                  }

                  final progressRatio = monthTaskCount > 0
                      ? (monthCompletedCount / monthTaskCount).clamp(0.0, 1.0)
                      : 0.0;

                  return InkWell(
                    onTap: () => onSelectMonth(monthDate),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.all(CalendarTokens.spacingM),
                      decoration: BoxDecoration(
                        color: isSelectedMonth
                            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                            : (isCurrentMonth
                                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                                : (isDark
                                    ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.40)
                                    : theme.cardColor)),
                        borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                        border: Border.all(
                          color: isSelectedMonth
                              ? theme.colorScheme.primary
                              : (isCurrentMonth
                                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder)),
                          width: isSelectedMonth ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                jalaliMonthNames[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                  color: isCurrentMonth || isSelectedMonth
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (isCurrentMonth)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                monthTaskCount > 0
                                    ? '${toPersianDigits((progressRatio * 100).round())}٪'
                                    : '—',
                                style: TextStyle(
                                  fontSize: CalendarTokens.textMeta,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Vazirmatn',
                                  color: monthTaskCount > 0
                                      ? (isCurrentMonth || isSelectedMonth
                                          ? theme.colorScheme.primary
                                          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.70))
                                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.30),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: monthTaskCount > 0 ? progressRatio : 0.0,
                                  minHeight: 3,
                                  backgroundColor: theme.dividerColor.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    monthTaskCount == 0
                                        ? theme.disabledColor
                                        : (monthCompletedCount == monthTaskCount
                                            ? CalendarTokens.emerald
                                            : theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
