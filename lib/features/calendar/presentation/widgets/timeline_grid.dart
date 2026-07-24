import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/features/calendar/presentation/logic/timeline_layout_engine.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_hour_axis.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_item_card.dart';

class TimelineGrid extends StatefulWidget {
  const TimelineGrid({
    super.key,
    required this.items,
    required this.isToday,
    this.pxPerMinute = 1.2,
    this.sleepStartMinutes,
    this.sleepEndMinutes,
    this.highlightedItemId,
    this.onItemTap,
    this.onItemMove,
    this.onItemResize,
    this.onSlotTap,
    this.onZoomScaleUpdate,
  });

  final List<AgendaItem> items;
  final bool isToday;
  final double pxPerMinute;
  final int? sleepStartMinutes;
  final int? sleepEndMinutes;
  final String? highlightedItemId;
  final ValueChanged<AgendaItem>? onItemTap;
  final Function(AgendaItem item, String newTimeOfDay)? onItemMove;
  final Function(AgendaItem item, int newDurationMinutes)? onItemResize;
  final ValueChanged<String>? onSlotTap;
  final ValueChanged<double>? onZoomScaleUpdate;

  @override
  State<TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<TimelineGrid> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  String? _activeDragItemId;
  int _dragStartMinutes = 0;

  String? _activeResizeItemId;
  int _resizeDurationMinutes = 30;

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
    final layoutEngine = TimelineLayoutEngine(pxPerMinute: widget.pxPerMinute);
    final layoutItems = layoutEngine.calculateLayout(widget.items);
    final totalHeight = layoutEngine.totalTimelineHeight;

