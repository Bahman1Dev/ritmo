import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/foreground_notification_updater.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:sqflite/sqflite.dart';

abstract class KernelCommand {
  const KernelCommand();
}

class CreateRoutineCommand extends KernelCommand {

  const CreateRoutineCommand({
    required this.routineData,
    required this.scheduleData,
  });
  final Map<String, dynamic> routineData;
  final Map<String, dynamic> scheduleData;
}

class EditRoutineCommand extends KernelCommand {

  const EditRoutineCommand({
    required this.routineId,
    required this.routineData,
    required this.scheduleData,
    required this.applyToAll,
  });
  final String routineId;
  final Map<String, dynamic> routineData;
  final Map<String, dynamic> scheduleData;
  final bool applyToAll;
}

class DeleteRoutineCommand extends KernelCommand {

  const DeleteRoutineCommand({required this.routineId});
  final String routineId;
}

class CompleteOccurrenceCommand extends KernelCommand {

  const CompleteOccurrenceCommand({
    required this.routineId,
    required this.dateStr,
    required this.resultType,
    required this.durationMinutes,
    this.note,
  });
  final String routineId;
  final String dateStr;
  final String resultType;
  final int durationMinutes;
  final String? note;
}

class SkipOccurrenceCommand extends KernelCommand {

  const SkipOccurrenceCommand({
    required this.routineId,
    required this.dateStr,
    this.reason,
  });
  final String routineId;
  final String dateStr;
  final String? reason;
}

class SnoozeReminderCommand extends KernelCommand {

  const SnoozeReminderCommand({
    required this.reminderId,
    required this.snoozeMinutes,
  });
  final String reminderId;
  final int snoozeMinutes;
}

class ConfirmReshuffleCommand extends KernelCommand {

  const ConfirmReshuffleCommand({required this.actions});
  final List<ReshuffleAction> actions;
}

class RitmoExecutionKernel {
  RitmoExecutionKernel._internal();
  static final RitmoExecutionKernel instance = RitmoExecutionKernel._internal();

  final RitmoEventBus _eventBus = RitmoEventBus();

  Future<void> execute(KernelCommand command) async {
    final db = await DatabaseHelper.instance.database;

    // We will collect platform actions that need to run OUTSIDE the database transaction
    final platformActions = <Future<void> Function()>[];

    await db.transaction((txn) async {
      if (command is CreateRoutineCommand) {
        await _handleCreateRoutine(txn, command);
      } else if (command is EditRoutineCommand) {
        await _handleEditRoutine(txn, command, platformActions);
      } else if (command is DeleteRoutineCommand) {
        await _handleDeleteRoutine(txn, command, platformActions);
      } else if (command is CompleteOccurrenceCommand) {
        await _handleCompleteOccurrence(txn, command, platformActions);
      } else if (command is SkipOccurrenceCommand) {
        await _handleSkipOccurrence(txn, command, platformActions);
      } else if (command is SnoozeReminderCommand) {
        await _handleSnoozeReminder(txn, command, platformActions);
      } else if (command is ConfirmReshuffleCommand) {
        await _handleConfirmReshuffle(txn, command, platformActions);
      }
    });

    // Execute platform bridge actions outside the SQL transaction to prevent deadlocks and timing issues
    for (final action in platformActions) {
      try {
        await action();
      } catch (e) {
        debugPrint('Error executing platform action in REK: $e');
      }
    }

    // Trigger caches invalidations via event bus
    final nowTime = DateTime.now();
    if (command is CreateRoutineCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineCreated', timestamp: nowTime, payload: {'routineId': command.routineData['id']}));
    } else if (command is EditRoutineCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineEdited', timestamp: nowTime, payload: {'routineId': command.routineId}));
    } else if (command is DeleteRoutineCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineEdited', timestamp: nowTime, payload: {'routineId': command.routineId}));
    } else if (command is CompleteOccurrenceCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineCompleted', timestamp: nowTime, payload: {'routineId': command.routineId}));
    } else if (command is SkipOccurrenceCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineSkipped', timestamp: nowTime, payload: {'routineId': command.routineId}));
    } else if (command is SnoozeReminderCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineEdited', timestamp: nowTime, payload: {'reminderId': command.reminderId}));
    } else if (command is ConfirmReshuffleCommand) {
      _eventBus.fire(RitmoEvent(type: 'RoutineEdited', timestamp: nowTime, payload: {}));
    }

    // Central UI state notification triggering dashboard/profile/calendar rebuilds
    RitmoEvents.notifyRoutineChanged();
    
    // Update foreground persistent notification asynchronously
    unawaited(ForegroundNotificationUpdater.update());
  }

