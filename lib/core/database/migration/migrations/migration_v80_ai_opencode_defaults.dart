import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV80AiOpencodeDefaults extends Migration {
  @override
  int get version => 80;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    Future<void> putSetting(String key, String value) async {
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': value,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Set OpenCode default endpoint, provider preset, and model
    await putSetting('ai_mode', 'personal_key');
    await putSetting('ai_provider_preset', 'opencode');
    await putSetting('ai_base_url', 'https://opencode.ai/zen/v1/chat/completions');
    await putSetting('ai_model', 'deepseek-v4-flash-free');
    await putSetting('ai_features_base_url', 'https://opencode.ai/zen/v1/chat/completions');
    await putSetting('ai_features_model', 'deepseek-v4-flash-free');

    // Save default OpenCode API key encrypted in SecureKeyStore
    const apiKey = 'sk-jFjvHozwSit6S3YthLrr9UiFLYMSTBABkXnxACu5pFSiTpHv2YG8gGj4pWNgQKWn';
    await SecureKeyStore.setKey('ai_api_key', apiKey);
    await SecureKeyStore.setKey('ai_features_api_key', apiKey);
  }

  @override
  Future<void> down(Database db) async {}
}
