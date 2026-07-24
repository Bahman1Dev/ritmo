import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/services/foreground_notification_updater.dart';
import 'package:sqflite/sqflite.dart';

@pragma('vm:entry-point')
void notificationActionDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ritmo.app/notif_action_bg');
  
  channel.setMethodCallHandler((call) async {
    if (call.method == 'handleAction') {
      final args = call.arguments as Map?;
      if (args != null) {
        final action = args['action'] as String?;
        final reminderId = args['reminderId'] as String?;
        if (action != null && reminderId != null) {
          await NotificationActionHandler.handle(action, reminderId);
        }
      }
      return true;
    } else if (call.method == 'completeRoutineDirect') {
      final args = call.arguments as Map?;
      if (args != null) {
        final routineId = args['routineId'] as String?;
        final dateStr = args['dateStr'] as String?;
        if (routineId != null && dateStr != null) {
          await RitmoExecutionKernel.instance.execute(
            CompleteOccurrenceCommand(
              routineId: routineId,
              dateStr: dateStr,
              resultType: 'FULL',
              durationMinutes: 0,
            ),
          );
        }
      }
      return true;
    } else if (call.method == 'changeZoneDirect') {
      final args = call.arguments as Map?;
      if (args != null) {
        final zoneId = args['zoneId'] as String?;
        if (zoneId != null) {
          final db = await DatabaseHelper.instance.database;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          
          if (zoneId.isEmpty || zoneId == 'default_zone') {
            await db.insert('app_settings', {'key': 'realm_override_id', 'value': '', 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
            await db.insert('app_settings', {'key': 'realm_override_until_ms', 'value': '0', 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            final untilMs = nowMs + 60 * 60 * 1000;
            await db.insert('app_settings', {'key': 'realm_override_id', 'value': zoneId, 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
            await db.insert('app_settings', {'key': 'realm_override_until_ms', 'value': untilMs.toString(), 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          
          RitmoEventBus().fire(RitmoEvent(
            type: 'ZoneChanged',
            timestamp: DateTime.now(),
            payload: {},
          ));
          RitmoEvents.notifyRoutineChanged();
          await ForegroundNotificationUpdater.update();
        }
      }
      return true;
    } else if (call.method == 'changeEnergyDirect') {
      final args = call.arguments as Map?;
      if (args != null) {
        final energy = args['energy'] as String?;
        if (energy != null) {
          final db = await DatabaseHelper.instance.database;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          
          await db.insert('app_settings', {'key': 'default_energy_level', 'value': energy.toUpperCase(), 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
          
          RitmoEventBus().fire(RitmoEvent(
            type: 'EnergyLogged',
            timestamp: DateTime.now(),
            payload: {},
          ));
          RitmoEvents.notifyRoutineChanged();
          await ForegroundNotificationUpdater.update();
        }
      }
      return true;
    } else if (call.method == 'updatePersistentStatus') {
      await ForegroundNotificationUpdater.update();
      return true;
    }
    return false;
  });

  // Signal Kotlin side that dispatcher is registered and ready to receive calls
  channel.invokeMethod('dispatcherReady');
}

class NotificationActionHandler {
  static Future<void> handle(String action, String reminderId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch the reminder record
      final List<Map<String, dynamic>> reminders = await db.query(
        'pending_reminders',
        where: 'id = ?',
        whereArgs: [reminderId],
      );

      if (reminders.isEmpty) {
        RitmoLog.warning('NOTIF', 'Reminder not found: $reminderId');
        return;
      }

      final reminder = reminders.first;
      final routineId = reminder['routineId'] as String;
      final originalTime = reminder['originalTime'] as int;

      // Formulate dateStr from originalTime (YYYY-MM-DD)
      final date = DateTime.fromMillisecondsSinceEpoch(originalTime);
      final dateStr = date.toIso8601String().substring(0, 10);

      RitmoLog.info('NOTIF', 'Processing action $action for reminder $reminderId (routine: $routineId, date: $dateStr)');

      // 2. Perform database actions based on action type
      switch (action) {
        case 'DONE':
          // Check if this is a real routine in routines table
          final List<Map<String, dynamic>> routines = await db.query(
            'routines',
            where: 'id = ?',
            whereArgs: [routineId],
          );
          
          if (routines.isNotEmpty) {
            await RitmoExecutionKernel.instance.execute(
              CompleteOccurrenceCommand(
                routineId: routineId,
                dateStr: dateStr,
                resultType: 'FULL',
                durationMinutes: 0,
              ),
            );
          } else {
            // Unregistered routine or special reminder (e.g. cycle privacy reminder)
            await db.update(
              'pending_reminders',
              {
                'state': 'opened',
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [reminderId],
            );
          }

        case 'SNOOZE':
          // Load snooze minutes from settings or default to 10
          final List<Map<String, dynamic>> settingsList = await db.query(
            'app_settings',
            where: 'key = ?',
            whereArgs: ['snooze_minutes'],
          );
          
          var snoozeMinutes = 10;
          if (settingsList.isNotEmpty) {
            snoozeMinutes = int.tryParse(settingsList.first['value'] as String) ?? 10;
          }

          await AlarmSchedulerService.snoozeReminder(reminderId, snoozeMinutes);

        case 'DISMISS':
          // Check if this is a real routine
          final List<Map<String, dynamic>> routines = await db.query(
            'routines',
            where: 'id = ?',
            whereArgs: [routineId],
          );

          if (routines.isNotEmpty) {
            await RitmoExecutionKernel.instance.execute(
              SkipOccurrenceCommand(
                routineId: routineId,
                dateStr: dateStr,
                reason: 'Dismissed from notification',
              ),
            );
          } else {
            await db.update(
              'pending_reminders',
              {
                'state': 'opened',
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [reminderId],
            );
          }

        default:
          RitmoLog.warning('NOTIF', 'Unknown action: $action');
      }

      // Re-trigger alarm synchronization to dismiss or reschedule alarms
      await AlarmSchedulerService.scheduleNextAlarms();
      
    } catch (e, stacktrace) {
      RitmoLog.error('NOTIF', 'Error handling action $action', e, stacktrace);
    }
  }
}
