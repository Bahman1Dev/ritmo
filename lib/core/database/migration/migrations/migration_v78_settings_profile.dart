import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV78SettingsProfile extends Migration {
  @override
  int get version => 78;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> put(String key, String value) => db.insert(
          'app_settings',
          {'key': key, 'value': value, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    // ۱. مقداردهی کلیدهای جدید تنظیمات در صورت عدم وجود
    final initialDefaults = <String, String>{
      'app_lock_enabled': 'false',
      'app_use_device_lock': 'false',
      'app_biometric_enabled': 'false',
      'app_lock_timeout_seconds': '300',
      'notif_quiet_start': '00:00',
      'notif_quiet_end': '07:00',
      'notif_quiet_enabled': 'false',
      'digest_mode': 'standard',
      'coalescing_window_minutes': '15',
      'max_non_essential_per_hour': '3',
      'snooze_minutes': '10',
      'snooze_max_defer_count': '3',
      'auto_backup_enabled': 'false',
      'backup_frequency_days': '7',
      'crash_reports_enabled': 'true',
      'cycle_biometric_enabled': 'false',
    };

    for (final entry in initialDefaults.entries) {
      final existing = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      if (existing.isEmpty) {
        await put(entry.key, entry.value);
      }
    }

    // ۲. تفکیک رمز بخش چرخه از قفل برنامه
    final appPin = await SecureKeyStore.getKey('app_lock_password');
    final cyclePin = await SecureKeyStore.getKey('cycle_lock_password');
    if ((cyclePin == null || cyclePin.isEmpty) && appPin != null && appPin.isNotEmpty) {
      await SecureKeyStore.setKey('cycle_lock_password', appPin);
    }

    // ۳. پاک‌سازی کلیدهای مرده
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['module_konkur_enabled']);
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_model_name']);

    // ۴. حذف امن جدول worship_seasons در صورت وجود
    await db.execute('DROP TABLE IF EXISTS worship_seasons;');
  }

  @override
  Future<void> down(Database db) async {
    // این مایگریشن غیرقابل بازگشت است — down اجرا نمی‌شود
  }
}
