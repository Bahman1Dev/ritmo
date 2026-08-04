// lib/features/registry/presentation/widgets/registry_countdown_badge.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

/// Minimal, neutral countdown badge that shows remaining time until
/// a routine's scheduled execution. Colors shift only for the text,
/// keeping the badge surface calm and consistent.
class RegistryCountdownBadge extends StatefulWidget {
  const RegistryCountdownBadge({
    super.key,
    required this.agendaItem,
    this.onTap,
  });

  final AgendaItem agendaItem;
  final VoidCallback? onTap;

  @override
  State<RegistryCountdownBadge> createState() => _RegistryCountdownBadgeState();
}

class _RegistryCountdownBadgeState extends State<RegistryCountdownBadge> {
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  /// Returns the remaining minutes to the scheduled time, or null if floating.
  int? _computeDiff() {
    final timeStr = widget.agendaItem.timeOfDay?.trim();
    if (timeStr == null || timeStr.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeStr);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hour, minute);
    return target.difference(now).inMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final diffMinutes = _computeDiff();

    // Floating (no scheduled time)
    if (diffMinutes == null) {
      return _buildPill(
        context,
        text: 'شناور',
        textColor: Colors.grey,
        bgColor: isDark
            ? Colors.grey.withValues(alpha: 0.10)
            : Colors.grey.withValues(alpha: 0.08),
      );
    }

    // Determine text color and label based on urgency
    Color textColor;
    String label;

    if (diffMinutes < -45) {
      // Long past
      textColor = Colors.grey;
      label = 'سپری‌شده';
    } else if (diffMinutes < 0) {
      // Due now / slightly past
      textColor = const Color(0xFF10B981);
      label = 'موعد انجام';
    } else if (diffMinutes <= 15) {
      // Urgent
      textColor = const Color(0xFFEF4444);
      label = 'مانده ${PersianDigits.convert('$diffMinutes')}د';
    } else if (diffMinutes <= 60) {
      // Approaching
      textColor = const Color(0xFFF59E0B);
      label = 'مانده ${PersianDigits.convert('$diffMinutes')}د';
    } else {
      // Ample time
      final hrs = diffMinutes ~/ 60;
      final mins = diffMinutes % 60;
      textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      label = mins > 0
          ? 'مانده ${PersianDigits.convert('$hrs')}س ${PersianDigits.convert('$mins')}د'
          : 'مانده ${PersianDigits.convert('$hrs')}س';
    }

    return _buildPill(
      context,
      text: label,
      textColor: textColor,
      bgColor: textColor.withValues(alpha: 0.08),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required String text,
    required Color textColor,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
