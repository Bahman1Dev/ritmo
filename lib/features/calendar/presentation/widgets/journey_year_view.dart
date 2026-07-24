import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';

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
    final now = DateTime.now();
    final currentYear = selectedDate.year;

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 6),
              Text(
                'Year $currentYear Overview',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final monthDate = DateTime(currentYear, monthNumber, 1);
                final isSelectedMonth = monthNumber == selectedDate.month;
                final isCurrentMonth = currentYear == now.year && monthNumber == now.month;

                // Calculate month summary metrics from rangeSnapshots
                int monthTaskCount = 0;
                int monthCompletedCount = 0;

                for (final entry in rangeSnapshots.entries) {
                  final parts = entry.key.split('-');
                  if (parts.length == 3 &&
                      int.tryParse(parts[0]) == currentYear &&
                      int.tryParse(parts[1]) == monthNumber) {
                    monthTaskCount += entry.value.items.length;
                    monthCompletedCount += entry.value.completedCount;
                  }
                }

                return InkWell(
                  onTap: () => onSelectMonth(monthDate),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isSelectedMonth
                          ? theme.colorScheme.primaryContainer
                          : isCurrentMonth
                              ? Colors.amber.withValues(alpha: 0.15)
                              : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelectedMonth
                            ? theme.colorScheme.primary
                            : isCurrentMonth
                                ? Colors.amber
                                : theme.dividerColor.withValues(alpha: 0.2),
                        width: isSelectedMonth ? 2.0 : 1.0,
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
                              monthNames[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth ? Colors.amber.shade900 : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (isCurrentMonth)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$monthTaskCount items',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (monthTaskCount > 0)
                              LinearProgressIndicator(
                                value: (monthCompletedCount / monthTaskCount).clamp(0.0, 1.0),
                                backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                                color: Colors.green,
                                minHeight: 3,
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
    );
  }
}
