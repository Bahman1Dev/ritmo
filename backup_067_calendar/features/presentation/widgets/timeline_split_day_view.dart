import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_motion.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_column_header.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_grid.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_hour_axis.dart';

class TimelineSplitDayView extends StatefulWidget {
  const TimelineSplitDayView({
    super.key,
    required this.items,
    required this.isToday,
    this.sleepStartMinutes,
    this.sleepEndMinutes,
    this.highlightedItemId,
    this.onItemTap,
    this.onItemMove,
    this.onItemResize,
    this.onSlotTap,
    this.onScheduleUntimed,
    this.onOverflowTap,
  });

  final List<AgendaItem> items;
  final bool isToday;
  final int? sleepStartMinutes;
  final int? sleepEndMinutes;
  final String? highlightedItemId;
  final ValueChanged<AgendaItem>? onItemTap;
  final void Function(AgendaItem item, int newStartMinutes)? onItemMove;
  final void Function(AgendaItem item, int newDurationMinutes)? onItemResize;
  final ValueChanged<int>? onSlotTap; // minute of day (0..1439)
  final void Function(AgendaItem item, int startMinutes, int durationMinutes)? onScheduleUntimed;
  final ValueChanged<AgendaItem>? onOverflowTap;

  @override
  State<TimelineSplitDayView> createState() => TimelineSplitDayViewState();
}

class TimelineSplitDayViewState extends State<TimelineSplitDayView> {
  late final ScrollController _sharedScrollController;
  late final ScrollController _singleColumnController;

