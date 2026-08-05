import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';

class RoutineActions {
  static Future<void> completeRoutine({
    required BuildContext context,
    required String routineId,
    required String resultType,
    required String dateStr,
    int? durationMinutes,
    VoidCallback? onDone,
  }) async {
    await CompletionGateway.instance.submit(
      RoutineCompletion(
        routineId: routineId,
        dateStr: dateStr,
        result: CompletionResult.fromDb(resultType),
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
    RitmoToast.show(context, message, icon: icon, iconColor: iconColor);
  }
}
