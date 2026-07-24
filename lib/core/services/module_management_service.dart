import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:sqflite/sqflite.dart';

/// Central Single Source of Truth for Module Activation & Synchronization in Ritmo.
class ModuleManagementService {
  ModuleManagementService._();
  static final ModuleManagementService instance = ModuleManagementService._();

  /// Canonical list of all module keys in Ritmo
  static const List<String> allModuleKeys = [
    'module_religion_enabled',
    'module_medicine_enabled',
    'module_sports_enabled',
    'module_supplementary_sports_enabled',
    'module_cycle_enabled',
    'module_courses_enabled',
    'module_goals_enabled',
    'module_assistant_enabled',
    'module_konkur_enabled',
    'module_energy_enabled',
    'module_sleep_enabled',
    'module_progressive_habits_enabled',
  ];

  /// Fetches all module enable flags atomically from SQLite `app_settings`
  Future<Map<String, bool>> getAllModuleStates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final settingsMap = <String, String>{
        for (final s in settings) s['key']! as String: s['value']! as String
      };

      final states = <String, bool>{};
      for (final key in allModuleKeys) {
        states[key] = settingsMap[key] == 'true';
      }
      return states;
    } catch (e) {
      debugPrint('ModuleManagementService: Error fetching module states: $e');
      return {};
    }
  }

  /// Check if a specific module is enabled
  Future<bool> isModuleEnabled(String key) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) {
        return result.first['value'] == 'true';
      }
    } catch (e) {
      debugPrint('ModuleManagementService: Error checking module $key: $e');
    }
    return false;
  }

  /// Sets a module enabled state with guaranteed atomic upsert, alarm cleanup/rescheduling,
  /// and global event bus notification.
  Future<void> setModuleEnabled(String key, bool enabled) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Atomic Replace into app_settings (Never fails even if key was missing)
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': enabled.toString(),
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Alarm Scheduler handling when disabling specific modules
      if (!enabled) {
        final categoryName = key == 'module_religion_enabled'
            ? 'religious'
            : key == 'module_medicine_enabled'
                ? 'medical'
                : '';

        if (categoryName.isNotEmpty) {
          final routines = await db.query(
            'routines',
            where: 'category = ?',
            whereArgs: [categoryName],
          );
          for (final r in routines) {
            final id = r['id']! as String;
            await AlarmSchedulerService.cancelAllAlarmsForRoutine(id);
          }
        }
      } else {
        await AlarmSchedulerService.scheduleNextAlarms();
      }

      // 3. Broadcast global event to notify all listeners (UI screens, engines, services)
      RitmoEvents.notifyRoutineChanged();
    } catch (e) {
      debugPrint('ModuleManagementService: Error setting module $key to $enabled: $e');
    }
  }

  /// Safely clear/reset all data associated with a specific module in SQLite.
  Future<void> resetModuleData(String key) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        void safeDelete(String table) async {
          try {
            await txn.delete(table);
          } catch (_) {}
        }

        void safeDeleteSettingsLike(String pattern) async {
          try {
            await txn.delete('app_settings', where: 'key LIKE ? AND key != ?', whereArgs: [pattern, key]);
          } catch (_) {}
        }

        switch (key) {
          case 'module_religion_enabled':
            safeDelete('worship_debts');
            safeDelete('worship_seasons');
            safeDelete('worship_practices');
            safeDelete('fasting_debt');
            safeDeleteSettingsLike('religion_%');
            safeDeleteSettingsLike('worship_%');
            safeDeleteSettingsLike('prayer_%');
            try {
              await txn.rawDelete("DELETE FROM routine_logs WHERE routineId IN (SELECT id FROM routines WHERE category = 'religious')");
              await txn.delete('routines', where: "category = 'religious'");
            } catch (_) {}
            break;

          case 'module_medicine_enabled':
            safeDelete('medications');
            safeDelete('medication_logs');
            safeDelete('prn_logs');
            safeDelete('doctor_visits');
            safeDelete('blood_sugar_logs');
            safeDelete('blood_pressure_logs');
            safeDelete('vital_signs_logs');
            safeDelete('medical_documents');
            safeDelete('medical_document_images');
            safeDelete('vaccinations');
            safeDelete('allergies');
            safeDelete('medical_profile');
            safeDelete('pregnancy_tracker');
            safeDelete('pregnancy_checkups');
            safeDelete('pregnancy_symptoms');
            safeDelete('kick_counts');
            safeDelete('contraction_timer');
            safeDeleteSettingsLike('health_%');
            safeDeleteSettingsLike('medical_%');
            safeDeleteSettingsLike('medication_%');
            try {
              await txn.rawDelete("DELETE FROM routine_logs WHERE routineId IN (SELECT id FROM routines WHERE category = 'medical')");
              await txn.delete('routines', where: "category = 'medical'");
            } catch (_) {}
            break;

          case 'module_sports_enabled':
          case 'module_supplementary_sports_enabled':
            safeDelete('workout_logs');
            safeDelete('workout_split_days');
            safeDelete('workout_recovery_logs');
            safeDelete('ss_user_profile');
            safeDelete('ss_workout_plans');
            safeDelete('ss_workout_sessions');
            safeDelete('ss_exercise_logs');
            safeDelete('ss_favorites');
            safeDeleteSettingsLike('sports_%');
            safeDeleteSettingsLike('ss_%');
            try {
              await txn.rawDelete("DELETE FROM routine_logs WHERE routineId IN (SELECT id FROM routines WHERE category = 'sports')");
              await txn.delete('routines', where: "category = 'sports'");
            } catch (_) {}
            break;

          case 'module_cycle_enabled':
            safeDelete('cycle_logs');
            safeDelete('cycle_periods');
            safeDelete('cycle_day_logs');
            safeDelete('cycle_reminders_config');
            safeDeleteSettingsLike('cycle_%');
            break;

          case 'module_courses_enabled':
            safeDelete('courses');
            safeDelete('course_sessions');
            safeDelete('course_logs');
            safeDeleteSettingsLike('courses_%');
            safeDeleteSettingsLike('course_%');
            break;

          case 'module_goals_enabled':
            safeDelete('goals');
            safeDelete('goal_steps');
            safeDeleteSettingsLike('goals_%');
            safeDeleteSettingsLike('goal_%');
            break;

          case 'module_assistant_enabled':
            safeDelete('assistant_chats');
            safeDelete('assistant_audit_log');
            safeDelete('assistant_threads');
            safeDelete('assistant_suggestions');
            safeDeleteSettingsLike('assistant_%');
            break;

          case 'module_konkur_enabled':
            safeDelete('konkur_subjects');
            safeDelete('konkur_topics');
            safeDelete('konkur_mock_exams');
            safeDelete('konkur_mock_exam_results');
            safeDelete('konkur_study_sessions');
            safeDelete('konkur_plan_items');
            safeDeleteSettingsLike('konkur_%');
            break;

          case 'module_energy_enabled':
            safeDelete('energy_logs');
            safeDelete('mood_logs');
            safeDeleteSettingsLike('energy_%');
            safeDeleteSettingsLike('mood_%');
            break;

          case 'module_sleep_enabled':
            safeDelete('sleep_logs');
            safeDelete('bedtime_diagnostics');
            safeDeleteSettingsLike('sleep_%');
            break;

          case 'module_progressive_habits_enabled':
            safeDelete('daily_checkins');
            safeDelete('daily_reflections');
            safeDeleteSettingsLike('habit_%');
            safeDeleteSettingsLike('reflection_%');
            safeDeleteSettingsLike('checkin_%');
            try {
              await txn.rawDelete("DELETE FROM routine_logs WHERE routineId IN (SELECT id FROM routines WHERE category = 'habits')");
              await txn.delete('routines', where: "category = 'habits'");
            } catch (_) {}
            break;
        }

        // Set module enable flag to 'false' so it requires activation & onboarding
        final now = DateTime.now().millisecondsSinceEpoch;
        await txn.insert(
          'app_settings',
          {
            'key': key,
            'value': 'false',
            'updatedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      RitmoEvents.notifyRoutineChanged();
    } catch (e) {
      debugPrint('ModuleManagementService: Error resetting module data for $key: $e');
    }
  }
}