  @override
  void initState() {
    super.initState();
    _sharedScrollController = ScrollController();
    _singleColumnController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSmartInitialScroll();
    });
  }

  @override
  void dispose() {
    _sharedScrollController.dispose();
    _singleColumnController.dispose();
    super.dispose();
  }

  void scrollToMinutes(int minutes) {
    if (!_sharedScrollController.hasClients) {
      if (_singleColumnController.hasClients) {
        final offset = ((minutes - 60).clamp(0, 1440)) * CalendarTokens.pxPerMinute;
        final maxScroll = _singleColumnController.position.maxScrollExtent;
        _singleColumnController.animateTo(
          offset.clamp(0.0, maxScroll),
          duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
          curve: CalendarTokens.curveEmphasis,
        );
      }
      return;
    }

    final isMorning = minutes < CalendarTokens.splitBoundaryMinutes;
    final rangeStart = isMorning ? 0 : CalendarTokens.splitBoundaryMinutes;
    final minuteInRange = minutes - rangeStart;

    final offset = ((minuteInRange - 60).clamp(0, 720)) * CalendarTokens.pxPerMinuteSplit;
    final maxScroll = _sharedScrollController.position.maxScrollExtent;
    _sharedScrollController.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
      curve: CalendarTokens.curveEmphasis,
    );
  }

  void _performSmartInitialScroll() {
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;

    if (widget.isToday) {
      final rangeStart = nowMinutes < CalendarTokens.splitBoundaryMinutes ? 0 : CalendarTokens.splitBoundaryMinutes;
      _scrollToMinutesInController(_sharedScrollController, nowMinutes, rangeStart);
      if (_singleColumnController.hasClients) {
        final offset = ((nowMinutes - 60).clamp(0, 1440)) * CalendarTokens.pxPerMinute;
        final maxScroll = _singleColumnController.position.maxScrollExtent;
        _singleColumnController.animateTo(
          offset.clamp(0.0, maxScroll),
          duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
          curve: CalendarTokens.curveEmphasis,
        );
      }
    } else {
      _scrollToFirstItemOrDefault(_sharedScrollController, 0, 1440);
      if (_singleColumnController.hasClients) {
        _scrollToFirstItemOrDefault(_singleColumnController, 0, 1440, isSingle: true);
      }
    }
  }

  void _scrollToMinutesInController(ScrollController controller, int minutes, int rangeStart) {
    if (!controller.hasClients) return;
    final offset = ((minutes - rangeStart - 60).clamp(0, 720)) * CalendarTokens.pxPerMinuteSplit;
    final maxScroll = controller.position.maxScrollExtent;
    controller.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
      curve: CalendarTokens.curveEmphasis,
    );
  }

  void _scrollToFirstItemOrDefault(ScrollController controller, int rangeStart, int rangeEnd, {bool isSingle = false}) {
    if (!controller.hasClients) return;
    final timedItems = widget.items.where((i) => i.isTimed).toList();
    var firstMinute = rangeStart;

    for (final item in timedItems) {
      final startM = TimelineSnappingHelper.parseTimeToMinutes(item.timeOfDay ?? '');
      if (startM >= rangeStart && startM < rangeEnd) {
        firstMinute = startM;
        break;
      }
    }

    final pxRate = isSingle ? CalendarTokens.pxPerMinute : CalendarTokens.pxPerMinuteSplit;
    final offset = ((firstMinute - rangeStart - 30).clamp(0, 720)) * pxRate;
    final maxScroll = controller.position.maxScrollExtent;
    controller.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
      curve: CalendarTokens.curveEmphasis,
    );
  }

  Widget _buildColumnGrid({
    required BuildContext context,
    required SplitDayRange range,
    required HourAxisSide side,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final columnItems = widget.items.where((item) {
      if (!item.isTimed) return false;
      final startM = TimelineSnappingHelper.parseTimeToMinutes(item.timeOfDay ?? '');
      final durM = DurationBounds.sanitize(item.durationMinutes);
      final endM = startM + durM;
      return startM < range.endMinutes && endM > range.startMinutes;
    }).toList();

    return DragTarget<AgendaItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localOffset = renderBox.globalToLocal(details.offset);
        final scrollOffset = _sharedScrollController.hasClients ? _sharedScrollController.offset : 0.0;
        final localY = localOffset.dy + scrollOffset;

        final rawMinutes = ((localY / CalendarTokens.pxPerMinuteSplit) + range.startMinutes).round();
        final dur = DurationBounds.sanitize(details.data.durationMinutes);
        final snappedStart = TimelineSnappingHelper.snapStartMinutes(rawMinutes, durationMinutes: dur);

        if (details.data.isTimed) {
          widget.onItemMove?.call(details.data, snappedStart);
        } else {
          widget.onScheduleUntimed?.call(details.data, snappedStart, dur);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            TimelineGrid(
              items: widget.items,
              isToday: widget.isToday,
              rangeStartMinutes: range.startMinutes,
              rangeEndMinutes: range.endMinutes,
              pxPerMinute: CalendarTokens.pxPerMinuteSplit,
              hourAxisWidth: CalendarTokens.hourAxisWidthSplit,
              maxLanes: CalendarTokens.maxLanesSplit,
              axisSide: side,
              scrollController: _sharedScrollController,
              sleepStartMinutes: widget.sleepStartMinutes,
              sleepEndMinutes: widget.sleepEndMinutes,
              highlightedItemId: widget.highlightedItemId,
              onItemTap: widget.onItemTap,
              onItemMove: widget.onItemMove,
              onItemResize: widget.onItemResize,
              onSlotTap: widget.onSlotTap,
              onScheduleUntimed: widget.onScheduleUntimed,
              onOverflowTap: widget.onOverflowTap,
            ),
            if (columnItems.isEmpty)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(CalendarTokens.spacingM),
                      child: Text(
                        'برنامه‌ای در این بازه نیست',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: CalendarTokens.textMeta,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 20.0;
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;

    final isMorningActive = widget.isToday && nowMinutes < CalendarTokens.splitBoundaryMinutes;
    final isAfternoonActive = widget.isToday && nowMinutes >= CalendarTokens.splitBoundaryMinutes;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < CalendarTokens.splitMinScreenWidth) {
          // Fallback to single column timeline for narrow screens
          return SingleChildScrollView(
            controller: _singleColumnController,
            padding: EdgeInsets.only(bottom: paddingBottom),
            child: TimelineGrid(
              items: widget.items,
              isToday: widget.isToday,
              rangeStartMinutes: 0,
              rangeEndMinutes: 1440,
              pxPerMinute: CalendarTokens.pxPerMinute,
              hourAxisWidth: CalendarTokens.hourAxisWidth,
              sleepStartMinutes: widget.sleepStartMinutes,
              sleepEndMinutes: widget.sleepEndMinutes,
              highlightedItemId: widget.highlightedItemId,
              onItemTap: widget.onItemTap,
              onItemMove: widget.onItemMove,
              onItemResize: widget.onItemResize,
              onSlotTap: widget.onSlotTap,
              onScheduleUntimed: widget.onScheduleUntimed,
              onOverflowTap: widget.onOverflowTap,
            ),
          );
        }

        // Split 2-column layout (Morning on RIGHT in RTL, Afternoon on LEFT)
        // Synchronized Scrolling & Borderless Frameless UI
        return Column(
          children: [
            // Sticky Headers Row
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingS),
                child: Row(
                  children: [
                    Expanded(
                      child: TimelineColumnHeader(
                        title: SplitDayRange.morning.titleFa,
                        icon: SplitDayRange.morning.icon,
                        rangeLabel: SplitDayRange.morning.rangeLabel,
                        isActive: isMorningActive,
                      ),
                    ),
                    const SizedBox(width: CalendarTokens.columnGap),
                    Expanded(
                      child: TimelineColumnHeader(
                        title: SplitDayRange.afternoon.titleFa,
                        icon: SplitDayRange.afternoon.icon,
                        rangeLabel: SplitDayRange.afternoon.rangeLabel,
                        isActive: isAfternoonActive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Shared Synchronized Scrollable Grids
            Expanded(
              child: SingleChildScrollView(
                controller: _sharedScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: paddingBottom),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning Column (Right in RTL, side: HourAxisSide.leading -> Hour Axis on RIGHT)
                        Expanded(
                          child: _buildColumnGrid(
                            context: context,
                            range: SplitDayRange.morning,
                            side: HourAxisSide.leading,
                          ),
                        ),
                        SizedBox(
                          width: CalendarTokens.columnGap,
                          child: Center(
                            child: Container(
                              width: 1.0,
                              height: 720 * CalendarTokens.pxPerMinuteSplit,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).dividerColor.withValues(alpha: 0.0),
                                    Theme.of(context).dividerColor.withValues(alpha: 0.22),
                                    Theme.of(context).dividerColor.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Afternoon Column (Left in RTL, side: HourAxisSide.leading -> Hour Axis on RIGHT)
                        Expanded(
                          child: _buildColumnGrid(
                            context: context,
                            range: SplitDayRange.afternoon,
                            side: HourAxisSide.leading,
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
    );
  }
}
