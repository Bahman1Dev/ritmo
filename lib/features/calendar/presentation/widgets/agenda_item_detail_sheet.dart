import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

class AgendaItemDetailSheet extends StatelessWidget {
  const AgendaItemDetailSheet({
    super.key,
    required this.item,
    this.onComplete,
    this.onSkip,
    this.onFocus,
  });

  final AgendaItem item;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onFocus;

  static Future<void> show(
    BuildContext context, {
    required AgendaItem item,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    VoidCallback? onFocus,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AgendaItemDetailSheet(
        item: item,
        onComplete: onComplete,
        onSkip: onSkip,
        onFocus: onFocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = item.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.domain.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 8),
              Text(
                item.isTimed
                    ? '${item.timeOfDay}${item.durationMinutes != null ? ' (${item.durationMinutes} minutes)' : ''}'
                    : 'All-day / Untimed',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.pending_outlined,
                size: 18,
                color: isDone ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Status: ${item.completion.name.toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDone ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (onFocus != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.maybePop(context);
                    onFocus!();
                  },
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  label: const Text('Focus'),
                ),
                const SizedBox(width: 8),
              ],
              if (!isDone && onSkip != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.maybePop(context);
                    onSkip!();
                  },
                  icon: const Icon(Icons.block, size: 18, color: Colors.orange),
                  label: const Text('Skip', style: TextStyle(color: Colors.orange)),
                ),
                const SizedBox(width: 8),
              ],
              if (!isDone && onComplete != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onComplete!();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