  /// Runs background/startup reconciliation to check if native tasks made any changes.
  Future<void> reconcileExternalState() async {
    // SnapshotSyncService.syncAll() internally runs backfillAndGenerateAll to optimize start up.
    await SnapshotSyncService.syncAll();
  }

  Future<void> _handleCreateRoutine(Transaction txn, CreateRoutineCommand cmd) async {
    final routineMap = Map<String, dynamic>.from(cmd.routineData);
    final mode = routineMap['progressionMode'] as String? ?? 'NONE';
    final start = routineMap['progressionStart'] as int? ?? 0;
    if (mode != 'NONE' && (routineMap['progressionCurrent'] == null || routineMap['progressionCurrent'] == 0)) {
      routineMap['progressionCurrent'] = start;
    }

    await txn.insert('routines', routineMap);
    await txn.insert('routine_schedules', cmd.scheduleData);

    final ruleMap = jsonDecode(cmd.scheduleData['recurrenceRule'] as String? ?? '{}');
    final rule = RecurrenceRule.fromMap(ruleMap);
    await RoutineOccurrenceGenerator.generateFutureOccurrences(txn, routineMap['id'] as String, rule);
  }

  Future<void> _handleEditRoutine(Transaction txn, EditRoutineCommand cmd, List<Future<void> Function()> platformActions) async {
    final id = cmd.routineId;
    await txn.update('routines', cmd.routineData, where: 'id = ?', whereArgs: [id]);
    await txn.update('routine_schedules', cmd.scheduleData, where: 'routineId = ?', whereArgs: [id]);

    final ruleMap = jsonDecode(cmd.scheduleData['recurrenceRule'] as String? ?? '{}');
    final rule = RecurrenceRule.fromMap(ruleMap);

    // Cancel existing alarms to prevent wrong alarm times
    final pending = await txn.query(
      'pending_reminders',
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      platformActions.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    await txn.update(
      'pending_reminders',
      {'state': 'CANCELLED', 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    // Regenerate occurrences based on scope
    if (cmd.applyToAll) {
      await txn.delete('routine_occurrences', where: 'routine_id = ?', whereArgs: [id]);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      for (var i = -30; i < 30; i++) {
        final targetDate = today.add(Duration(days: i));
        final dateStr = targetDate.toIso8601String().substring(0, 10);
        if (RoutineOccurrenceGenerator.shouldOccurOnDate(targetDate, rule)) {
          final timeStr = rule.reminderTimes.isNotEmpty ? rule.reminderTimes.first : '08:00';
          await txn.insert('routine_occurrences', {
            'routine_id': id,
            'date': dateStr,
            'scheduled_time': timeStr,
            'status': 'pending',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    } else {
      // Future scope
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await txn.delete('routine_occurrences', where: 'routine_id = ? AND date >= ?', whereArgs: [id, todayStr]);
      await RoutineOccurrenceGenerator.generateFutureOccurrences(txn, id, rule);
    }

    platformActions.add(SnapshotSyncService.syncAll);
  }

  Future<void> _handleDeleteRoutine(Transaction txn, DeleteRoutineCommand cmd, List<Future<void> Function()> platformActions) async {
    final id = cmd.routineId;

    // Archive or hard delete
    await txn.update(
      'routines',
      {'isArchived': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cancel existing alarms
    final pending = await txn.query(
      'pending_reminders',
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      platformActions.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    await txn.update(
      'pending_reminders',
      {'state': 'CANCELLED', 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    // Clear occurrences starting today
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await txn.delete('routine_occurrences', where: 'routine_id = ? AND date >= ?', whereArgs: [id, todayStr]);

    platformActions.add(SnapshotSyncService.syncAll);
  }

  Future<void> _handleCompleteOccurrence(Transaction txn, CompleteOccurrenceCommand cmd, List<Future<void> Function()> platformActions) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Insert completion record
    await txn.insert('routine_completions', {
      'id': 'comp_${cmd.routineId}_$now',
      'routineId': cmd.routineId,
      'completionDate': cmd.dateStr,
      'completionTime': now,
      'resultType': cmd.resultType,
      'resultSource': 'USER',
      'durationMinutes': cmd.durationMinutes,
      'actual_duration_minutes': cmd.durationMinutes,
      'note': cmd.note,
      'createdAt': now,
    });

    // Decrement medication stock count if it is a medical routine
    final routineRows = await txn.query('routines', columns: ['category', 'medStockCount'], where: 'id = ?', whereArgs: [cmd.routineId]);
    if (routineRows.isNotEmpty) {
      final category = routineRows.first['category'] as String? ?? '';
      final currentStock = routineRows.first['medStockCount'] as int? ?? 0;
      if (category.toLowerCase() == 'medical' && currentStock > 0) {
        await txn.update(
          'routines',
          {'medStockCount': currentStock - 1},
          where: 'id = ?',
          whereArgs: [cmd.routineId],
        );
      }
    }

    // Invoke progression engine logic on successful completion
    await ProgressionEngine().onCompletion(txn, cmd.routineId);

    // 2. Update occurrence status
    await txn.update(
      'routine_occurrences',
      {'status': 'done'},
      where: 'routine_id = ? AND date = ?',
      whereArgs: [cmd.routineId, cmd.dateStr],
    );

    // 3. Mark pending reminders as opened and cancel them
    final dateDateTime = DateTime.parse(cmd.dateStr);
    final startOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day, 23, 59, 59).millisecondsSinceEpoch;

    final reminders = await txn.query(
      'pending_reminders',
      where: 'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [cmd.routineId, 'unknown', 'delayed', 'sent', startOfDay, endOfDay],
    );

    for (final rem in reminders) {
      final remId = rem['id']! as String;
      platformActions.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
      await txn.update(
        'pending_reminders',
        {'state': 'opened', 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [remId],
      );
    }

    platformActions.add(() => DatabaseHelper.instance.logNotificationEvent(
      routineId: cmd.routineId,
      actionTaken: 'opened',
      notificationType: 'ROUTINE',
    ));
    platformActions.add(SnapshotSyncService.syncAll);
  }

  Future<void> _handleSkipOccurrence(Transaction txn, SkipOccurrenceCommand cmd, List<Future<void> Function()> platformActions) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Insert skip record into completions
    await txn.insert('routine_completions', {
      'id': 'comp_${cmd.routineId}_$now',
      'routineId': cmd.routineId,
      'completionDate': cmd.dateStr,
      'completionTime': now,
      'resultType': 'SKIPPED',
      'resultSource': 'USER',
      'note': cmd.reason,
      'createdAt': now,
    });

    // 2. Update occurrence status
    await txn.update(
      'routine_occurrences',
      {'status': 'skipped'},
      where: 'routine_id = ? AND date = ?',
      whereArgs: [cmd.routineId, cmd.dateStr],
    );

    // 3. Mark pending reminders as opened and cancel them
    final dateDateTime = DateTime.parse(cmd.dateStr);
    final startOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(dateDateTime.year, dateDateTime.month, dateDateTime.day, 23, 59, 59).millisecondsSinceEpoch;

    final reminders = await txn.query(
      'pending_reminders',
      where: 'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [cmd.routineId, 'unknown', 'delayed', 'sent', startOfDay, endOfDay],
    );

    for (final rem in reminders) {
      final remId = rem['id']! as String;
      platformActions.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
      await txn.update(
        'pending_reminders',
        {'state': 'opened', 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [remId],
      );
    }

    platformActions.add(() => DatabaseHelper.instance.logNotificationEvent(
      routineId: cmd.routineId,
      actionTaken: 'opened',
      notificationType: 'ROUTINE',
    ));
    platformActions.add(SnapshotSyncService.syncAll);
  }

  Future<void> _handleSnoozeReminder(Transaction txn, SnoozeReminderCommand cmd, List<Future<void> Function()> platformActions) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final snoozeUntilMs = nowMs + (cmd.snoozeMinutes * 60 * 1000);

    final reminders = await txn.query(
      'pending_reminders',
      where: 'id = ?',
      whereArgs: [cmd.reminderId],
    );

    if (reminders.isNotEmpty) {
      final rem = reminders.first;
      final rId = rem['routineId']! as String;
      final origTimeMs = rem['originalTime']! as int;
      final dateStr = DateTime.fromMillisecondsSinceEpoch(origTimeMs).toIso8601String().substring(0, 10);

      // 1. Update reminder status
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
        whereArgs: [cmd.reminderId],
      );

      // 2. Update occurrence status to snoozed
      await txn.update(
        'routine_occurrences',
        {'status': 'snoozed'},
        where: 'routine_id = ? AND date = ?',
        whereArgs: [rId, dateStr],
      );

      // 3. Schedule next platform alarm
      final routineList = await txn.query('routines', where: 'id = ?', whereArgs: [rId], limit: 1);
      final title = routineList.isNotEmpty ? routineList.first['title']! as String : 'روتین';
      final isEssential = routineList.isNotEmpty && routineList.first['isEssential'] == 1;

      platformActions.add(() async {
        await sl<AlarmPlatform>().cancelAlarm(cmd.reminderId);
        await sl<AlarmPlatform>().scheduleExactAlarm(
          id: cmd.reminderId,
          timeMsUTC: snoozeUntilMs,
          title: title,
          isEssential: isEssential,
        );
        await DatabaseHelper.instance.logNotificationEvent(
          routineId: rId,
          actionTaken: 'delayed',
          notificationType: 'ROUTINE',
        );
        await SnapshotSyncService.syncAll();
      });
    }
  }

  Future<void> _handleConfirmReshuffle(Transaction txn, ConfirmReshuffleCommand cmd, List<Future<void> Function()> platformActions) async {
    final now = DateTime.now();

    for (final action in cmd.actions) {
      if (action.actionType == ReshuffleActionType.shiftWithinZone ||
          action.actionType == ReshuffleActionType.shiftToNextZone ||
          action.actionType == ReshuffleActionType.moveToTomorrow) {

        if (action.newTime != null) {
          final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

          final reminders = await txn.query(
            'pending_reminders',
            where: 'routineId = ? AND (state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?',
            whereArgs: [action.routineId, 'unknown', 'delayed', startOfDay, endOfDay],
          );

          for (final rem in reminders) {
            final remId = rem['id']! as String;
            final newScheduledMs = action.newTime!.millisecondsSinceEpoch;

            await txn.update(
              'pending_reminders',
              {
                'scheduledTime': newScheduledMs,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [remId],
            );

            // Fetch info to reschedule alarm outside the transaction
            final routinesList = await txn.query('routines', where: 'id = ?', whereArgs: [action.routineId], limit: 1);
            final title = routinesList.isNotEmpty ? routinesList.first['title']! as String : action.routineTitle;
            final isEssential = routinesList.isNotEmpty && routinesList.first['isEssential'] == 1;

            platformActions.add(() async {
              await sl<AlarmPlatform>().cancelAlarm(remId);
              await sl<AlarmPlatform>().scheduleExactAlarm(
                id: remId,
                timeMsUTC: newScheduledMs,
                title: title,
                isEssential: isEssential,
              );
              await DatabaseHelper.instance.logNotificationEvent(
                routineId: action.routineId,
                actionTaken: 'sent',
                notificationType: 'ROUTINE',
              );
            });
          }
        }
      }
    }

    platformActions.add(SnapshotSyncService.syncAll);
  }
}

