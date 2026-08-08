import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV77AiConnection extends Migration {
  @override
  int get version => 77;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> put(String key, String value) => db.insert(
          'app_settings',
          {'key': key, 'value': value, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    // ۱. نگاشت یک‌بارهٔ مدل‌های منسوخ (منتقل‌شده از _loadConfig)
    await db.rawUpdate(
      "UPDATE app_settings SET value = 'glm-5.2', updatedAt = ? "
      "WHERE key IN ('ai_model','ai_features_model') AND value = 'glm-4.7-flash'",
      [now],
    );
    await db.rawUpdate(
      "UPDATE app_settings SET value = '@cf/zai-org/glm-4.7-flash', updatedAt = ? "
      "WHERE key IN ('ai_model','ai_features_model') AND value = '@cf/zai-org/glm-5.2'",
      [now],
    );

    // ۲. تایم‌اوت پیش‌فرض عاقلانه
    final t = await db.query('app_settings', where: 'key = ?', whereArgs: ['ai_timeout']);
    if (t.isEmpty) await put('ai_timeout', '60000');

    // ۳. حالت اتصال: کاربر فعلی که کلید دارد نباید رفتارش عوض شود
    final existing = await db.query(
      'app_settings',
      where: "key IN ('ai_api_key','ai_features_api_key','ai_base_url') AND value != ''",
    );
    final legacyKey = await SecureKeyStore.getKey('ai_api_key');
    final hasAnything = existing.isNotEmpty || (legacyKey != null && legacyKey.isNotEmpty);
    await put('ai_mode', hasAnything ? 'personal_key' : 'ritmo_server');

    // ۴. حدس پیش‌تنظیم از روی آدرس فعلی
    final urlRow = await db.query('app_settings', where: 'key = ?', whereArgs: ['ai_base_url']);
    final url = urlRow.isNotEmpty ? (urlRow.first['value'] as String? ?? '') : '';
    final preset = url.contains('bigmodel.cn')
        ? 'zhipu'
        : url.contains('openrouter.ai')
            ? 'openrouter'
            : url.contains('cloudflare.com')
                ? 'cloudflare'
                : url.contains('groq.com')
                    ? 'groq'
                    : 'custom';
    await put('ai_provider_preset', preset);
  }

  @override
  Future<void> down(Database db) async {}
}
