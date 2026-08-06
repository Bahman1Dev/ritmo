import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_feedback.dart';
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
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_month_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_scale_switcher.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_week_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_year_view.dart';
import 'package:ritmo/features/calendar/presentation/widgets/now_pill.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_split_day_view.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/registry_service.dart';
import 'package:ritmo/features/registry/presentation/all_plans_screen.dart';
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
  int _registryHealthCount = 0;

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

    _checkHealthIssues();
    _eventSubscription = RitmoEventBus().onEvents.listen((event) {
      _handleNavigationEvent(event);
      _checkHealthIssues();
    });
  }

  Future<void> _checkHealthIssues() async {
    final count = await RegistryService().healthIssueCount({});
    if (mounted) {
      setState(() {
        _registryHealthCount = count;
      });
    }
  }

  void _openAllPlans() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AllPlansScreen()),
    ).then((_) => _checkHealthIssues());
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

    ActionRouter.open(context, item: item, onChanged: () => _controller.refresh());
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

  String _getSubContextTitle(JourneyScale scale, DateTime date) {
    switch (scale) {
      case JourneyScale.day:
        final jalali = Jalali.fromDateTime(date);
        return 'روز ${jalali.formatter.wN}';
      case JourneyScale.week:
        final sat = date.subtract(Duration(days: (date.weekday == 6 ? 0 : (date.weekday == 7 ? 1 : date.weekday + 1))));
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

        final pillViewModel = NowPillViewModel.fromSnapshot(
          snapshot,
          now: DateTime.now(),
          isToday: isToday,
          selectedDate: selectedDate,
        );

        final isScaleChanged = activeScale != _prevScale;
        final isDateBackward = selectedDate.isBefore(_prevDate);
        _prevScale = activeScale;
        _prevDate = selectedDate;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                // Layer 1 Command Deck Header Surface
                Container(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85)
                      : theme.colorScheme.surface.withValues(alpha: 0.95),
                  padding: EdgeInsets.only(
                    left: CalendarTokens.spacingXl,
                    right: CalendarTokens.spacingXl,
                    top: MediaQuery.paddingOf(context).top + CalendarTokens.spacingS,
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
                                  _controller.selectDate(DateTime.now(), scaleToSet: JourneyScale.day);
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
                                    final entries = await RegistryService().query(RegistryQuery(), {});
                                    if (context.mounted) {
                                      showSearch(
                                        context: context,
                                        delegate: CalendarSearchDelegate(
                                          items: allItems,
                                          registryEntries: entries,
                                          onItemSelected: _openItemDetails,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.list_alt_rounded, size: 20),
                                      tooltip: 'همه برنامه‌ها',
                                      onPressed: _openAllPlans,
                                    ),
                                    if (_registryHealthCount > 0)
                                      Positioned(
                                        top: 7,
                                        left: 7,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF43F5E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
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
                    duration: CalendarTokens.durationEmphasis,
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
                            final dur = item.durationMinutes ?? CalendarDefaults.fallbackDurationMinutes;
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
                            final prefilledTime = TimeOfDay(hour: slotMinutes ~/ 60, minute: slotMinutes % 60);
                            UniversalPlannerSheet.show(context: context, prefilledTime: prefilledTime);
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
                              ? () async {
                                  final item = pillViewModel.targetItem!;
                                  await _controller.completeItem(item);
                                  if (mounted) {
                                    ActionFeedback.success(
                                      context,
                                      message: 'رویداد با موفقیت ثبت شد',
                                      dateStr: item.dateStr,
                                    );
                                  }
                                }
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
