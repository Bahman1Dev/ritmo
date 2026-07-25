import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_date_formatter.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_motion.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/presentation/widgets/calendar_search_delegate.dart';
import 'package:ritmo/features/calendar/presentation/widgets/domain_selection_sheet.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/now_pill.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_split_day_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_untimed_section.dart';
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
  final GlobalKey<TimelineSplitDayViewState> _splitDayKey = GlobalKey<TimelineSplitDayViewState>();
  StreamSubscription<RitmoEvent>? _eventSubscription;

  JourneyScale _prevScale = JourneyScale.day;
  DateTime _prevDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = JourneyController();

    final startDate = widget.initialDate ?? DateTime.now();
    _prevDate = startDate;
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
    if (isToday && _controller.activeScale == JourneyScale.day) {
      final nowMinutes = (now.hour * 60) + now.minute;
      _scrollToMinutesValue(nowMinutes);
    }
  }

  void _scrollToMinutesValue(int minutes) {
    _splitDayKey.currentState?.scrollToMinutes(minutes);
  }

  int? _tryParseMinutes(String? timeStr) {
    if (timeStr == null) return null;

    final value = timeStr.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null) return null;
    if (h < 0 || h >= 24 || m < 0 || m >= 60) return null;

    return (h * 60) + m;
  }

  void _scrollToTimeString(String? timeStr) {
    final minutes = _tryParseMinutes(timeStr);
    if (minutes == null) return;
    _scrollToMinutesValue(minutes);
  }

  void _openItemDetails(AgendaItem item) {
    _controller.highlightItem(item.id);
    if (item.isTimed) {
      _scrollToTimeString(item.timeOfDay);
    }

    ActionRouter.open(context, item: item);
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
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getHeroDateTitle(DateTime date) {
    return CalendarDateFormatter.formatSelectedDateTitle(
      date,
      relativeTo: DateTime.now(),
      includeYear: true,
    );
  }

  String _getJalaliSubTitle(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return toPersianDigits(
      '${jalali.day} ${jalali.formatter.mN} ${jalali.year}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeScale = _controller.activeScale;
        final selectedDate = _controller.selectedDate;
        final snapshot = _controller.snapshot;
        final isToday = _isSameDay(selectedDate, DateTime.now());

        final allItems = snapshot?.items ?? const <AgendaItem>[];
        final untimedItems = allItems.where((i) => !i.isTimed).toList();
        final timedItems = allItems.where((i) => i.isTimed).toList();

        final pillViewModel = NowPillViewModel.fromSnapshot(snapshot);

        final isScaleChanged = activeScale != _prevScale;
        final isDateBackward = selectedDate.isBefore(_prevDate);
        _prevScale = activeScale;
        _prevDate = selectedDate;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                // Header Bar with Navigation Controls & Hero Titles
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + CalendarTokens.spacingS,
                    left: CalendarTokens.spacingL,
                    right: CalendarTokens.spacingL,
                    bottom: CalendarTokens.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: () => _controller.navigatePeriod(-1),
                            tooltip: 'روز قبل',
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _getHeroDateTitle(selectedDate),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: CalendarTokens.textHero - 10,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  _getJalaliSubTitle(selectedDate),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: CalendarTokens.textMeta,
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                            onPressed: () => _controller.navigatePeriod(1),
                            tooltip: 'روز بعد',
                          ),
                          IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () {
                              showSearch(
                                context: context,
                                delegate: CalendarSearchDelegate(
                                  items: allItems,
                                  onItemSelected: _openItemDetails,
                                ),
                              );
                            },
                            tooltip: 'جستجو',
                          ),
                          IconButton(
                            icon: const Icon(Icons.auto_awesome_rounded),
                            onPressed: _openSmartPanel,
                            tooltip: 'پنل هوشمند',
                          ),
                        ],
                      ),
                      const SizedBox(height: CalendarTokens.spacingM),

                      // Scale Switcher Segmented Control
                      JourneyScaleSwitcher(
                        activeScale: activeScale,
                        onScaleChanged: _controller.setScale,
                      ),
                    ],
                  ),
                ),

                // Content View with PageTransitionSwitcher
                Expanded(
                  child: PageTransitionSwitcher(
                    duration: CalendarMotion.d(context, CalendarTokens.durationEmphasis),
                    reverse: isDateBackward,
                    transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                      if (isScaleChanged) {
                        return SharedAxisTransition(
                          animation: primaryAnimation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.scaled,
                          child: child,
                        );
                      } else {
                        return SharedAxisTransition(
                          animation: primaryAnimation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.horizontal,
                          child: child,
                        );
                      }
                    },
                    child: _controller.isLoading
                        ? const Center(key: ValueKey('journey_loading'), child: CircularProgressIndicator())
                        : _controller.errorMessage != null
                            ? Center(
                                key: const ValueKey('journey_error'),
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
                                key: ValueKey('${activeScale.name}_${selectedDate.year}_${selectedDate.month}_${selectedDate.day}'),
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
                      TimelineUntimedSection(
                        untimedItems: untimedItems,
                        onItemTap: _openItemDetails,
                        onUnscheduleItem: (item) async {
                          await _controller.unscheduleItem(item);
                          if (mounted) {
                            RitmoToast.show(
                              context,
                              'رویداد از زمان‌بندی خارج شد',
                              onUndo: () => _controller.undoLastAction(),
                            );
                          }
                        },
                      ),
                      Expanded(
                        child: TimelineSplitDayView(
                          key: _splitDayKey,
                          items: snapshot.items,
                          isToday: isToday,
                          sleepStartMinutes: snapshot.sleepWindow?.startMinutes,
                          sleepEndMinutes: snapshot.sleepWindow?.endMinutes,
                          highlightedItemId: _controller.highlightedItemId,
                          onItemTap: _openItemDetails,
                          onItemMove: (item, newStartMinutes) async {
                            final dur = item.durationMinutes ?? 30;
                            await _controller.scheduleItem(item, newStartMinutes, dur);
                            if (mounted) {
                              final timeStr = TimelineSnappingHelper.minutesToTimeString(newStartMinutes);
                              RitmoToast.show(
                                context,
                                'زمان رویداد به ${toPersianDigits(timeStr)} تغییر یافت',
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
                          onSlotTap: (slotMinutes) {
                            final timeStr = TimelineSnappingHelper.minutesToTimeString(slotMinutes);
                            DomainSelectionSheet.show(context, slotMinutes, timeStr);
                          },
                          onScheduleUntimed: (item, startMinutes, durMinutes) async {
                            await _controller.scheduleItem(item, startMinutes, durMinutes);
                            if (mounted) {
                              final timeStr = TimelineSnappingHelper.minutesToTimeString(startMinutes);
                              RitmoToast.show(
                                context,
                                'رویداد در ساعت ${toPersianDigits(timeStr)} زمان‌بندی شد',
                                onUndo: () => _controller.undoLastAction(),
                              );
                            }
                          },
                          onOverflowTap: _openItemDetails,
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
          onSelectDate: (date) {
            _controller.selectDate(date, scaleToSet: JourneyScale.day);
          },
        );
      case JourneyScale.month:
        return JourneyMonthView(
          selectedDate: selectedDate,
          rangeSnapshots: _controller.rangeSnapshots,
          onSelectDate: (date) {
            _controller.selectDate(date, scaleToSet: JourneyScale.day);
          },
        );
      case JourneyScale.year:
        return JourneyYearView(
          selectedDate: selectedDate,
          rangeSnapshots: _controller.rangeSnapshots,
          onSelectMonth: (date) {
            _controller.selectDate(date, scaleToSet: JourneyScale.month);
          },
        );
    }
  }
}
