import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_free_gaps_section.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_suggestions_section.dart';
import 'package:ritmo/features/calendar/presentation/widgets/journey_summary_section.dart';

class JourneySmartPanel extends StatefulWidget {
  const JourneySmartPanel({
    super.key,
    required this.snapshot,
  });

  final DayAgendaSnapshot snapshot;

  static Future<void> showAsBottomSheet(BuildContext context, DayAgendaSnapshot snapshot) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JourneySmartPanel(snapshot: snapshot),
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(
                text: 'Summary',
                icon: Icon(Icons.analytics_outlined, size: 18),
              ),
              Tab(
                text: 'Suggestions (${widget.snapshot.suggestions.length})',
                icon: const Icon(Icons.lightbulb_outline, size: 18),
              ),
              Tab(
                text: 'Free Gaps (${widget.snapshot.freeGaps.length})',
                icon: const Icon(Icons.event_available, size: 18),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: JourneySummarySection(snapshot: widget.snapshot),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: JourneySuggestionsSection(snapshot: widget.snapshot),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: JourneyFreeGapsSection(snapshot: widget.snapshot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