    final nowMinutes = (_now.hour * 60) + _now.minute;
    final nowTop = nowMinutes * widget.pxPerMinute;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: TimelineHourAxis(pxPerMinute: widget.pxPerMinute),
          ),
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
                        final rawMinutes = (tapY / widget.pxPerMinute).round();
                        final snapped = TimelineSnappingHelper.snapStartMinutes(rawMinutes);
                        final timeStr = TimelineSnappingHelper.minutesToTimeString(snapped);
                        widget.onSlotTap?.call(timeStr);
                      },
                      child: RepaintBoundary(
                        child: TimelineGridLines(pxPerMinute: widget.pxPerMinute),
                      ),
                    ),

                    // Optional sleep block layer
                    if (widget.sleepStartMinutes != null && widget.sleepEndMinutes != null)
                      _buildSleepBlock(widget.sleepStartMinutes!, widget.sleepEndMinutes!),

                    // Past dimmer for today
                    if (widget.isToday && nowTop > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: nowTop,
                        child: IgnorePointer(
                          child: Container(
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                          ),
                        ),
                      ),

                    // Empty timeline placeholder guidance if no timed items exist
                    if (widget.items.isEmpty)
                      Positioned(
                        top: 100,
                        left: 16,
                        right: 16,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'هیچ برنامه‌ زمان‌بندی‌شده‌ای برای این روز ثبت نشده است',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Drop target preview ghost box during drag
                    if (_activeDragItemId != null && draggingLayoutItem != null)
                      Positioned(
                        top: _dragStartMinutes * widget.pxPerMinute,
                        left: draggingLayoutItem.leftFraction * gridWidth,
                        width: (draggingLayoutItem.widthFraction * gridWidth) - 4.0,
                        height: (draggingLayoutItem.durationMinutes) * widget.pxPerMinute,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.0),
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
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    toPersianDigits(TimelineSnappingHelper.minutesToTimeString(_dragStartMinutes)),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Timed Agenda Cards
                    for (final layoutItem in layoutItems)
                      RepaintBoundary(
                        key: ObjectKey(layoutItem),
                        child: _buildPositionedItemCard(layoutItem, gridWidth),
                      ),

                    // Live Now Line
                    if (widget.isToday)
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      toPersianDigits(
                                        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2.0,
                                      color: Colors.redAccent,
                                    ),
                                  ),
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
        ],
      ),
    );
  }

  Widget _buildPositionedItemCard(TimelineLayoutItem layoutItem, double gridWidth) {
    final item = layoutItem.item;
    final isDraggable = DirectManipulationEligibility.isDraggable(item);
    final isResizable = DirectManipulationEligibility.isResizable(item);

    final isCurrentlyDragging = _activeDragItemId == item.id;
    final isCurrentlyResizing = _activeResizeItemId == item.id;

    final top = isCurrentlyDragging
        ? _dragStartMinutes * widget.pxPerMinute
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
      displayDurationOverride: displayDuration,
      onTap: () => widget.onItemTap?.call(item),
      onResizeStart: isResizable
          ? (_) {
              if (mounted) {
                setState(() {
                  _activeResizeItemId = item.id;
                  _resizeDurationMinutes = layoutItem.durationMinutes;
                });
              }
            }
          : null,
      onResizeUpdate: isResizable
          ? (details) {
              final deltaMins = (details.delta.dy / widget.pxPerMinute).round();
              final rawDuration = _resizeDurationMinutes + deltaMins;
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
          : null,
      onResizeEnd: isResizable
          ? (_) {
              widget.onItemResize?.call(item, _resizeDurationMinutes);
              if (mounted) {
                setState(() {
                  _activeResizeItemId = null;
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
          borderRadius: BorderRadius.circular(12),
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
          HapticFeedback.mediumImpact();
          if (mounted) {
            setState(() {
              _activeDragItemId = item.id;
              _dragStartMinutes = layoutItem.startMinutes;
            });
          }
        },
        onDragUpdate: (details) {
          _handleAutoEdgeScroll(details.globalPosition);
          final deltaMinutes = (details.delta.dy / widget.pxPerMinute).round();
          final rawStart = _dragStartMinutes + deltaMinutes;
          final snapped = TimelineSnappingHelper.snapStartMinutes(
            rawStart,
            durationMinutes: layoutItem.durationMinutes,
          );
          if (snapped != _dragStartMinutes && mounted) {
            setState(() {
              _dragStartMinutes = snapped;
            });
          }
        },
        onDragEnd: (details) {
          final targetTime = TimelineSnappingHelper.minutesToTimeString(_dragStartMinutes);
          widget.onItemMove?.call(item, targetTime);
          if (mounted) {
            setState(() {
              _activeDragItemId = null;
            });
          }
        },
        child: sizedItemCard,
      );
    } else {
      contentWidget = sizedItemCard;
    }

    return Positioned(
      top: top,
      left: layoutItem.leftFraction * gridWidth,
      width: cardWidth,
      height: cardHeight,
      child: contentWidget,
    );
  }

  void _handleAutoEdgeScroll(Offset globalPosition) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPosition);
    final viewportHeight = scrollable.position.viewportDimension;
    final scrollOffset = scrollable.position.pixels;
    final targetYInViewport = localPos.dy - scrollOffset;

    const edgeMargin = 50.0;
    const scrollStep = 25.0;

    if (targetYInViewport < edgeMargin && scrollOffset > 0) {
      final newOffset = (scrollOffset - scrollStep).clamp(0.0, scrollable.position.maxScrollExtent);
      scrollable.position.jumpTo(newOffset);
    } else if (targetYInViewport > viewportHeight - edgeMargin && scrollOffset < scrollable.position.maxScrollExtent) {
      final newOffset = (scrollOffset + scrollStep).clamp(0.0, scrollable.position.maxScrollExtent);
      scrollable.position.jumpTo(newOffset);
    }
  }

  Widget _buildSleepBlock(int startM, int endM) {
    if (endM <= startM) return const SizedBox.shrink();
    final top = startM * widget.pxPerMinute;
    final height = (endM - startM) * widget.pxPerMinute;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: Container(
          color: Colors.indigo.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(4.0),
          child: const Text(
            'Sleep Window',
            style: TextStyle(
              fontSize: 10,
              color: Colors.indigo,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
