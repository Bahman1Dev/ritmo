// lib/features/registry/presentation/widgets/registry_countdown_badge.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

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
    // Update remaining time display every 30 seconds
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = widget.agendaItem.timeOfDay?.trim();
    if (timeStr == null || timeStr.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.all_inclusive_rounded, size: 12, color: Colors.blueGrey),
            SizedBox(width: 4),
            Text(
              'شناور',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      );
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeStr);
    if (match == null) return const SizedBox.shrink();

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);

    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, hour, minute);
    final diff = targetTime.difference(now);
    final diffMinutes = diff.inMinutes;

    Color bgGradientStart;
    Color bgGradientEnd;
    Color textColor;
    Color borderColor;
    String badgeText;
    IconData icon;

    if (diffMinutes < -45) {
      // Time passed long ago
      bgGradientStart = Colors.grey.shade700;
      bgGradientEnd = Colors.grey.shade800;
      textColor = Colors.white70;
      borderColor = Colors.grey.shade600;
      badgeText = 'سپری‌شده';
      icon = Icons.history_rounded;
    } else if (diffMinutes < 0) {
      // Due right now / slightly past
      bgGradientStart = const Color(0xFF10B981); // Emerald
      bgGradientEnd = const Color(0xFF059669);
      textColor = Colors.white;
      borderColor = const Color(0xFF34D399);
      badgeText = '⚡ موعد انجام';
      icon = Icons.bolt_rounded;
    } else if (diffMinutes <= 15) {
      // Urgent (< 15 mins)
      bgGradientStart = const Color(0xFFEF4444); // Crimson Rose
      bgGradientEnd = const Color(0xFFDC2626);
      textColor = Colors.white;
      borderColor = const Color(0xFFF87171);
      badgeText = 'مانده ${PersianDigits.convert('$diffMinutes')}د';
      icon = Icons.timer_rounded;
    } else if (diffMinutes <= 60) {
      // Approaching (< 1 hour)
      bgGradientStart = const Color(0xFFF97316); // Vibrant Orange
      bgGradientEnd = const Color(0xFFEA580C);
      textColor = Colors.white;
      borderColor = const Color(0xFFFB923C);
      badgeText = 'مانده ${PersianDigits.convert('$diffMinutes')}د';
      icon = Icons.access_time_filled_rounded;
    } else if (diffMinutes <= 180) {
      // 1 to 3 hours
      bgGradientStart = const Color(0xFFF59E0B); // Amber
      bgGradientEnd = const Color(0xDDF59E0B);
      textColor = Colors.white;
      borderColor = const Color(0xFFFBBF24);
      final hrs = diffMinutes ~/ 60;
      final mins = diffMinutes % 60;
      badgeText = mins > 0
          ? 'مانده ${PersianDigits.convert('$hrs')}س ${PersianDigits.convert('$mins')}د'
          : 'مانده ${PersianDigits.convert('$hrs')}س';
      icon = Icons.schedule_rounded;
    } else {
      // Ample time (> 3 hours)
      bgGradientStart = const Color(0xFF3B82F6); // Royal Blue
      bgGradientEnd = const Color(0xFF2563EB);
      textColor = Colors.white;
      borderColor = const Color(0xFF60A5FA);
      final hrs = diffMinutes ~/ 60;
      final mins = diffMinutes % 60;
      badgeText = mins > 0
          ? 'مانده ${PersianDigits.convert('$hrs')}س ${PersianDigits.convert('$mins')}د'
          : 'مانده ${PersianDigits.convert('$hrs')}س';
      icon = Icons.hourglass_top_rounded;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: bgGradientStart.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
