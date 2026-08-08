import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV74PsychLayerSettings extends Migration {
  @override
  int get version => 74;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final defaults = {
      'motivation_diagnosis_enabled': 'true',
      'daily_budget_warning_enabled': 'true',
      'wip_limit_enabled': 'true',
      'wip_limit_count': '3',
      'cognitive_routing_enabled': 'false',
      'fresh_start_enabled': 'true',
      'capture_inbox_enabled': 'true',
      'mastery_pleasure_sampling_enabled': 'false',
      'mastery_decay_enabled': 'true',
    };

    for (final entry in defaults.entries) {
      await db.execute('''
        INSERT OR IGNORE INTO app_settings (key, value, updatedAt)
        VALUES ('${entry.key}', '${entry.value}', $nowMs);
      ''');
    }
  }

  @override
  Future<void> down(Database db) async {}
}
