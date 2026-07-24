import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/widgets/agenda_item_detail_sheet.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/now_pill.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_grid.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_untimed_section.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({
    super.key,
    this.initialDate,
    this.initialItemId,
  });

  final DateTime? initialDate;
  final String? initialItemId;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final JourneyController _controller;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<RitmoEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _controller = JourneyController();

    final startDate = widget.initialDate ?? DateTime.now();
    _controller.loadDate(startDate).then((_) {
      if (widget.initialItemId != null) {
        _focusItemById(widget.initialItemId);
      } else {
        _autoScrollToNow();
      }
    });

    _eventSubscription = RitmoEventBus().onEvents.listen(_handleNavigationEvent);
  }

  void _handleNavigationEvent(RitmoEvent event) {
    if (!mounted) return;
    if (event.type == 'navigate_tab' && event.payload['index'] == 4) {
      final dateStr = event.payload['date'] as String?;
      final itemId = event.payload['itemId'] as String?;

      if (dateStr != null) {
        try {
          final targetDate = DateTime.parse(dateStr);
          _controller.selectDate(targetDate, scaleToSet: JourneyScale.day);
        } catch (_) {}
      }

      if (itemId != null) {
        _focusItemById(itemId);
      } else {
        _autoScrollToNow();
      }
    }
  }

  void _focusItemById(String? itemId) {
    if (itemId == null || !mounted) return;
    _controller.highlightItem(itemId);

    final snapshot = _controller.snapshot;
    if (snapshot != null) {
      for (final item in snapshot.items) {
        if (item.id == itemId && item.isTimed) {
          _scrollToTimeString(item.timeOfDay);
          break;
        }
      }
    }
  }

  void _autoScrollToNow() {
    if (!mounted) return;
    final now = DateTime.now();
    final isToday = _isSameDay(_controller.selectedDate, now);
    if (isToday && _scrollController.hasClients && _controller.activeScale == JourneyScale.day) {
      final nowMinutes = (now.hour * 60) + now.minute;
      _scrollToMinutesValue(nowMinutes);
    }
  }

  void _scrollToMinutesValue(int minutes) {
    if (!_scrollController.hasClients) return;
    final targetScroll = ((minutes - 60).clamp(0, 1440)) * 1.2;
    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollToTimeString(String? timeStr) {
    if (timeStr == null) return;
    final parts = timeStr.split(':');
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    _scrollToMinutesValue((h * 60) + m);
  }

  void _openItemDetails(AgendaItem item) {
    _controller.highlightItem(item.id);
    if (item.isTimed) {
      _scrollToTimeString(item.timeOfDay);
    }

    AgendaItemDetailSheet.show(
      context,
      item: item,
      onComplete: () => _controller.completeItem(item),
      onSkip: () => _controller.skipItem(item),
      onFocus: () => _scrollToTimeString(item.timeOfDay),
    );
  }

  void _openSmartPanel() {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;

    JourneySmartPanel.showAsBottomSheet(
      context,
      snapshot: snapshot,
      onSelectActivity: _openItemDetails,
      onSelectFreeGap: (gap) {
        if (_controller.activeScale != JourneyScale.day) {
          _controller.setScale(JourneyScale.day);
        }
        _scrollToTimeString(gap.startTimeStr);
      },
      onSelectConflict: (conflict) {
        if (_controller.activeScale != JourneyScale.day) {
          _controller.setScale(JourneyScale.day);
        }
        _openItemDetails(conflict.itemA);
      },
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getHeaderTitle(JourneyScale scale, DateTime date) {
    switch (scale) {
      case JourneyScale.day:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case JourneyScale.week:
        final sat = CourseScheduler.getSaturdayOfWeek(date);
        final fri = sat.add(const Duration(days: 6));
        return '${sat.month}/${sat.day} - ${fri.month}/${fri.day} (${date.year})';
      case JourneyScale.month:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case JourneyScale.year:
        return 'Year ${date.year}';
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final snapshot = _controller.snapshot;
        final selectedDate = _controller.selectedDate;
        final activeScale = _controller.activeScale;
        final isToday = _isSameDay(selectedDate, DateTime.now());

        final untimedItems = snapshot?.items.where((i) => !i.isTimed).toList() ?? [];
        final timedItems = snapshot?.items.where((i) => i.isTimed).toList() ?? [];
        final pillViewModel = NowPillViewModel.fromSnapshot(snapshot);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _controller.navigatePeriod(-1),
                  tooltip: 'Previous period',
                ),
                Expanded(
                  child: Text(
                    _getHeaderTitle(activeScale, selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _controller.navigatePeriod(1),
                  tooltip: 'Next period',
                ),
              ],
            ),
            actions: [
              if (!isToday)
                TextButton(
                  onPressed: () {
                    _controller.selectDate(DateTime.now());
                    _autoScrollToNow();
                  },
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              if (snapshot != null)
                IconButton(
                  icon: const Icon(Icons.space_dashboard_outlined),
                  tooltip: 'Day Insights & Summary',
                  onPressed: _openSmartPanel,
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _controller.refresh,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: JourneyScaleSwitcher(
                  activeScale: activeScale,
                  onScaleChanged: _controller.setScale,
                ),
              ),
              Expanded(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: ${_controller.errorMessage}'),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _controller.refresh,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : _buildScaleContent(
                            activeScale: activeScale,
                            selectedDate: selectedDate,
                            snapshot: snapshot,
                            untimedItems: untimedItems,
                            timedItems: timedItems,
                            pillViewModel: pillViewModel,
                            isToday: isToday,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaleContent({
    required JourneyScale activeScale,
    required DateTime selectedDate,
    required DayAgendaSnapshot? snapshot,
    required List<AgendaItem> untimedItems,
    required List<AgendaItem> timedItems,
    required NowPillViewModel pillViewModel,
    required bool isToday,
  }) {
    switch (activeScale) {
      case JourneyScale.day:
        return snapshot == null
            ? const Center(child: Text('No agenda data found.'))
            : Stack(
                children: [
                  Column(
                    children: [
                      if (untimedItems.isNotEmpty)
                        TimelineUntimedSection(
                          untimedItems: untimedItems,
                          onItemTap: _openItemDetails,
                        ),
                      Expanded(
                        child: PrimaryScrollController(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: TimelineGrid(
                              items: timedItems,
                              isToday: isToday,
                              pxPerMinute: 1.2,
                              highlightedItemId: _controller.highlightedItemId,
                              onItemTap: _openItemDetails,
                              onItemMove: (item, newTimeOfDay) => _controller.commitItemDrag(item, newTimeOfDay),
                              onItemResize: (item, newDurationMinutes) => _controller.commitItemResize(item, newDurationMinutes),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pillViewModel.isVisible)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: NowPill(
                          viewModel: pillViewModel,
                          onTapPill: _openSmartPanel,
                          onTapJumpNow: _autoScrollToNow,
                          onTapComplete: pillViewModel.targetItem != null
                              ? () => _controller.completeItem(pillViewModel.targetItem!)
                              : null,
                        ),
                      ),
                    ),
                ],
              );
      case JourneyScale.week:
        return JourneyWeekView(
          selectedDate: selectedDate,
          rangeSnapshots: _controller.rangeSnapshots,
          onSelectDate: (date) => _controller.selectDate(date, scaleToSet: JourneyScale.day),
        );
      case JourneyScale.month:
        return JourneyMonthView(
          selectedDate: selectedDate,
          rangeSnapshots: _controller.rangeSnapshots,
          onSelectDate: (date) => _controller.selectDate(date, scaleToSet: JourneyScale.day),
        );
      case JourneyScale.year:
        return JourneyYearView(
          selectedDate: selectedDate,
          rangeSnapshots: _controller.rangeSnapshots,
          onSelectMonth: (date) => _controller.selectDate(date, scaleToSet: JourneyScale.month),
        );
    }
  }
}
