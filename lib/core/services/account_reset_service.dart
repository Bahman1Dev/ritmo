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

    // 2. Perform transactional wipe across all database tables dynamically fetched from sqlite_master
    await db.transaction((txn) async {
      final tableRows = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );
      final tables = tableRows.map((r) => r['name'] as String).toList();

      for (final table in tables) {
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
