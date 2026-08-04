import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class OccurrenceStatusBadge extends StatelessWidget {
  const OccurrenceStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  final String status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (label, color, icon) = switch (status.toLowerCase()) {
      'done' || 'completed' || 'full' => ('انجام شد', colors.success, Icons.check_circle_rounded),
      'skipped' => ('رد شد', colors.medicalRed, Icons.cancel_rounded),
      'rescheduled' || 'snoozed' => ('موکول شد', colors.warning, Icons.update_rounded),
      'unfulfilled' || 'past_unfulfilled' || 'missed' => ('ثبت‌نشده', colors.textSecondary, Icons.history_rounded),
      _ => ('در انتظار', colors.textSecondary, Icons.hourglass_bottom_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
