// lib/features/registry/presentation/widgets/registry_status_badge.dart

import 'package:flutter/material.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';

/// Unified, consistent status badge for registry entries.
/// Shows a small pill with a colored dot and label text.
class RegistryStatusBadge extends StatelessWidget {
  const RegistryStatusBadge({
    super.key,
    required this.status,
    required this.reminderHealth,
    this.isUrgent = false,
  });

  final RegistryStatus status;
  final ReminderHealth reminderHealth;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final (String label, Color dotColor) = _resolve();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve() {
    // Priority 1: Overdue reminder on active items → needs attention
    if (status == RegistryStatus.active &&
        reminderHealth == ReminderHealth.overdue) {
      return ('نیازمند توجه', const Color(0xFFEF4444));
    }

    // Priority 2: Urgent countdown on active items
    if (status == RegistryStatus.active && isUrgent) {
      return ('موعد نزدیک', const Color(0xFFF59E0B));
    }

    // Priority 3: Base status
    switch (status) {
      case RegistryStatus.active:
        return ('فعال', const Color(0xFF10B981));
      case RegistryStatus.paused:
        return ('متوقف', const Color(0xFF94A3B8));
      case RegistryStatus.archived:
        return ('بایگانی', const Color(0xFF64748B));
      case RegistryStatus.completed:
        return ('تکمیل‌شده', const Color(0xFF10B981));
      case RegistryStatus.expired:
        return ('منقضی', const Color(0xFFF59E0B));
    }
  }
}
