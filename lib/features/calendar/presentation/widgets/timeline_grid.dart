import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_hour_axis.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_item_card.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_overflow_card.dart';

class TimelineGrid extends StatefulWidget {
  const TimelineGrid({
    super.key,
    required this.items,
    required this.isToday,
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
    this.pxPerMinute = CalendarTokens.pxPerMinute,
    this.hourAxisWidth = CalendarTokens.hourAxisWidth,
    this.maxLanes,
    this.axisSide = HourAxisSide.leading,
    this.scrollController,
    this.sleepStartMinutes,
    this.sleepEndMinutes,
    this.highlightedItemId,
    this.onItemTap,
    this.onItemMove,
    this.onItemResize,
    this.onSlotTap,
    this.onScheduleUntimed,
    this.onOverflowTap,
    this.onZoomScaleUpdate,
  });

  final List<AgendaItem> items;
  final bool isToday;
  final int rangeStartMinutes;
  final int rangeEndMinutes;
  final double pxPerMinute;
  final double hourAxisWidth;
  final int? maxLanes;
  final HourAxisSide axisSide;
  final ScrollController? scrollController;
  final int? sleepStartMinutes;
  final int? sleepEndMinutes;
  final String? highlightedItemId;
  final ValueChanged<AgendaItem>? onItemTap;
  final Function(AgendaItem item, int newStartMinutes)? onItemMove;
  final Function(AgendaItem item, int newDurationMinutes)? onItemResize;
  final ValueChanged<int>? onSlotTap; // minute of day (0..1439)
  final void Function(AgendaItem item, int startMinutes, int durationMinutes)? onScheduleUntimed;
  final ValueChanged<AgendaItem>? onOverflowTap;
  final ValueChanged<double>? onZoomScaleUpdate;

  @override
  State<TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<TimelineGrid> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  String? _activeDragItemId;
  int _dragStartMinutes = 0;
  int _dragInitialStartMinutes = 0;
  double? _touchOffsetInCardY;

  String? _activeResizeItemId;
  int _resizeDurationMinutes = 30;
  int _resizeInitialDurationMinutes = 30;
  double? _resizeInitialTouchLocalY;

  @override
  void initState() {
    super.initState();
    if (widget.isToday) {
      _startMinuteTimer();
    }
  }

