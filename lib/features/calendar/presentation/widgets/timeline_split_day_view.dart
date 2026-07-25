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
  late final ScrollController _morningController;
  late final ScrollController _afternoonController;
  late final ScrollController _singleColumnController;

  @override
  void initState() {
    super.initState();
    _morningController = ScrollController();
    _afternoonController = ScrollController();
    _singleColumnController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSmartInitialScroll();
    });
  }

  @override
  void dispose() {
    _morningController.dispose();
    _afternoonController.dispose();
    _singleColumnController.dispose();
    super.dispose();
  }

  void scrollToMinutes(int minutes) {
    final isMorning = minutes < CalendarTokens.splitBoundaryMinutes;
    final controller = isMorning ? _morningController : _afternoonController;
    final rangeStart = isMorning ? 0 : CalendarTokens.splitBoundaryMinutes;

    if (!controller.hasClients) {
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

    final offset = ((minutes - rangeStart - 60).clamp(0, 720)) * CalendarTokens.pxPerMinuteSplit;
    final maxScroll = controller.position.maxScrollExtent;
    controller.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
      curve: CalendarTokens.curveEmphasis,
    );
  }

  void _performSmartInitialScroll() {
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;

    if (widget.isToday) {
      if (nowMinutes < CalendarTokens.splitBoundaryMinutes) {
        _scrollToMinutesInController(_morningController, nowMinutes, 0);
        _scrollToFirstItemOrDefault(_afternoonController, CalendarTokens.splitBoundaryMinutes, 1440);
      } else {
        _scrollToMinutesInController(_afternoonController, nowMinutes, CalendarTokens.splitBoundaryMinutes);
        _scrollToFirstItemOrDefault(_morningController, 0, CalendarTokens.splitBoundaryMinutes);
      }
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
      _scrollToFirstItemOrDefault(_morningController, 0, CalendarTokens.splitBoundaryMinutes);
      _scrollToFirstItemOrDefault(_afternoonController, CalendarTokens.splitBoundaryMinutes, 1440);
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

  Widget _buildColumn({
    required BuildContext context,
    required SplitDayRange range,
    required HourAxisSide side,
    required ScrollController controller,
    required bool isMorning,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;
    final isActive = widget.isToday && (nowMinutes >= range.startMinutes && nowMinutes < range.endMinutes);

    final columnItems = widget.items.where((item) {
      if (!item.isTimed) return false;
      final startM = TimelineSnappingHelper.parseTimeToMinutes(item.timeOfDay ?? '');
      final durM = DurationBounds.sanitize(item.durationMinutes);
      final endM = startM + durM;
      return startM < range.endMinutes && endM > range.startMinutes;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: CalendarTokens.alphaCardBorder),
        ),
      ),
      child: Column(
        children: [
          TimelineColumnHeader(
            title: range.titleFa,
            icon: range.icon,
            rangeLabel: range.rangeLabel,
            isActive: isActive,
          ),
          Expanded(
            child: DragTarget<AgendaItem>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                final localOffset = renderBox.globalToLocal(details.offset);
                final scrollOffset = controller.hasClients ? controller.offset : 0.0;
                final localY = localOffset.dy + scrollOffset - CalendarTokens.columnHeaderHeight;

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
                    SingleChildScrollView(
                      controller: controller,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: TimelineGrid(
                        items: widget.items,
                        isToday: widget.isToday,
                        rangeStartMinutes: range.startMinutes,
                        rangeEndMinutes: range.endMinutes,
                        pxPerMinute: CalendarTokens.pxPerMinuteSplit,
                        hourAxisWidth: CalendarTokens.hourAxisWidthSplit,
                        maxLanes: CalendarTokens.maxLanesSplit,
                        axisSide: side,
                        scrollController: controller,
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
                    ),
                    if (columnItems.isEmpty)
                      Center(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(CalendarTokens.spacingM),
                            child: Text(
                              'برنامه‌ای در این بازه نیست',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: CalendarTokens.textMeta,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontFamily: 'Vazirmatn',
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

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 80.0;

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
        return Padding(
          padding: EdgeInsets.only(bottom: paddingBottom),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔴 CRITICAL ORDER IN RTL:
                // First child in Row renders on the RIGHT side of screen.
                // Morning column MUST be the first child.
                Expanded(
                  child: _buildColumn(
                    context: context,
                    range: SplitDayRange.morning,
                    side: HourAxisSide.trailing,
                    controller: _morningController,
                    isMorning: true,
                  ),
                ),
                const SizedBox(width: CalendarTokens.columnGap),
                // Afternoon column renders on the LEFT side of screen.
                Expanded(
                  child: _buildColumn(
                    context: context,
                    range: SplitDayRange.afternoon,
                    side: HourAxisSide.leading,
                    controller: _afternoonController,
                    isMorning: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
