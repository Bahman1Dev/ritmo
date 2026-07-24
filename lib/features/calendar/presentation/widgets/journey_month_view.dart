import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';

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
    final now = DateTime.now();

    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final firstGridDay = CourseScheduler.getSaturdayOfWeek(firstOfMonth);
    final totalDays = lastOfMonth.difference(firstGridDay).inDays + 1;
    final gridDayCount = (totalDays / 7).ceil() * 7;

    final gridDays = List.generate(gridDayCount, (i) => firstGridDay.add(Duration(days: i)));

    const weekHeaders = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekHeaders.map((h) {
              return Expanded(
                child: Text(
                  h,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: gridDays.length,
              itemBuilder: (context, index) {
                final day = gridDays[index];
                final isCurrentMonth = day.month == selectedDate.month;
                final isSelected = _isSameDay(day, selectedDate);
                final isToday = _isSameDay(day, now);

                final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final snapshot = rangeSnapshots[dateKey];
                final totalItems = snapshot?.items.length ?? 0;
                final completedCount = snapshot?.completedCount ?? 0;

                return InkWell(
                  onTap: () => onSelectDate(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : isToday
                              ? Colors.amber.withValues(alpha: 0.2)
                              : isCurrentMonth
                                  ? theme.cardColor
                                  : theme.cardColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? Colors.amber
                                : theme.dividerColor.withValues(alpha: 0.2),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentMonth
                                ? (isToday ? Colors.amber.shade900 : theme.textTheme.bodyMedium?.color)
                                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                          ),
                        ),
                        if (totalItems > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: completedCount == totalItems
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$completedCount/$totalItems',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: completedCount == totalItems ? Colors.green.shade800 : theme.colorScheme.primary,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