  @override
  void didUpdateWidget(TimelineGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToday && _timer == null) {
      _startMinuteTimer();
    } else if (!widget.isToday && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startMinuteTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final newNow = DateTime.now();
      if (newNow.minute != _now.minute || newNow.hour != _now.hour) {
        if (mounted) {
          setState(() {
            _now = newNow;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutEngine = TimelineLayoutEngine(
      pxPerMinute: widget.pxPerMinute,
      rangeStartMinutes: widget.rangeStartMinutes,
      rangeEndMinutes: widget.rangeEndMinutes,
      maxLanes: widget.maxLanes,
    );
    final layoutItems = layoutEngine.calculateLayout(widget.items);
    final totalHeight = layoutEngine.totalTimelineHeight;

    final nowMinutes = (_now.hour * 60) + _now.minute;
    final isNowInRange = widget.isToday &&
        nowMinutes >= widget.rangeStartMinutes &&
        nowMinutes < widget.rangeEndMinutes;
    final nowTop = (nowMinutes - widget.rangeStartMinutes) * widget.pxPerMinute;

    final isLeadingAxis = widget.axisSide == HourAxisSide.leading;

    final hourAxisWidget = RepaintBoundary(
      child: TimelineHourAxis(
        pxPerMinute: widget.pxPerMinute,
        rangeStartMinutes: widget.rangeStartMinutes,
        rangeEndMinutes: widget.rangeEndMinutes,
        width: widget.hourAxisWidth,
        side: widget.axisSide,
      ),
    );

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLeadingAxis) hourAxisWidget,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth;

                TimelineLayoutItem? draggingLayoutItem;
                if (_activeDragItemId != null) {
                  for (final item in layoutItems) {
                    if (item.item.id == _activeDragItemId) {
                      draggingLayoutItem = item;
                      break;
                    }
                  }
                }

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final tapY = details.localPosition.dy;
                        final rawMinutes = (tapY / widget.pxPerMinute).round() + widget.rangeStartMinutes;
                        final snapped = TimelineSnappingHelper.snapStartMinutes(rawMinutes);
                        widget.onSlotTap?.call(snapped);
                      },
                      child: RepaintBoundary(
                        child: TimelineGridLines(
                          pxPerMinute: widget.pxPerMinute,
                          rangeStartMinutes: widget.rangeStartMinutes,
                          rangeEndMinutes: widget.rangeEndMinutes,
                        ),
                      ),
                    ),

                    // Sleep block layer
                    if (widget.sleepStartMinutes != null && widget.sleepEndMinutes != null)
                      _buildSleepBlock(widget.sleepStartMinutes!, widget.sleepEndMinutes!),

                    // Past dimmer for today
                    if (widget.isToday) _buildPastDimmer(nowMinutes, totalHeight),

                    // Drop target preview ghost box during drag
                    if (_activeDragItemId != null && draggingLayoutItem != null)
                      Positioned(
                        top: (_dragStartMinutes - widget.rangeStartMinutes) * widget.pxPerMinute,
                        left: draggingLayoutItem.leftFraction * gridWidth,
                        width: (draggingLayoutItem.widthFraction * gridWidth) - 4.0,
                        height: (draggingLayoutItem.durationMinutes) * widget.pxPerMinute,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                                  ),
                                  child: Text(
                                    toPersianDigits(TimelineSnappingHelper.minutesToTimeString(_dragStartMinutes)),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: CalendarTokens.textLabel,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Timed Agenda Cards & Overflow Cards
                    for (final layoutItem in layoutItems)
                      _buildPositionedItemCard(layoutItem, gridWidth),

                    // Live Now Line
                    if (isNowInRange)
                      Positioned(
                        top: nowTop,
                        left: 0,
                        right: 0,
                        child: RepaintBoundary(
                          child: Semantics(
                            label: 'خط زمان کنونی: ${toPersianDigits('${_now.hour}:${_now.minute}')}',
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  if (isLeadingAxis) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
                                      ),
                                      child: Text(
                                        toPersianDigits(
                                          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                                        ),
                                        style: const TextStyle(
                                          fontSize: CalendarTokens.textLabel,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: CalendarTokens.nowLineThickness,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Container(
                                        height: CalendarTokens.nowLineThickness,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
                                      ),
                                      child: Text(
                                        toPersianDigits(
                                          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                                        ),
                                        style: const TextStyle(
                                          fontSize: CalendarTokens.textLabel,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (!isLeadingAxis) hourAxisWidget,
        ],
      ),
    );
  }

  Widget _buildPastDimmer(int nowMinutes, double totalHeight) {
    if (nowMinutes <= widget.rangeStartMinutes) return const SizedBox.shrink();

    final dimHeight = min(
      (nowMinutes - widget.rangeStartMinutes) * widget.pxPerMinute,
      totalHeight,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: dimHeight,
      child: IgnorePointer(
        child: Container(
          color: Theme.of(context).disabledColor.withValues(alpha: CalendarTokens.alphaPastDim),
        ),
      ),
    );
  }

  Widget _buildPositionedItemCard(TimelineLayoutItem layoutItem, double gridWidth) {
    if (layoutItem.overflowCount > 0) {
      final cardWidth = ((layoutItem.widthFraction * gridWidth) - 4.0).clamp(44.0, gridWidth);
      return Positioned(
        key: ValueKey('overflow_${layoutItem.startMinutes}_${layoutItem.laneIndex}'),
        top: layoutItem.top,
        left: layoutItem.leftFraction * gridWidth,
        width: cardWidth,
        height: layoutItem.height,
        child: TimelineOverflowCard(
          overflowCount: layoutItem.overflowCount,
          overflowItems: layoutItem.overflowItems,
        ),
      );
    }

    final item = layoutItem.item;
    final isDraggable = DirectManipulationEligibility.isDraggable(item);
    final isResizable = DirectManipulationEligibility.isResizable(item);

    final isCurrentlyDragging = _activeDragItemId == item.id;
    final isCurrentlyResizing = _activeResizeItemId == item.id;

    final top = isCurrentlyDragging
        ? (_dragStartMinutes - widget.rangeStartMinutes) * widget.pxPerMinute
        : layoutItem.top;

    final height = isCurrentlyResizing
        ? _resizeDurationMinutes * widget.pxPerMinute
        : layoutItem.height;

    final displayTime = isCurrentlyDragging
        ? toPersianDigits(TimelineSnappingHelper.minutesToTimeString(_dragStartMinutes))
        : null;

    final displayDuration = isCurrentlyResizing ? _resizeDurationMinutes : null;

    final cardWidth = ((layoutItem.widthFraction * gridWidth) - 4.0).clamp(44.0, gridWidth);
    final cardHeight = max(height, 28.0);

    final itemCard = TimelineItemCard(
      layoutItem: layoutItem,
      isHighlighted: item.id == widget.highlightedItemId,
      isDraggable: isDraggable,
      isResizable: isResizable,
      isDragging: isCurrentlyDragging,
      isResizing: isCurrentlyResizing,
      displayTimeOverride: displayTime,
      displayHeightOverride: displayDuration != null ? displayDuration * widget.pxPerMinute : null,
      onTap: () => widget.onItemTap?.call(item),
      onResizeStart: isResizable
          ? (_) {
              if (mounted) {
                setState(() {
                  _activeResizeItemId = item.id;
                  _resizeDurationMinutes = layoutItem.durationMinutes;
                  _resizeInitialDurationMinutes = layoutItem.durationMinutes;
                  _resizeInitialTouchLocalY = null;
                });
              }
            }
          : null,
      onResizeUpdate: isResizable
          ? (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localY = renderBox.globalToLocal(details.globalPosition).dy;
                _resizeInitialTouchLocalY ??= localY;
                final deltaY = localY - _resizeInitialTouchLocalY!;
                final deltaMins = (deltaY / widget.pxPerMinute).round();
                final rawDuration = _resizeInitialDurationMinutes + deltaMins;
                final snapped = TimelineSnappingHelper.snapDurationMinutes(
                  rawDuration,
                  startMinutes: layoutItem.startMinutes,
                );
                if (snapped != _resizeDurationMinutes && mounted) {
                  setState(() {
                    _resizeDurationMinutes = snapped;
                  });
                }
              }
            }
          : null,
      onResizeEnd: isResizable
          ? (_) {
              widget.onItemResize?.call(item, _resizeDurationMinutes);
              if (mounted) {
                setState(() {
                  _activeResizeItemId = null;
                  _resizeInitialTouchLocalY = null;
                });
              }
            }
          : null,
    );

    final sizedItemCard = SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: itemCard,
    );

    Widget contentWidget;
    if (isDraggable) {
      contentWidget = LongPressDraggable<AgendaItem>(
        data: item,
        delay: const Duration(milliseconds: 400),
        hapticFeedbackOnStart: true,
        feedback: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: Transform.scale(
              scale: 1.05,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: TimelineItemCard(
                  layoutItem: layoutItem,
                  isGhost: true,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: sizedItemCard,
        ),
        onDragStarted: () {
          RitmoHaptics.tap();
          if (mounted) {
            setState(() {
              _activeDragItemId = item.id;
              _dragStartMinutes = layoutItem.startMinutes;
              _dragInitialStartMinutes = layoutItem.startMinutes;
              _touchOffsetInCardY = null;
            });
          }
        },
        onDragUpdate: (details) {
          _handleAutoEdgeScroll(details.globalPosition);
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localOffset = renderBox.globalToLocal(details.globalPosition);
            if (_touchOffsetInCardY == null) {
              final initialCardTopY = (_dragInitialStartMinutes - widget.rangeStartMinutes) * widget.pxPerMinute;
              _touchOffsetInCardY = localOffset.dy - initialCardTopY;
            }
            final cardTopY = localOffset.dy - _touchOffsetInCardY!;
            final rawStart = (cardTopY / widget.pxPerMinute).round() + widget.rangeStartMinutes;
            final snapped = TimelineSnappingHelper.snapStartMinutes(
              rawStart,
              durationMinutes: layoutItem.durationMinutes,
            );
            if (snapped != _dragStartMinutes && mounted) {
              RitmoHaptics.tap();
              setState(() {
                _dragStartMinutes = snapped;
              });
            }
          }
        },
        onDraggableCanceled: (_, __) {
          if (mounted) {
            setState(() {
              _activeDragItemId = null;
              _touchOffsetInCardY = null;
            });
          }
        },
        onDragEnd: (details) {
          widget.onItemMove?.call(item, _dragStartMinutes);
          if (mounted) {
            setState(() {
              _activeDragItemId = null;
              _touchOffsetInCardY = null;
            });
          }
        },
        child: sizedItemCard,
      );
    } else {
      contentWidget = sizedItemCard;
    }

    return Positioned(
      key: ValueKey('item_${layoutItem.item.id}_${widget.rangeStartMinutes}_${layoutItem.startMinutes}_${layoutItem.laneIndex}'),
      top: top,
      left: layoutItem.leftFraction * gridWidth,
      width: cardWidth,
      height: cardHeight,
      child: RepaintBoundary(
        child: contentWidget,
      ),
    );
  }

  void _handleAutoEdgeScroll(Offset globalPosition) {
    final controller = widget.scrollController ?? PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPosition);
    final viewportHeight = controller.position.viewportDimension;
    final scrollOffset = controller.position.pixels;
    final targetYInViewport = localPos.dy - scrollOffset;

    const edgeMargin = 50.0;
    const scrollStep = 25.0;

    if (targetYInViewport < edgeMargin && scrollOffset > 0) {
      final newOffset = (scrollOffset - scrollStep).clamp(0.0, controller.position.maxScrollExtent);
      controller.jumpTo(newOffset);
    } else if (targetYInViewport > viewportHeight - edgeMargin && scrollOffset < controller.position.maxScrollExtent) {
      final newOffset = (scrollOffset + scrollStep).clamp(0.0, controller.position.maxScrollExtent);
      controller.jumpTo(newOffset);
    }
  }

  Widget _buildSleepBlock(int startM, int endM) {
    final segments = _sleepSegmentsForDay(startM, endM);
    if (segments.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final widgets = <Widget>[];

    for (final seg in segments) {
      final visStart = max(seg.startMinutes, widget.rangeStartMinutes);
      final visEnd = min(seg.endMinutes, widget.rangeEndMinutes);
      if (visStart >= visEnd) continue;

      final top = (visStart - widget.rangeStartMinutes) * widget.pxPerMinute;
      final height = (visEnd - visStart) * widget.pxPerMinute;
      if (height <= 0) continue;

      widgets.add(Positioned(
        top: top,
        left: 0,
        right: 0,
        height: height,
        child: IgnorePointer(
          child: Container(
            color: colors.sunken.withValues(alpha: 0.55),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'پنجره خواب',
              style: TextStyle(
                fontSize: CalendarTokens.textLabel,
                color: colors.textTertiary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ),
      ));
    }

    return Stack(children: widgets);
  }

  List<({int startMinutes, int endMinutes})> _sleepSegmentsForDay(int startM, int endM) {
    final start = startM % 1440;
    final end = endM % 1440;
    final crossesMidnight = startM > endM || endM > 1440;
    if (!crossesMidnight && start < end) {
      return [(startMinutes: start, endMinutes: end)];
    }
    return [
      (startMinutes: 0, endMinutes: end),
      (startMinutes: start, endMinutes: 1440),
    ];
  }
}
