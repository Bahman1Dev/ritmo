import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';

class TimelineItemCard extends StatelessWidget {
  const TimelineItemCard({
    super.key,
    required this.layoutItem,
    this.isHighlighted = false,
    this.isDraggable = false,
    this.isResizable = false,
    this.isDragging = false,
    this.isResizing = false,
    this.displayTimeOverride,
    this.displayDurationOverride,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onResizeStart,
    this.onResizeUpdate,
    this.onResizeEnd,
  });

  final TimelineLayoutItem layoutItem;
  final bool isHighlighted;
  final bool isDraggable;
  final bool isResizable;
  final bool isDragging;
  final bool isResizing;
  final String? displayTimeOverride;
  final int? displayDurationOverride;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final GestureDragStartCallback? onResizeStart;
  final GestureDragUpdateCallback? onResizeUpdate;
  final GestureDragEndCallback? onResizeEnd;

  @override
  Widget build(BuildContext context) {
    final item = layoutItem.item;
    final theme = Theme.of(context);

    final cardColor = _getDomainColor(item.domain, theme);
    final isDone = item.isCompleted;

    final effectiveTime = displayTimeOverride ?? item.timeOfDay;
    final effectiveDuration = displayDurationOverride ?? item.durationMinutes;

    return Stack(
      children: [
        // Main Card Body
        GestureDetector(
          onTap: onTap,
          onVerticalDragStart: isDraggable ? onDragStart : null,
          onVerticalDragUpdate: isDraggable ? onDragUpdate : null,
          onVerticalDragEnd: isDraggable ? onDragEnd : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: isDone ? 0.4 : (isDragging ? 0.95 : 0.85)),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: (isHighlighted || isDragging || isResizing)
                    ? Colors.white
                    : cardColor.withValues(alpha: 1.0),
                width: (isHighlighted || isDragging || isResizing) ? 2.5 : 1.2,
              ),
              boxShadow: (isHighlighted || isDragging || isResizing)
                  ? [
                      BoxShadow(
                        color: (isDragging || isResizing)
                            ? cardColor.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(_getDomainIcon(item.domain), size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
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
                    if (isDraggable)
                      const Padding(
                        padding: EdgeInsets.only(left: 2.0),
                        child: Icon(Icons.drag_indicator, size: 12, color: Colors.white70),
                      ),
                  ],
                ),
                if (layoutItem.height > 36 && effectiveTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$effectiveTime${effectiveDuration != null ? ' (${effectiveDuration}m)' : ''}',
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
        ),

        // Bottom Resize Handle
        if (isResizable)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: onResizeStart,
              onVerticalDragUpdate: onResizeUpdate,
              onVerticalDragEnd: onResizeEnd,
              child: Center(
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _getDomainIcon(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return Icons.sync_rounded;
      case AgendaDomain.prayer:
        return Icons.mosque_rounded;
      case AgendaDomain.mustahab:
        return Icons.menu_book_rounded;
      case AgendaDomain.course:
        return Icons.school_rounded;
      case AgendaDomain.goalStep:
        return Icons.track_changes_rounded;
      case AgendaDomain.konkur:
        return Icons.assignment_rounded;
      case AgendaDomain.cycle:
        return Icons.favorite_rounded;
      case AgendaDomain.worshipDebt:
        return Icons.restore_rounded;
      case AgendaDomain.sport:
        return Icons.fitness_center_rounded;
      case AgendaDomain.medicine:
        return Icons.medication_rounded;
    }
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
