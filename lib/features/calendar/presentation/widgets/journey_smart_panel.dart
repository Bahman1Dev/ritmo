import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_free_gaps_section.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_suggestions_section.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_summary_section.dart';

class JourneySmartPanel extends StatefulWidget {
  const JourneySmartPanel({
    super.key,
    required this.snapshot,
    this.onSelectActivity,
    this.onSelectFreeGap,
    this.onSelectConflict,
  });

  final DayAgendaSnapshot snapshot;
  final ValueChanged<AgendaItem>? onSelectActivity;
  final ValueChanged<TimeGap>? onSelectFreeGap;
  final ValueChanged<AgendaConflict>? onSelectConflict;

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required DayAgendaSnapshot snapshot,
    ValueChanged<AgendaItem>? onSelectActivity,
    ValueChanged<TimeGap>? onSelectFreeGap,
    ValueChanged<AgendaConflict>? onSelectConflict,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JourneySmartPanel(
        snapshot: snapshot,
        onSelectActivity: onSelectActivity,
        onSelectFreeGap: onSelectFreeGap,
        onSelectConflict: onSelectConflict,
      ),
    );
  }

  @override
  State<JourneySmartPanel> createState() => _JourneySmartPanelState();
}

class _JourneySmartPanelState extends State<JourneySmartPanel> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.68,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerLow : theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusSheet)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: CalendarTokens.spacingM),
            // Top Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CalendarTokens.spacingM),

            // Segmented Tab Header Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingXl),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(CalendarTokens.spacingXs),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHigh : theme.cardColor,
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusSegPill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Vazirmatn',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Vazirmatn',
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(text: 'خلاصه'),
                    Tab(text: 'پیشنهادها (${toPersianDigits(widget.snapshot.suggestions.length.toString())})'),
                    Tab(text: 'زمان آزاد (${toPersianDigits(widget.snapshot.freeGaps.length.toString())})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CalendarTokens.spacingS),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(CalendarTokens.spacingXl),
                    child: JourneySummarySection(
                      snapshot: widget.snapshot,
                      onSelectActivity: (item) {
                        Navigator.maybePop(context);
                        widget.onSelectActivity?.call(item);
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(CalendarTokens.spacingXl),
                    child: JourneySuggestionsSection(
                      snapshot: widget.snapshot,
                      onSelectConflict: (conflict) {
                        Navigator.maybePop(context);
                        widget.onSelectConflict?.call(conflict);
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(CalendarTokens.spacingXl),
                    child: JourneyFreeGapsSection(
                      snapshot: widget.snapshot,
                      onSelectFreeGap: (gap) {
                        Navigator.maybePop(context);
                        widget.onSelectFreeGap?.call(gap);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
