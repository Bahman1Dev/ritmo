import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RoutineActions {
  static Future<void> completeRoutine({
    required BuildContext context,
    required String routineId,
    required String resultType,
    required String dateStr,
    int? durationMinutes,
    VoidCallback? onDone,
  }) async {
    await RitmoExecutionKernel.instance.execute(
      CompleteOccurrenceCommand(
        routineId: routineId,
        dateStr: dateStr,
        resultType: resultType,
        durationMinutes: durationMinutes ?? 0,
      ),
    );

    if (!context.mounted) return;
    final colors = context.colors;
    _showTopToast(
      context: context,
      message: 'روتین ثبت شد: ${resultType == 'LIGHT' ? 'نسخه سبک' : (resultType == 'MINIMAL' ? 'نسخه حداقلی' : 'نسخه کامل')}',
      icon: Icons.check_circle_rounded,
      iconColor: colors.success,
    );
    onDone?.call();
  }

  static Future<void> snoozeRoutine({
    required BuildContext context,
    required String routineId,
    required String dateStr,
    required int minutes,
    VoidCallback? onDone,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final selectedDateMidnight = DateTime.parse(dateStr);
    final startOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day, 23, 59, 59).millisecondsSinceEpoch;

    final reminders = await db.query(
      'pending_reminders',
      where: 'routineId = ? AND scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [routineId, startOfDay, endOfDay],
    );

    String reminderId;
    if (reminders.isNotEmpty) {
      reminderId = reminders.first['id']! as String;
    } else {
      // برای روتینهای بدون yadowari فعال، یک pending_reminder تازه بساز
      // تا Kernel بتواند alarm را schedule کند.
      reminderId = 'rem_${routineId}_${DateTime.now().millisecondsSinceEpoch}';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.insert('pending_reminders', {
        'id': reminderId,
        'routineId': routineId,
        'originalTime': nowMs,
        'scheduledTime': nowMs,
        'state': 'unknown',
        'deferCount': 0,
        'snoozeUntil': null,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });
    }

    await RitmoExecutionKernel.instance.execute(
      SnoozeReminderCommand(reminderId: reminderId, snoozeMinutes: minutes, dateStr: dateStr),
    );

    // Invalidate the agenda cache for the target date so the UI refreshes correctly
    DayAgendaService.instance.invalidateDate(dateStr);

    if (!context.mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'روتین به مدت $minutes دقیقه به تعویق افتاد.',
          style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary),
        ),
        backgroundColor: colors.warning,
      ),
    );
    onDone?.call();
  }

  static void _showTopToast({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    OverlayState? overlayState;
    try {
      overlayState = Overlay.of(context, rootOverlay: true);
    } catch (_) {}
    if (overlayState == null) {
      try {
        overlayState = Overlay.of(context);
      } catch (_) {}
    }
    if (overlayState == null) return;
    
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {

  const _TopToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 64,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xff1E2235).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
