import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/database/database_helper.dart';

class PersonaGate {
  static Future<Set<DataDomain>> readableDomains(String personaId) async {
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('app_settings');
    final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};

    bool isEnabled(String key, bool defaultValue) {
      final val = settingsMap[key];
      if (val == null) return defaultValue;
      return val == 'true';
    }

    final cloudConsent = isEnabled('assistant_cloud_consent', true);
    if (!cloudConsent) return const {};

    final readable = <DataDomain>{};

    // cycles
    if (personaId == 'cycle' && isEnabled('module_cycle_enabled', false) && isEnabled('ai_domain_cycle_read', false)) {
      readable.add(DataDomain.cycle);
    }
    // medical
    if (personaId == 'health' && isEnabled('module_medicine_enabled', false) && isEnabled('ai_domain_medical_read', false)) {
      readable.add(DataDomain.medical);
    }
    // reflection
    if (isEnabled('ai_domain_reflection_read', false)) {
      readable.add(DataDomain.reflection);
    }

    // General domains allowed for appropriate personas
    // Routines
    if (isEnabled('module_today_routines', true) || isEnabled('module_progressive_habits_enabled', false)) {
      readable.add(DataDomain.routines);
    }
    // Goals
    if (isEnabled('module_goals_enabled', false)) {
      readable.add(DataDomain.goals);
    }
    // Worship
    if (isEnabled('module_religion_enabled', false)) {
      readable.add(DataDomain.worship);
    }
    // Study
    if (isEnabled('module_study_enabled', false)) {
      readable.add(DataDomain.konkur);
    }
    // Courses
    if (isEnabled('module_courses_enabled', false)) {
      readable.add(DataDomain.courses);
    }
    // Sports
    if (isEnabled('module_sports_enabled', false)) {
      readable.add(DataDomain.sports);
    }
    // Sleep
    if (isEnabled('module_sleep_enabled', false)) {
      readable.add(DataDomain.sleep);
    }
    // Energy
    if (isEnabled('module_energy_enabled', false)) {
      readable.add(DataDomain.energy);
    }

    return readable;
  }

  static Future<bool> canWriteDomain(String personaId, Set<DataDomain> touches) async {
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('app_settings');
    final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};

    bool isEnabled(String key, bool defaultValue) {
      final val = settingsMap[key];
      if (val == null) return defaultValue;
      return val == 'true';
    }

    for (final domain in touches) {
      if (domain == DataDomain.medical) {
        // Medical write is strictly forbidden at registry level
        return false;
      }
      if (domain == DataDomain.cycle) {
        if (!isEnabled('module_cycle_enabled', false) || !isEnabled('ai_domain_cycle_write', false)) {
          return false;
        }
      }
      // Other domains check if their modules are enabled
      if (domain == DataDomain.routines && !isEnabled('module_today_routines', true)) return false;
      if (domain == DataDomain.goals && !isEnabled('module_goals_enabled', false)) return false;
      if (domain == DataDomain.worship && !isEnabled('module_religion_enabled', false)) return false;
      if (domain == DataDomain.konkur && !isEnabled('module_study_enabled', false)) return false;
      if (domain == DataDomain.courses && !isEnabled('module_courses_enabled', false)) return false;
      if (domain == DataDomain.sports && !isEnabled('module_sports_enabled', false)) return false;
      if (domain == DataDomain.sleep && !isEnabled('module_sleep_enabled', false)) return false;
      if (domain == DataDomain.energy && !isEnabled('module_energy_enabled', false)) return false;
    }
    return true;
  }
}
