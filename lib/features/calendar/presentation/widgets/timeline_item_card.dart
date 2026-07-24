import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

class TimelineItemCard extends StatelessWidget {
  const TimelineItemCard({
    super.key,
    required this.layoutItem,
    this.onTap,
  });

  final TimelineLayoutItem layoutItem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = layoutItem.item;
    final theme = Theme.of(context);

    final cardColor = _getDomainColor(item.domain, theme);
    final isDone = item.isCompleted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: isDone ? 0.4 : 0.85),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: cardColor.withValues(alpha: 1.0),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (isDone)
                  const Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: Icon(Icons.check_circle, size: 12, color: Colors.white),
                  ),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            if (layoutItem.height > 36 && item.timeOfDay != null) ...[
              const SizedBox(height: 2),
              Text(
                '${item.timeOfDay}${item.durationMinutes != null ? ' (${item.durationMinutes}m)' : ''}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _getDomainColor(AgendaDomain domain, ThemeData theme) {
    switch (domain) {
      case AgendaDomain.routine:
        return Colors.teal.shade700;
      case AgendaDomain.prayer:
        return Colors.indigo.shade700;
      case AgendaDomain.mustahab:
        return Colors.blueGrey.shade600;
      case AgendaDomain.course:
        return Colors.amber.shade800;
      case AgendaDomain.goalStep:
        return Colors.deepPurple.shade600;
      case AgendaDomain.konkur:
        return Colors.red.shade700;
      case AgendaDomain.cycle:
        return Colors.pink.shade600;
      case AgendaDomain.worshipDebt:
        return Colors.brown.shade600;
      case AgendaDomain.sport:
        return Colors.green.shade700;
      case AgendaDomain.medicine:
        return Colors.orange.shade800;
    }
  }
}
