import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';

class JourneySummarySection extends StatelessWidget {
  const JourneySummarySection({
    super.key,
    required this.snapshot,
    this.onSelectActivity,
  });

  final DayAgendaSnapshot snapshot;
  final ValueChanged<AgendaItem>? onSelectActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Day Overview (${snapshot.dateStr})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Rhythm Score',
                value: '${snapshot.rhythmScore}',
                icon: Icons.speed,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Completed',
                value: '${snapshot.completedCount}',
                icon: Icons.task_alt,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Remaining',
                value: '${snapshot.remainingCount}',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Free Gaps',
                value: '${snapshot.freeGaps.length}',
                icon: Icons.event_available,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Overload Ratio',
                value: '${(snapshot.overloadScore * 100).toInt()}%',
                icon: Icons.warning_amber_rounded,
                color: snapshot.overloadScore > 1.0 ? Colors.red : Colors.blueGrey,
              ),
            ),
          ],
        ),
        if (snapshot.currentActivity != null) ...[
          const SizedBox(height: 16),
          _ActivityRow(
            label: 'Current Activity',
            item: snapshot.currentActivity!,
            color: Colors.green,
            onTap: () => onSelectActivity?.call(snapshot.currentActivity!),
          ),
        ],
        if (snapshot.nextActivity != null) ...[
          const SizedBox(height: 8),
          _ActivityRow(
            label: 'Next Activity',
            item: snapshot.nextActivity!,
            color: Colors.amber,
            onTap: () => onSelectActivity?.call(snapshot.nextActivity!),
          ),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.item,
    required this.color,
    required this.onTap,
  });

  final String label;
  final AgendaItem item;
  final MaterialColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
