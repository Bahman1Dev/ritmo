import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/database/legacy_database_recovery.dart';
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full transactional account and user data reset service.
class AccountResetService {
  static Future<void> wipeUserData() async {
    RitmoLog.info('AccountResetService', 'Starting transactional wipe of user data');

    final db = await DatabaseHelper.instance.database;

    // 1. Create emergency backup before wiping
    await LegacyDatabaseRecovery.createEmergencyBackup(db.path);

    // 2. Perform transactional wipe across all user data tables
    await db.transaction((txn) async {
      final userTables = [
        'routines',
        'routine_schedules',
        'routine_completions',
        'routine_occurrences',
        'skip_reasons',
        'goals',
        'goal_steps',
        'worship_completions',
        'worship_practices',
        'worship_debts',
        'fasting_debt',
        'cycle_periods',
        'cycle_logs',
        'ss_workout_plan',
        'ss_workout_exercise_crossref',
        'ss_workout_session_log',
        'ss_exercise_feeling_log',
        'ss_user_profile',
        'ss_decision_log',
        'ss_workout_set_log',
        'konkur_study_logs',
        'konkur_study_sessions',
        'konkur_mock_exam_results',
        'course_sessions',
        'course_active_timers',
        'health_logs',
        'allergies',
        'blood_pressure_logs',
        'blood_sugar_logs',
        'doctor_visits',
        'medical_documents',
        'medication_logs',
        'vaccinations',
        'vital_signs_logs',
        'notification_history',
        'pending_reminders',
        'active_timers',
        'daily_reflections',
        'ai_memory',
        'ss_ai_memory',
        'inbox_items',
        'app_settings',
      ];

      for (final table in userTables) {
        try {
          await txn.delete(table);
        } catch (e) {
          RitmoLog.warning('AccountResetService', 'Could not clear table $table: $e');
        }
      }
    });

    // 3. Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e, st) {
      RitmoLog.error('AccountResetService', 'Error clearing SharedPreferences', e, st);
    }

    // 4. Re-seed essential system settings
    await SeedService.seedSettings(db);
    RitmoLog.info('AccountResetService', 'Transactional wipe completed successfully');
  }
}
