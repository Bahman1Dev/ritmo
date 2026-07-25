import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class TimelineItemCard extends StatelessWidget {
  const TimelineItemCard({
    super.key,
    required this.layoutItem,
    this.isHighlighted = false,
    this.isDraggable = false,
    this.isResizable = false,
    this.isDragging = false,
    this.isResizing = false,
    this.isGhost = false,
    this.isDimmed = false,
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
  final bool isGhost;
  final bool isDimmed;
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
    final isDark = theme.brightness == Brightness.dark;

    final domainColor = _getDomainColor(item.domain, theme);
    final isDone = item.isCompleted;

    final effectiveTime = displayTimeOverride ?? item.timeOfDay;
    final effectiveDuration = displayDurationOverride ?? item.durationMinutes;

    final surfaceColor = isDone
        ? theme.cardColor.withValues(alpha: 0.5)
        : (isDragging || isGhost
            ? domainColor.withValues(alpha: 0.20)
            : domainColor.withValues(alpha: isDark ? 0.12 : CalendarTokens.alphaDomainFill));

    final accentBarColor = isDone
        ? theme.colorScheme.outline.withValues(alpha: 0.35)
        : domainColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Opacity(
        opacity: isDimmed ? 0.25 : (isGhost ? 0.85 : 1.0),
        child: Stack(
          children: [
            // Main Card Body — GestureDetector only handles onTap so scroll passes through
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: onTap,
              child: AnimatedContainer(
                width: double.infinity,
                height: double.infinity,
                duration: CalendarTokens.durationMicro,
                curve: CalendarTokens.curveDefault,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : (isDragging || isResizing
                          ? domainColor
                          : theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder)),
                  width: (isHighlighted || isDragging || isResizing) ? 1.5 : 1.0,
                ),
                boxShadow: (isDragging || isResizing)
                    ? [
                        BoxShadow(
                          color: domainColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : (isHighlighted
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                            )
                          ]
                        : null),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Row(
                  children: [
                    // Right Edge Domain Accent Bar (3px) in RTL
                    Container(
                      width: CalendarTokens.accentBarWidth,
                      height: double.infinity,
                      color: accentBarColor,
                    ),

                    // Card Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: layoutItem.height < 36 ? 2.0 : 5.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getDomainIcon(item.domain),
                                  size: 13,
                                  color: isDone
                                      ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)
                                      : domainColor,
                                ),
                                const SizedBox(width: CalendarTokens.spacingXs),
                                if (isDone)
                                  Padding(
                                    padding: const EdgeInsets.only(left: CalendarTokens.spacingXs),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: CalendarTokens.textBody,
                                      fontWeight: isDone ? FontWeight.w400 : FontWeight.w600,
                                      color: isDone
                                          ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45)
                                          : theme.textTheme.bodyLarge?.color,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                                if (isDraggable)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 14,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                                    ),
                                  ),
                              ],
                            ),
                            if (layoutItem.height > 36 && effectiveTime != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                toPersianDigits(
                                  '$effectiveTime${effectiveDuration != null ? ' ($effectiveDuration دقیقه)' : ''}',
                                ),
                                style: TextStyle(
                                  fontSize: CalendarTokens.textMeta,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.60),
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Truncated indicator ("ادامه دارد")
          if (layoutItem.isTruncated)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 22,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        surfaceColor.withValues(alpha: 0.0),
                        surfaceColor.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(
                        Icons.keyboard_double_arrow_down_rounded,
                        size: 14,
                        color: domainColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Resize Handle Pill
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
                    height: 4,
                    decoration: BoxDecoration(
                      color: domainColor.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(2),
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
        return Colors.teal.shade600;
      case AgendaDomain.prayer:
        return Colors.indigo.shade600;
      case AgendaDomain.mustahab:
        return Colors.blueGrey.shade600;
      case AgendaDomain.course:
        return Colors.amber.shade700;
      case AgendaDomain.goalStep:
        return Colors.deepPurple.shade600;
      case AgendaDomain.konkur:
        return Colors.red.shade600;
      case AgendaDomain.cycle:
        return Colors.pink.shade600;
      case AgendaDomain.worshipDebt:
        return Colors.brown.shade600;
      case AgendaDomain.sport:
        return Colors.green.shade600;
      case AgendaDomain.medicine:
        return Colors.orange.shade700;
    }
  }
}
