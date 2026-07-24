import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';

class JourneyFreeGapsSection extends StatelessWidget {
  const JourneyFreeGapsSection({
    super.key,
    required this.snapshot,
    this.onSelectFreeGap,
  });

  final DayAgendaSnapshot snapshot;
  final ValueChanged<TimeGap>? onSelectFreeGap;

  @override
  Widget build(BuildContext context) {
    final gaps = snapshot.freeGaps;

    if (gaps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No free gaps remaining today.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            Text(
              'Available Free Gaps (${gaps.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final gap in gaps)
          InkWell(
            onTap: () => onSelectFreeGap?.call(gap),
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        '${gap.startTimeStr} - ${gap.endTimeStr}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${gap.durationMinutes} min free',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.center_focus_strong, size: 16, color: Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
