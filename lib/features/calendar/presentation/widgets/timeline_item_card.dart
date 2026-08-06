import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_time_range.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';

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
    this.displayHeightOverride,
    this.onTap,
    this.onToggleComplete,
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
  final double? displayHeightOverride;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = layoutItem.item;
    final isDone = item.isCompleted;

    final color = domainColor(context, item.domain);
    final bgContainerColor = domainContainerColor(context, item.domain);

    final height = displayHeightOverride ?? layoutItem.height;
    final isCompact = height < 36.0;
    final isExpanded = height > 64.0;

    final cardOpacity = isDone ? 0.55 : (isDimmed ? 0.30 : (isGhost ? 0.85 : 1.0));

    final borderRadius = layoutItem.continuedFromPreviousDay
        ? const BorderRadius.vertical(bottom: Radius.circular(CalendarTokens.radiusCard))
        : (layoutItem.continuesToNextDay
            ? const BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusCard))
            : BorderRadius.circular(CalendarTokens.radiusCard));

    final startMin = layoutItem.startMinutes;
    final durMin = layoutItem.durationMinutes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Semantics(
        label: '${item.title}، ${item.timeOfDay ?? "بدون زمان"}، ${domainLabelFa(item.domain)}',
        child: Opacity(
          opacity: cardOpacity,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: AnimatedContainer(
              duration: CalendarTokens.durationMicro,
              curve: CalendarTokens.curveDefault,
              decoration: BoxDecoration(
                color: bgContainerColor,
                borderRadius: borderRadius,
                border: Border.all(
                  color: isHighlighted
                      ? color
                      : (item.isEstimated
                          ? color.withValues(alpha: 0.4)
                          : colors.border.withValues(alpha: 0.15)),
                  width: isHighlighted ? 2.0 : 1.0,
                  style: item.isEstimated ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    // Right accent bar (RTL)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 4.0,
                      child: Container(
                        color: isDone ? colors.disabled : color,
                      ),
                    ),

                    // Single-day override indicator dot
                    if (item.hasOverride)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Tooltip(
                          message: 'فقط امروز تغییر کرده',
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                    // Content layout by tier
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0, left: 6.0, top: 4.0, bottom: 4.0),
                      child: isCompact
                          ? _buildCompactTier(context, colors, color, isDone)
                          : (isExpanded
                              ? _buildExpandedTier(context, colors, color, isDone, startMin, durMin)
                              : _buildNormalTier(context, colors, color, isDone, startMin, durMin)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTier(BuildContext context, RitmoColors colors, Color color, bool isDone) {
    final item = layoutItem.item;
    return Row(
      children: [
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: CalendarTokens.textLabel,
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              decoration: isDone ? TextDecoration.lineThrough : null,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalTier(BuildContext context, RitmoColors colors, Color color, bool isDone, int startMin, int durMin) {
    final item = layoutItem.item;
    return Row(
      children: [
        Icon(domainIcon(item.domain), size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: CalendarTokens.textMeta,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              if (item.isTimed)
                RitmoTimeRange(
                  startMinutes: startMin,
                  endMinutes: startMin + durMin,
                  style: TextStyle(
                    fontSize: CalendarTokens.textLabel,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedTier(BuildContext context, RitmoColors colors, Color color, bool isDone, int startMin, int durMin) {
    final item = layoutItem.item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(domainIcon(item.domain), size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: CalendarTokens.textTitle,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              if (item.subtitle != null && item.subtitle!.isNotEmpty)
                Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: CalendarTokens.textLabel,
                    color: colors.textTertiary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              const Spacer(),
              if (item.isTimed)
                RitmoTimeRange(
                  startMinutes: startMin,
                  endMinutes: startMin + durMin,
                  style: TextStyle(
                    fontSize: CalendarTokens.textLabel,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
            ],
          ),
        ),
        if (onToggleComplete != null)
          GestureDetector(
            onTap: onToggleComplete,
            child: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isDone ? colors.success : colors.disabled,
            ),
          ),
      ],
    );
  }
}
