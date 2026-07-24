import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_date_formatter.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/presentation/widgets/agenda_item_detail_sheet.dart';
import 'package:ritmo/features/calendar/presentation/widgets/calendar_search_delegate.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/now_pill.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_grid.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_untimed_section.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:shamsi_date/shamsi_date.dart';

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
    final targetScroll = ((minutes - 60).clamp(0, 1440)) * CalendarTokens.pxPerMinute;
    _scrollController.animateTo(
      targetScroll,
      duration: CalendarTokens.durationEmphasis,
      curve: CalendarTokens.curveEmphasis,
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

  void _handleSlotTap(String timeOfDay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusSheet)),
            ),
            padding: const EdgeInsets.all(CalendarTokens.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_task_rounded, color: Colors.blueAccent),
                    const SizedBox(width: CalendarTokens.spacingS),
                    Text(
                      'ثبت برنامه جدید در ساعت ${toPersianDigits(timeOfDay)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: CalendarTokens.spacingM),
                Text(
                  'کارت موقت ثبت سریع رویداد در ساعت ${toPersianDigits(timeOfDay)} ایجاد شد.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: CalendarTokens.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('ثبت رویداد جدید'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getHeroDateTitle(DateTime date) {
    return CalendarDateFormatter.formatSelectedDateTitle(
      date,
      relativeTo: DateTime.now(),
      includeYear: true,
    );
  }

  String _getSubContextTitle(JourneyScale scale, DateTime date) {
    switch (scale) {
      case JourneyScale.day:
        final jalali = Jalali.fromDateTime(date);
        return 'روز ${jalali.formatter.wN}';
      case JourneyScale.week:
        final sat = CourseScheduler.getSaturdayOfWeek(date);
        final fri = sat.add(const Duration(days: 6));
        final satJalali = Jalali.fromDateTime(sat);
        final friJalali = Jalali.fromDateTime(fri);
        return 'هفته ${toPersianDigits(satJalali.day.toString())} ${satJalali.formatter.mN} – ${toPersianDigits(friJalali.day.toString())} ${friJalali.formatter.mN}';
      case JourneyScale.month:
        final jalali = Jalali.fromDateTime(date);
        return '${jalali.formatter.mN} ${toPersianDigits(jalali.year.toString())}';
      case JourneyScale.year:
        final jalali = Jalali.fromDateTime(date);
        return 'سال ${toPersianDigits(jalali.year.toString())}';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Layer 1 Command Deck Header Surface
                Container(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85)
                      : theme.colorScheme.surface.withValues(alpha: 0.95),
                  padding: const EdgeInsets.only(
                    left: CalendarTokens.spacingXl,
                    right: CalendarTokens.spacingXl,
                    top: CalendarTokens.spacingM,
                    bottom: CalendarTokens.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [1] Date Hero Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getHeroDateTitle(selectedDate),
                              style: TextStyle(
                                fontSize: CalendarTokens.textHero,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'Vazirmatn',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isToday)
                            Semantics(
                              label: 'پرش به امروز',
                              button: true,
                              child: GestureDetector(
                                onTap: () {
                                  _controller.selectDate(DateTime.now());
                                  _autoScrollToNow();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
                                  ),
                                  child: Text(
                                    'امروز',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: CalendarTokens.spacingS),

                      // [2] Navigation & Context Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 38,
                                height: 38,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.chevron_right, size: 22),
                                  onPressed: () => _controller.navigatePeriod(-1),
                                  tooltip: 'دوره قبل',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  _getSubContextTitle(activeScale, selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 38,
                                height: 38,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.chevron_left, size: 22),
                                  onPressed: () => _controller.navigatePeriod(1),
                                  tooltip: 'دوره بعد',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (snapshot != null)
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.space_dashboard_outlined, size: 20),
                                    tooltip: 'خلاصه روز',
                                    onPressed: _openSmartPanel,
                                  ),
                                ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.search_rounded, size: 20),
                                  tooltip: 'جستجوی رویدادها',
                                  onPressed: () async {
                                    final selected = await showSearch<AgendaItem?>(
                                      context: context,
                                      delegate: CalendarSearchDelegate(items: snapshot?.items ?? []),
                                    );
                                    if (selected != null) {
                                      _openItemDetails(selected);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: 'بازخوانی',
                                  onPressed: _controller.refresh,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: CalendarTokens.spacingM),

                      // [3] Scale Switcher Segmented Control
                      JourneyScaleSwitcher(
                        activeScale: activeScale,
                        onScaleChanged: _controller.setScale,
                      ),
                    ],
                  ),
                ),

                // Content View with AnimatedSwitcher Transition
                Expanded(
                  child: AnimatedSwitcher(
                    duration: CalendarTokens.durationStandard,
                    switchInCurve: CalendarTokens.curveDefault,
                    switchOutCurve: CalendarTokens.curveDefault,
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _controller.errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('خطا: ${_controller.errorMessage}'),
                                    const SizedBox(height: CalendarTokens.spacingM),
                                    ElevatedButton(
                                      onPressed: _controller.refresh,
                                      child: const Text('بازخوانی'),
                                    ),
                                  ],
                                ),
                              )
                            : KeyedSubtree(
                                key: ValueKey(activeScale),
                                child: _buildScaleContent(
                                  activeScale: activeScale,
                                  selectedDate: selectedDate,
                                  snapshot: snapshot,
                                  untimedItems: untimedItems,
                                  timedItems: timedItems,
                                  pillViewModel: pillViewModel,
                                  isToday: isToday,
                                ),
                              ),
                  ),
                ),
              ],
            ),
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
            ? const Center(child: Text('هیچ برنامه‌ای برای این روز ثبت نشده'))
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
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80,
                            ),
                            child: TimelineGrid(
                              items: timedItems,
                              isToday: isToday,
                              pxPerMinute: CalendarTokens.pxPerMinute,
                              highlightedItemId: _controller.highlightedItemId,
                              onItemTap: _openItemDetails,
                              onItemMove: (item, newTimeOfDay) async {
                                await _controller.commitItemDrag(item, newTimeOfDay);
                                if (mounted) {
                                  RitmoToast.show(
                                    context,
                                    'زمان رویداد به ${toPersianDigits(newTimeOfDay)} تغییر یافت',
                                    onUndo: () => _controller.undoLastAction(),
                                  );
                                }
                              },
                              onItemResize: (item, newDurationMinutes) async {
                                await _controller.commitItemResize(item, newDurationMinutes);
                                if (mounted) {
                                  RitmoToast.show(
                                    context,
                                    'مدت زمان به ${toPersianDigits(newDurationMinutes.toString())} دقیقه تغییر یافت',
                                    onUndo: () => _controller.undoLastAction(),
                                  );
                                }
                              },
                              onSlotTap: _handleSlotTap,
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
