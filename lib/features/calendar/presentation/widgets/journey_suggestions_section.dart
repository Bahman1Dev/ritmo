import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';

class JourneySuggestionsSection extends StatelessWidget {
  const JourneySuggestionsSection({
    super.key,
    required this.snapshot,
  });

  final DayAgendaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final conflicts = snapshot.conflicts;
    final suggestions = snapshot.suggestions;

    if (conflicts.isEmpty && suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 36, color: Colors.green.shade400),
            const SizedBox(height: 8),
            const Text(
              'No schedule conflicts or warnings.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Your day is well aligned and ready to execute.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conflicts.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'Detected Conflicts',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final conflict in conflicts)
            Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                conflict.description,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (suggestions.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                'Optimization Suggestions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final suggestion in suggestions)
            Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.message,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (suggestion.suggestedTimeOfDay != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        suggestion.suggestedTimeOfDay!,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
