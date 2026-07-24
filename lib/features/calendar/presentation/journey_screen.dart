import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_smart_panel.dart';
import 'package:ritmo/features/calendar/presentation/widgets/now_pill.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_grid.dart';
import 'package:ritmo/features/calendar/presentation/widgets/timeline_untimed_section.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final JourneyController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = JourneyController();
    _controller.loadDate(DateTime.now()).then((_) {
      _autoScrollToNow();
    });
  }

  void _autoScrollToNow() {
    if (!mounted) return;
    final now = DateTime.now();
    final isToday = _isSameDay(_controller.selectedDate, now);
    if (isToday && _scrollController.hasClients) {
      final nowMinutes = (now.hour * 60) + now.minute;
      final targetScroll = (nowMinutes - 60).clamp(0, 1440) * 1.2;
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _navigateDay(int offsetDays) {
    final nextDate = _controller.selectedDate.add(Duration(days: offsetDays));
    _controller.loadDate(nextDate).then((_) {
      if (_isSameDay(nextDate, DateTime.now())) {
        _autoScrollToNow();
      }
    });
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
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
                  onPressed: () => _navigateDay(-1),
                  tooltip: 'Previous day',
                ),
                Expanded(
                  child: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateDay(1),
                  tooltip: 'Next day',
                ),
              ],
            ),
            actions: [
              if (!isToday)
                TextButton(
                  onPressed: () {
                    _controller.loadDate(DateTime.now()).then((_) => _autoScrollToNow());
                  },
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              if (snapshot != null)
                IconButton(
                  icon: const Icon(Icons.space_dashboard_outlined),
                  tooltip: 'Day Insights & Summary',
                  onPressed: () {
                    JourneySmartPanel.showAsBottomSheet(context, snapshot);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _controller.refresh,
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.errorMessage != null
                  ? Center(child: Text('Error: ${_controller.errorMessage}'))
                  : snapshot == null
                      ? const Center(child: Text('No agenda data found.'))
                      : Stack(
                          children: [
                            Column(
                              children: [
                                if (untimedItems.isNotEmpty)
                                  TimelineUntimedSection(untimedItems: untimedItems),
                                Expanded(
                                  child: PrimaryScrollController(
                                    controller: _scrollController,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: TimelineGrid(
                                        items: timedItems,
                                        isToday: isToday,
                                        pxPerMinute: 1.2,
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
                                    onTapPill: () {
                                      JourneySmartPanel.showAsBottomSheet(context, snapshot);
                                    },
                                    onTapJumpNow: _autoScrollToNow,
                                  ),
                                ),
                              ),
                          ],
                        ),
        );
      },
    );
  }
}
