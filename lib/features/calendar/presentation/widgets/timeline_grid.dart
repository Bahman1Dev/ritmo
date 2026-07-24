import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
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
  });

  final List<AgendaItem> items;
  final bool isToday;
  final double pxPerMinute;
  final int? sleepStartMinutes;
  final int? sleepEndMinutes;

  @override
  State<TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<TimelineGrid> {
  Timer? _timer;
  DateTime _now = DateTime.now();

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
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            TimelineHourAxis(pxPerMinute: widget.pxPerMinute),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridWidth = constraints.maxWidth;

                  return Stack(
                    children: [
                      TimelineGridLines(pxPerMinute: widget.pxPerMinute),

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

                      // Timed Agenda Cards
                      for (final layoutItem in layoutItems)
                        Positioned(
                          top: layoutItem.top,
                          left: layoutItem.leftFraction * gridWidth,
                          width: (layoutItem.widthFraction * gridWidth) - 4.0,
                          height: layoutItem.height,
                          child: TimelineItemCard(layoutItem: layoutItem),
                        ),

                      // Live Now Line
                      if (widget.isToday)
                        Positioned(
                          top: nowTop,
                          left: 0,
                          right: 0,
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
                                    '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
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
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
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
