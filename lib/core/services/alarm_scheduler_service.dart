import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:sqflite/sqflite.dart';

class AlarmSchedulerService {
  /// Scans all active routine schedules and schedules the next occurrences (next 24h-48h).
  /// Reconciles with AlarmManager via NativeBridge.
  static Future<void> scheduleNextAlarms() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final settingsList = await db.query('app_settings');
    final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

    // Load active routines and schedules
    final routines = await db.query('routines', where: 'isArchived = 0');
    final schedules = await db.query('routine_schedules');

    // Fetch calendar exceptions and routines map
    final exceptions = await db.query('calendar_exceptions');
    final exceptionsMap = {
      for (final e in exceptions) e['date']! as String: e['behavior']! as String
    };
    final routinesMap = {
      for (final r in routines) r['id']! as String: r
    };

    // Clean up existing alarms that conflict with exceptions
    final pending = await db.query(
      'pending_reminders',
      where: "state = 'unknown' OR state = 'delayed'",
    );

    for (final pMap in pending) {
      final id = pMap['id']! as String;
      final routineId = pMap['routineId']! as String;
      final scheduledTimeMs = pMap['scheduledTime']! as int;
      final scheduledDate = DateTime.fromMillisecondsSinceEpoch(scheduledTimeMs);
      final dateStr = scheduledDate.toIso8601String().substring(0, 10);

      final behavior = exceptionsMap[dateStr] ?? 'NORMAL';
      final r = routinesMap[routineId];
      final isEssential = r != null && r['isEssential'] == 1;

      if (behavior == 'SILENCE_ALL' || (behavior == 'ESSENTIAL_ONLY' && !isEssential)) {
        // Cancel physical alarm
        await sl<AlarmPlatform>().cancelAlarm(id);
        // Mark as CANCELLED in db
        await db.update(
          'pending_reminders',
          {'state': 'CANCELLED', 'updatedAt': nowMs},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    // Schedule next reminders based on routine_occurrences for today and tomorrow
    final todayStr = now.toIso8601String().substring(0, 10);
    final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);

    // Query pending/snoozed occurrences for today and tomorrow
    final occurrences = await db.query(
      'routine_occurrences',
      where: "(status = 'pending' OR status = 'snoozed') AND (date = ? OR date = ?)",
      whereArgs: [todayStr, tomorrowStr],
    );

    for (final occ in occurrences) {
      final rId = occ['routine_id']! as String;
      final dateStr = occ['date']! as String;
      final rawTime = occ['scheduled_time'] as String?;
      if (rawTime == null || rawTime.trim().isEmpty) {
        // Skip scheduling arbitrary alarm for routines without a scheduled time
        continue;
      }
      final timeStr = rawTime.trim();
      final status = occ['status']! as String;

      final rMap = routinesMap[rId];
      if (rMap == null) continue;

      final title = rMap['title']! as String;
      final isEssential = rMap['isEssential'] == 1;

      final sched = schedules.firstWhere((s) => s['routineId'] == rId, orElse: () => <String, dynamic>{});
      if (sched.isEmpty) continue;
      final scheduleId = sched['id']! as String;

      // Parse schedule/reminder time
      final timeParts = timeStr.split(':');
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final dateParts = dateStr.split('-');
      final year = int.tryParse(dateParts[0]) ?? now.year;
      final month = int.tryParse(dateParts[1]) ?? now.month;
      final day = int.tryParse(dateParts[2]) ?? now.day;

      final reminderOffset = rMap['reminderOffsetMinutes'] as int? ?? 0;
      final targetTime = DateTime(year, month, day, hour, minute);
      var scheduledMs = targetTime.subtract(Duration(minutes: reminderOffset)).millisecondsSinceEpoch;

      if (scheduledMs <= nowMs && status == 'pending') {
        // If it's in the past and pending, it was missed/expired
        continue;
      }

      // Unique ID keying to prevent duplicates (Idempotency)
      final reminderId = 'rem_${rId}_${scheduleId}_${dateStr}_${timeStr.replaceAll(':', '')}';

      // Check if reminder already exists
      final existingReminder = await db.query(
        'pending_reminders',
        where: 'id = ?',
        whereArgs: [reminderId],
      );

      if (existingReminder.isNotEmpty) {
        final remState = existingReminder.first['state']! as String;
        final snoozeTime = existingReminder.first['snoozeUntil'] as int?;

        // If it was snoozed/delayed, make sure it is scheduled for the snooze time
        if (remState == 'delayed' && snoozeTime != null && snoozeTime > nowMs) {
          scheduledMs = snoozeTime;
          // Register physical Alarm
          await sl<AlarmPlatform>().scheduleExactAlarm(
            id: reminderId,
            timeMsUTC: scheduledMs,
            title: title,
            isEssential: isEssential,
          );
        }
        continue;
      }

      // Apply calendar behavior filter
      final behavior = exceptionsMap[dateStr] ?? 'NORMAL';
      if (behavior == 'SILENCE_ALL' || (behavior == 'ESSENTIAL_ONLY' && !isEssential)) {
        continue;
      }

      // Insert new reminder with 'unknown' state
      await db.insert(
        'pending_reminders',
        {
          'id': reminderId,
          'routineId': rId,
          'scheduleId': scheduleId,
          'originalTime': targetTime.millisecondsSinceEpoch,
          'scheduledTime': scheduledMs,
          'state': 'unknown',
          'deferCount': 0,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Register physical Alarm with AlarmManager
      await sl<AlarmPlatform>().scheduleExactAlarm(
        id: reminderId,
        timeMsUTC: scheduledMs,
        title: title,
        isEssential: isEssential,
      );

      await DatabaseHelper.instance.logNotificationEvent(
        routineId: rId,
        actionTaken: 'sent',
        notificationType: 'ROUTINE',
      );

      await CentralInboxService.push(
        category: InboxCategory.REMINDER,
        sourceSystem: 'routines',
        entityId: rId,
        eventType: 'reminder',
        title: title,
        body: 'زمان انجام روتین فرا رسیده است',
        priority: isEssential ? 2 : 0,
        linkModule: 'routines',
        linkEntityId: rId,
        linkAction: 'open_detail',
        dateBucket: dateStr,
      );
    }

    // Schedule private cycle reminders if gender is FEMALE and consent is granted
    final cycleConsentReminders = settingsMap['cycle_consent_reminders'] == 'true';
    final cycleModuleEnabled = settingsMap['module_cycle_enabled'] == 'true';
    final isFemale = CyclePrivacyGuard.isVisible(settingsMap);

    if (isFemale && cycleModuleEnabled && cycleConsentReminders) {
      final periods = await db.query('cycle_periods', orderBy: 'startDate DESC', limit: 1);
      if (periods.isNotEmpty) {
        final latestPeriod = periods.first;
        final start = DateTime.parse(latestPeriod['startDate']! as String);
        final cycleLength = int.tryParse(settingsMap['cycle_avg_length'] ?? '28') ?? 28;
        final daysSinceStart = now.difference(start).inDays;
        final cyclesElapsed = (daysSinceStart / cycleLength).floor() + 1;
        final nextPeriodStart = start.add(Duration(days: cyclesElapsed * cycleLength));

        final offsets = [-7, -3, -1, 0];
        for (final offset in offsets) {
          final reminderTime = DateTime(
            nextPeriodStart.year,
            nextPeriodStart.month,
            nextPeriodStart.day,
            9, // 9:00 AM
          ).add(Duration(days: offset));
          final reminderMs = reminderTime.millisecondsSinceEpoch;

          // Only schedule if in future and within next 48 hours
          if (reminderMs > nowMs && reminderMs < nowMs + 48 * 3600 * 1000) {
            final reminderId = 'cycle_rem_${nextPeriodStart.toIso8601String().substring(0, 10)}_$offset';
            
            final existing = await db.query(
              'pending_reminders',
              where: 'id = ?',
              whereArgs: [reminderId],
            );

            if (existing.isEmpty) {
              await db.insert('pending_reminders', {
                'id': reminderId,
                'routineId': 'cycle_private_reminder',
                'scheduleId': 'cycle_schedule',
                'originalTime': reminderMs,
                'scheduledTime': reminderMs,
                'state': 'unknown',
                'deferCount': 0,
                'createdAt': nowMs,
                'updatedAt': nowMs,
              });

              await sl<AlarmPlatform>().scheduleExactAlarm(
                id: reminderId,
                timeMsUTC: reminderMs,
                title: 'یک یادداشت خصوصی برایت آماده است',
                isEssential: false,
              );

              await DatabaseHelper.instance.logNotificationEvent(
                routineId: 'cycle_private_reminder',
                actionTaken: 'sent',
                notificationType: 'CYCLE',
              );
            }
          }
        }
      }
    }

    // Finally, update shared snapshot
    await SnapshotSyncService.syncAll();
  }

  /// Completes an occurrence, saves to completions, updates occurrence, cancels alarm
  static Future<void> completeOccurrence(String routineId, String dateStr, {String resultType = 'FULL', int? durationMinutes}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      // 1. Insert or Update completion (upsert check)
      final scheduleList = await txn.query(
        'routine_schedules',
        where: 'routineId = ?',
        whereArgs: [routineId],
        limit: 1,
      );
      final isInterval = scheduleList.isNotEmpty &&
          (scheduleList.first['intervalHours'] as int? ?? 0) > 0;

      var shouldInsert = true;
      if (!isInterval) {
        final existing = await txn.query(
          'routine_completions',
          where: 'routineId = ? AND completionDate = ?',
          whereArgs: [routineId, dateStr],
        );

        if (existing.isNotEmpty) {
          shouldInsert = false;
          await txn.update(
            'routine_completions',
            {
              'completionTime': now,
              'resultType': resultType,
              'durationMinutes': durationMinutes,
              'actual_duration_minutes': durationMinutes,
              'createdAt': now,
            },
            where: 'routineId = ? AND completionDate = ?',
            whereArgs: [routineId, dateStr],
          );
        }
      }

      if (shouldInsert) {
        await txn.insert('routine_completions', {
          'id': 'comp_${routineId}_$now',
          'routineId': routineId,
          'completionDate': dateStr,
          'completionTime': now,
          'resultType': resultType,
          'resultSource': 'USER',
          'durationMinutes': durationMinutes,
          'actual_duration_minutes': durationMinutes,
          'createdAt': now,
        });
      }

      // Invoke progression engine logic on successful completion
      await ProgressionEngine().onCompletion(txn, routineId);

      // 2. Update occurrence status
      await txn.update(
        'routine_occurrences',
        {'status': 'done'},
        where: 'routine_id = ? AND date = ?',
        whereArgs: [routineId, dateStr],
      );

      // 3. Update pending_reminders state to 'opened'
      final dateDateTime = DateTime.parse(dateStr);
      final startOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day, 23, 59, 59).millisecondsSinceEpoch;

      final reminders = await txn.query(
        'pending_reminders',
        where: 'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
        whereArgs: [routineId, 'unknown', 'delayed', 'sent', startOfDay, endOfDay],
      );

      for (final rem in reminders) {
        final remId = rem['id']! as String;
        alarmsToCancel.add(remId);
        await txn.update(
          'pending_reminders',
          {'state': 'opened', 'updatedAt': now},
          where: 'id = ?',
          whereArgs: [remId],
        );
      }

      await DatabaseHelper.instance.logNotificationEvent(
        routineId: routineId,
        actionTaken: 'opened',
        notificationType: 'ROUTINE',
        executor: txn,
      );

      await CentralInboxService.markActionedForEntity('routines', routineId, executor: txn);
    });

    // Run native cancel alarms outside the transaction
    for (final remId in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(remId);
    }

    // Run syncAll outside the transaction
    await SnapshotSyncService.syncAll();

    // Invalidate the agenda cache for the target date so the UI refreshes correctly
    DayAgendaService.instance.invalidateDate(dateStr);
  }

