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
        Future<void> safeDelete(String table) async {
          try {
            await txn.delete(table);
          } catch (_) {}
        }

        Future<void> safeDeleteSettingsLike(String pattern) async {
          try {
            await txn.delete('app_settings', where: 'key LIKE ? AND key != ?', whereArgs: [pattern, key]);
          } catch (_) {}
        }

        Future<void> safeDeleteSettingExact(String exactKey) async {
          try {
            await txn.delete('app_settings', where: 'key = ?', whereArgs: [exactKey]);
          } catch (_) {}
        }

        switch (key) {
          case 'module_religion_enabled':
            await safeDelete('worship_debts');
            await safeDelete('worship_seasons');
            await safeDelete('worship_practices');
            await safeDelete('fasting_debt');
            await safeDeleteSettingsLike('religion_%');
            await safeDeleteSettingsLike('religious_%');
            await safeDeleteSettingsLike('worship_%');
            await safeDeleteSettingsLike('prayer_%');
            await safeDeleteSettingsLike('quran_%');
            await safeDeleteSettingsLike('fasting_%');
            await _safeDeleteRoutinesByCategory(txn, 'religious');
            break;

          case 'module_medicine_enabled':
            await safeDelete('medications');
            await safeDelete('medication_logs');
            await safeDelete('prn_logs');
            await safeDelete('doctor_visits');
            await safeDelete('blood_sugar_logs');
            await safeDelete('blood_pressure_logs');
            await safeDelete('vital_signs_logs');
            await safeDelete('medical_documents');
            await safeDelete('medical_document_images');
            await safeDelete('vaccinations');
            await safeDelete('allergies');
            await safeDelete('medical_profile');
            await safeDelete('pregnancy_tracker');
            await safeDelete('pregnancy_checkups');
            await safeDelete('pregnancy_symptoms');
            await safeDelete('kick_counts');
            await safeDelete('contraction_timer');
            await safeDeleteSettingsLike('health_%');
            await safeDeleteSettingsLike('medical_%');
            await safeDeleteSettingsLike('medication_%');
            await safeDeleteSettingsLike('medicine_%');
            await _safeDeleteRoutinesByCategory(txn, 'medical');
            break;

          case 'module_sports_enabled':
            await safeDelete('workout_logs');
            await safeDelete('workout_split_days');
            await safeDelete('workout_recovery_logs');
            await safeDeleteSettingsLike('sports_%');
            await safeDeleteSettingsLike('workout_%');
            await _safeDeleteRoutinesByCategory(txn, 'sports');
            break;

          case 'module_supplementary_sports_enabled':
            await safeDelete('ss_user_profile');
            await safeDelete('ss_workout_plan');
            await safeDelete('ss_workout_exercise_crossref');
            await safeDelete('ss_workout_session_log');
            await safeDelete('ss_exercise_feeling_log');
            await safeDelete('ss_plan_version_history');
            await safeDelete('ss_decision_log');
            await safeDelete('ss_weight_log');
            await safeDelete('ss_workout_set_log');
            await safeDeleteSettingsLike('ss_%');
            break;

          case 'module_cycle_enabled':
            await safeDelete('cycle_logs');
            await safeDelete('cycle_periods');
            await safeDelete('cycle_day_logs');
            await safeDelete('cycle_reminders_config');
            await safeDeleteSettingsLike('cycle_%');
            await safeDeleteSettingsLike('period_%');
            await safeDeleteSettingExact('show_cycle_in_calendar');
            await safeDeleteSettingExact('period_duration_days');
            try {
              await txn.delete('worship_debts', where: "id LIKE 'debt_cycle_fast_%'");
            } catch (_) {}
            break;

          case 'module_courses_enabled':
            await safeDelete('courses');
            await safeDelete('course_sessions');
            await safeDelete('course_logs');
            await safeDeleteSettingsLike('courses_%');
            await safeDeleteSettingsLike('course_%');
            break;

          case 'module_goals_enabled':
            await safeDelete('goals');
            await safeDelete('goal_steps');
            await safeDeleteSettingsLike('goals_%');
            await safeDeleteSettingsLike('goal_%');
            break;

          case 'module_assistant_enabled':
            await safeDelete('assistant_chats');
            await safeDelete('assistant_audit_log');
            await safeDelete('assistant_threads');
            await safeDelete('assistant_suggestions');
            await safeDeleteSettingsLike('assistant_%');
            break;

          case 'module_konkur_enabled':
            await safeDelete('konkur_subjects');
            await safeDelete('konkur_topics');
            await safeDelete('konkur_mock_exams');
            await safeDelete('konkur_mock_exam_results');
            await safeDelete('konkur_study_sessions');
            await safeDelete('konkur_plan_items');
            await safeDeleteSettingsLike('konkur_%');
            break;

          case 'module_energy_enabled':
            await safeDelete('energy_logs');
            await safeDelete('mood_logs');
            await safeDeleteSettingsLike('energy_%');
            await safeDeleteSettingsLike('mood_%');
            break;

          case 'module_sleep_enabled':
            await safeDelete('sleep_logs');
            await safeDelete('bedtime_diagnostics');
            await safeDeleteSettingsLike('sleep_%');
            await safeDeleteSettingsLike('bedtime_%');
            break;

          case 'module_progressive_habits_enabled':
            await safeDelete('daily_checkins');
            await safeDelete('daily_reflections');
            await safeDeleteSettingsLike('habit_%');
            await safeDeleteSettingsLike('reflection_%');
            await safeDeleteSettingsLike('checkin_%');
            await _safeDeleteRoutinesByCategory(txn, 'habits');
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

  static Future<void> _safeDeleteRoutinesByCategory(DatabaseExecutor txn, String category) async {
    final rows = await txn.query('routines', columns: ['id'], where: 'category = ?', whereArgs: [category]);
    for (final row in rows) {
      final rId = row['id'] as String;
      await txn.delete('pending_reminders', where: 'routineId = ?', whereArgs: [rId]);
      await txn.delete('routine_occurrences', where: 'routine_id = ?', whereArgs: [rId]);
      await txn.delete('routine_completions', where: 'routineId = ?', whereArgs: [rId]);
      await txn.delete('routine_logs', where: 'routineId = ?', whereArgs: [rId]);
      await txn.delete('routine_schedules', where: 'routineId = ?', whereArgs: [rId]);
      await txn.delete('routines', where: 'id = ?', whereArgs: [rId]);
    }
  }
}