  /// Reverts a routine occurrence completion back to 'pending', deletes completion record, and restores alarms.
  static Future<void> undoCompletion(String routineId, String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // 1. Delete completion record
      await txn.delete(
        'routine_completions',
        where: 'routineId = ? AND completionDate = ?',
        whereArgs: [routineId, dateStr],
      );

      // 2. Revert occurrence status to 'pending'
      await txn.update(
        'routine_occurrences',
        {'status': 'pending'},
        where: 'routine_id = ? AND date = ?',
        whereArgs: [routineId, dateStr],
      );

      // 3. Revert reminders today back to 'unknown' if they were 'opened'
      final dateDateTime = DateTime.parse(dateStr);
      final startOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day, 23, 59, 59).millisecondsSinceEpoch;

      await txn.update(
        'pending_reminders',
        {'state': 'unknown', 'updatedAt': now},
        where: 'routineId = ? AND state = ? AND scheduledTime >= ? AND scheduledTime <= ?',
        whereArgs: [routineId, 'opened', startOfDay, endOfDay],
      );
    });

    // Run syncAll and reschedule alarms immediately
    await SnapshotSyncService.syncAll();
    await scheduleNextAlarms();

    // Invalidate the agenda cache for the target date so the UI refreshes correctly
    DayAgendaService.instance.invalidateDate(dateStr);
  }

  /// Skips an occurrence, updates occurrence status to skipped, cancels alarm
  static Future<void> skipOccurrence(String routineId, String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      // 1. Insert skip into completions (upsert check)
      final existing = await txn.query(
        'routine_completions',
        where: 'routineId = ? AND completionDate = ?',
        whereArgs: [routineId, dateStr],
      );

      if (existing.isNotEmpty) {
        await txn.update(
          'routine_completions',
          {
            'completionTime': now,
            'resultType': 'SKIPPED',
            'createdAt': now,
          },
          where: 'routineId = ? AND completionDate = ?',
          whereArgs: [routineId, dateStr],
        );
      } else {
        await txn.insert('routine_completions', {
          'id': 'comp_${routineId}_$now',
          'routineId': routineId,
          'completionDate': dateStr,
          'completionTime': now,
          'resultType': 'SKIPPED',
          'resultSource': 'USER',
          'createdAt': now,
        });
      }

      // 2. Update occurrence status
      await txn.update(
        'routine_occurrences',
        {'status': 'skipped'},
        where: 'routine_id = ? AND date = ?',
        whereArgs: [routineId, dateStr],
      );

      // 3. Update pending_reminders state to 'opened'
      final dateDateTime = DateTime.parse(dateStr);
      final startOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day, 23, 59, 59).millisecondsSinceEpoch;

      final reminders = await txn.query(
        'pending_reminders',
        where: 'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
        whereArgs: [routineId, 'unknown', 'delayed', 'sent', startOfDay, endOfDay],
      );

      for (final rem in reminders) {
        final remId = rem['id']! as String;
        alarmsToCancel.add(remId);
        await txn.update(
          'pending_reminders',
          {'state': 'opened', 'updatedAt': now},
          where: 'id = ?',
          whereArgs: [remId],
        );
      }

      await DatabaseHelper.instance.logNotificationEvent(
        routineId: routineId,
        actionTaken: 'opened',
        notificationType: 'ROUTINE',
        executor: txn,
      );

      await CentralInboxService.markActionedForEntity('routines', routineId, executor: txn);
    });

    // Run native cancel alarms outside the transaction
    for (final remId in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(remId);
    }

    await SnapshotSyncService.syncAll();
  }

  /// Snoozes a reminder, updates reminder and occurrence status, registers new alarm
  static Future<void> snoozeReminder(String reminderId, int snoozeMinutes) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final snoozeUntilMs = nowMs + (snoozeMinutes * 60 * 1000);

    String? rId;
    String? title;
    var isEssential = false;

    await db.transaction((txn) async {
      final reminders = await txn.query(
        'pending_reminders',
        where: 'id = ?',
        whereArgs: [reminderId],
      );

      if (reminders.isNotEmpty) {
        final rem = reminders.first;
        rId = rem['routineId']! as String;
        final origTimeMs = rem['originalTime']! as int;
        final dateStr = DateTime.fromMillisecondsSinceEpoch(origTimeMs).toIso8601String().substring(0, 10);

        // 1. Update reminder columns
        await txn.update(
          'pending_reminders',
          {
            'state': 'delayed',
            'snoozeUntil': snoozeUntilMs,
            'scheduledTime': snoozeUntilMs,
            'deferCount': (rem['deferCount']! as int) + 1,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [reminderId],
        );

        // 2. Update occurrence status
        await txn.update(
          'routine_occurrences',
          {'status': 'snoozed'},
          where: 'routine_id = ? AND date = ?',
          whereArgs: [rId, dateStr],
        );

        // 3. Load routine details for alarm configuration
        final routineList = await txn.query('routines', where: 'id = ?', whereArgs: [rId], limit: 1);
        title = routineList.isNotEmpty ? routineList.first['title']! as String : 'روتین';
        isEssential = routineList.isNotEmpty && routineList.first['isEssential'] == 1;

        await DatabaseHelper.instance.logNotificationEvent(
          routineId: rId,
          actionTaken: 'delayed',
          notificationType: 'ROUTINE',
          executor: txn,
        );
      }
    });

    // 4. Register physical Alarm outside transaction
    if (rId != null) {
      await sl<AlarmPlatform>().cancelAlarm(reminderId);
      await sl<AlarmPlatform>().scheduleExactAlarm(
        id: reminderId,
        timeMsUTC: snoozeUntilMs,
        title: title ?? 'روتین',
        isEssential: isEssential,
      );

      await SnapshotSyncService.syncAll();
    }
  }

  /// Triggered when a routine completion is logged.
  /// Handles interval-based schedules by setting the next alarm.
  static Future<void> onRoutineCompleted(String routineId, DateTime completionTime) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Load active routine schedules
    final schedules = await db.query(
      'routine_schedules',
      where: 'routineId = ? AND scheduleType = ?',
      whereArgs: [routineId, 'INTERVAL'],
    );

    if (schedules.isNotEmpty) {
      final sMap = schedules.first;
      final scheduleId = sMap['id']! as String;
      final intervalHours = sMap['intervalHours'] as int? ?? 4;

      final nextAlarmTime = completionTime.add(Duration(hours: intervalHours));
      final nextAlarmMs = nextAlarmTime.millisecondsSinceEpoch;

      final routineRes = await db.query('routines', where: 'id = ?', whereArgs: [routineId], limit: 1);
      if (routineRes.isNotEmpty) {
        final title = routineRes.first['title']! as String;
        final isEssential = routineRes.first['isEssential'] == 1;

        final reminderId = 'rem_${routineId}_${scheduleId}_$nextAlarmMs';

        await db.insert(
          'pending_reminders',
          {
            'id': reminderId,
            'routineId': routineId,
            'scheduleId': scheduleId,
            'originalTime': nextAlarmMs,
            'scheduledTime': nextAlarmMs,
            'state': 'unknown',
            'deferCount': 0,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Register exact alarm
        await sl<AlarmPlatform>().scheduleExactAlarm(
          id: reminderId,
          timeMsUTC: nextAlarmMs,
          title: title,
          isEssential: isEssential,
        );
        await DatabaseHelper.instance.logNotificationEvent(
          routineId: routineId,
          actionTaken: 'sent',
          notificationType: 'ROUTINE',
        );
      }
    }

    // Schedule persistent status notification update alarms for midnight and zone changes
    await _scheduleStatusUpdateAlarms(db, DateTime.now());

    // Sync state
    await SnapshotSyncService.syncAll();
  }

  static Future<void> _scheduleStatusUpdateAlarms(Database db, DateTime now) async {
    // 1. Midnight update alarm
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    await sl<AlarmPlatform>().scheduleExactAlarm(
      id: 'status_update_midnight',
      timeMsUTC: nextMidnight.millisecondsSinceEpoch,
      title: 'REFRESH_STATUS',
      isEssential: true,
    );

    // 2. Zone schedules transitions
    try {
      final zoneSchedules = await db.query('zone_schedules');
      final todayStr = now.toIso8601String().substring(0, 10);
      final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);

      final transitionTimesMs = <int>{};

      for (final sched in zoneSchedules) {
        final start = sched['startTime'] as String? ?? '09:00';
        final end = sched['endTime'] as String? ?? '17:00';
        
        for (final dateStr in [todayStr, tomorrowStr]) {
          for (final timeStr in [start, end]) {
            final parts = timeStr.split(':');
            if (parts.length == 2) {
              final h = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              final dateParts = dateStr.split('-');
              final dt = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
                h,
                m,
              );
              if (dt.isAfter(now)) {
                transitionTimesMs.add(dt.millisecondsSinceEpoch);
              }
            }
          }
        }
      }

      final sortedTimes = transitionTimesMs.toList()..sort();
      final timesToSchedule = sortedTimes.take(5);

      var idx = 0;
      for (final timeMs in timesToSchedule) {
        await sl<AlarmPlatform>().scheduleExactAlarm(
          id: 'status_update_zone_${idx++}',
          timeMsUTC: timeMs,
          title: 'REFRESH_STATUS',
          isEssential: true,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling zone transition status updates: $e');
    }
  }

  /// Cancels all alarms for a given routine.
  static Future<void> cancelAllAlarmsForRoutine(String routineId) async {
    final db = await DatabaseHelper.instance.database;

    // Query all scheduled pending reminders for this routine
    final pending = await db.query(
      'pending_reminders',
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [routineId],
    );

    for (final pMap in pending) {
      final id = pMap['id']! as String;
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    // Mark as CANCELLED in database
    await db.update(
      'pending_reminders',
      {'state': 'CANCELLED', 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [routineId],
    );

    // Sync state
    await SnapshotSyncService.syncAll();
  }

  static Future<void> cancel(String id) async {
    try {
      await sl<AlarmPlatform>().cancelAlarm(id);
    } catch (_) {}
  }
}

