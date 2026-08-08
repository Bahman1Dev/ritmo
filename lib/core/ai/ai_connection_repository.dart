import 'package:ritmo/core/ai/ai_connection_models.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:sqflite/sqflite.dart';

class AiConnectionRepository {
  AiConnectionRepository._();
  static final AiConnectionRepository instance = AiConnectionRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<AiConnectionConfig> load({AiSlot slot = AiSlot.assistant}) async {
    final db = await _db;
    final rows = await db.query('app_settings');
    final settingsMap = <String, String>{
      for (final r in rows) (r['key'] as String): (r['value'] as String? ?? '')
    };

    final isFeatures = slot == AiSlot.features;
    final baseUrlKey = isFeatures ? 'ai_features_base_url' : 'ai_base_url';
    final apiKeyKey = isFeatures ? 'ai_features_api_key' : 'ai_api_key';
    final modelKey = isFeatures ? 'ai_features_model' : 'ai_model';

    // 1. Read API key from SecureKeyStore, fallback to app_settings with auto-migration
    var apiKey = await SecureKeyStore.getKey(apiKeyKey);
    if (apiKey == null || apiKey.isEmpty) {
      final legacyVal = settingsMap[apiKeyKey];
      if (legacyVal != null && legacyVal.isNotEmpty) {
        await SecureKeyStore.setKey(apiKeyKey, legacyVal);
        await db.delete('app_settings', where: 'key = ?', whereArgs: [apiKeyKey]);
        apiKey = legacyVal;
      } else {
        apiKey = '';
      }
    }

    var backupApiKey = await SecureKeyStore.getKey('ai_api_key_2');
    if (backupApiKey == null || backupApiKey.isEmpty) {
      final legacyVal = settingsMap['ai_api_key_2'];
      if (legacyVal != null && legacyVal.isNotEmpty) {
        await SecureKeyStore.setKey('ai_api_key_2', legacyVal);
        await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_api_key_2']);
        backupApiKey = legacyVal;
      } else {
        backupApiKey = '';
      }
    }

    final modeStr = settingsMap['ai_mode'] ?? 'ritmo_server';
    final mode = modeStr == 'personal_key' ? AiMode.personalKey : AiMode.ritmoServer;

    final presetId = settingsMap['ai_provider_preset'] ?? 'zhipu';
    final baseUrl = settingsMap[baseUrlKey] ?? '';
    final model = settingsMap[modelKey] ?? '';
    final timeoutMs = int.tryParse(settingsMap['ai_timeout'] ?? '') ?? 60000;
    final backupBaseUrl = settingsMap['ai_base_url_2'] ?? '';
    final cloudflareAccountId = settingsMap['ai_cloudflare_account_id'] ?? '';
    final separateFeaturesConfig = (settingsMap['ai_separate_features_config'] ?? 'false') == 'true';

    final lastTestAt = int.tryParse(settingsMap['ai_last_test_at'] ?? '');
    final lastTestOkStr = settingsMap['ai_last_test_ok'];
    final lastTestOk = lastTestOkStr == null ? null : (lastTestOkStr == 'true');
    final lastTestLatencyMs = int.tryParse(settingsMap['ai_last_test_latency_ms'] ?? '');
    final lastErrorCode = settingsMap['ai_last_error_code'];

    return AiConnectionConfig(
      slot: slot,
      mode: mode,
      providerPresetId: presetId,
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      timeoutMs: timeoutMs,
      backupBaseUrl: backupBaseUrl,
      backupApiKey: backupApiKey,
      cloudflareAccountId: cloudflareAccountId,
      separateFeaturesConfig: separateFeaturesConfig,
      lastTestAt: lastTestAt,
      lastTestOk: lastTestOk,
      lastTestLatencyMs: lastTestLatencyMs,
      lastErrorCode: lastErrorCode,
    );
  }

  Future<void> save(AiConnectionConfig config) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> putSetting(String key, String value) => db.insert(
          'app_settings',
          {'key': key, 'value': value, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    final isFeatures = config.slot == AiSlot.features;
    final baseUrlKey = isFeatures ? 'ai_features_base_url' : 'ai_base_url';
    final apiKeyKey = isFeatures ? 'ai_features_api_key' : 'ai_api_key';
    final modelKey = isFeatures ? 'ai_features_model' : 'ai_model';

    // Write keys ONLY to SecureKeyStore
    if (config.apiKey.isNotEmpty) {
      await SecureKeyStore.setKey(apiKeyKey, config.apiKey);
    } else {
      await SecureKeyStore.deleteKey(apiKeyKey);
    }
    // Delete any legacy key in app_settings
    await db.delete('app_settings', where: 'key = ?', whereArgs: [apiKeyKey]);

    if (config.backupApiKey.isNotEmpty) {
      await SecureKeyStore.setKey('ai_api_key_2', config.backupApiKey);
    } else {
      await SecureKeyStore.deleteKey('ai_api_key_2');
    }
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_api_key_2']);

    // Write non-sensitive settings to app_settings
    await putSetting('ai_mode', config.mode == AiMode.personalKey ? 'personal_key' : 'ritmo_server');
    await putSetting('ai_provider_preset', config.providerPresetId);
    await putSetting(baseUrlKey, config.baseUrl);
    await putSetting(modelKey, config.model);
    await putSetting('ai_timeout', config.timeoutMs.toString());
    await putSetting('ai_base_url_2', config.backupBaseUrl);
    await putSetting('ai_cloudflare_account_id', config.cloudflareAccountId);
    await putSetting('ai_separate_features_config', config.separateFeaturesConfig.toString());
  }

  Future<void> deleteKey(AiSlot slot) async {
    final db = await _db;
    final isFeatures = slot == AiSlot.features;
    final apiKeyKey = isFeatures ? 'ai_features_api_key' : 'ai_api_key';
    await SecureKeyStore.deleteKey(apiKeyKey);
    await db.delete('app_settings', where: 'key = ?', whereArgs: [apiKeyKey]);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {'key': 'ai_last_test_ok', 'value': '', 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AiMode> loadMode() async {
    final db = await _db;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: ['ai_mode'], limit: 1);
    if (rows.isNotEmpty && rows.first['value'] == 'personal_key') {
      return AiMode.personalKey;
    }
    return AiMode.ritmoServer;
  }

  Future<void> saveMode(AiMode mode) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {
        'key': 'ai_mode',
        'value': mode == AiMode.personalKey ? 'personal_key' : 'ritmo_server',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> recordTest(AiTestResult result) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> putSetting(String key, String value) => db.insert(
          'app_settings',
          {'key': key, 'value': value, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    await putSetting('ai_last_test_at', now.toString());
    await putSetting('ai_last_test_ok', result.ok.toString());
    await putSetting('ai_last_test_latency_ms', result.latencyMs.toString());
    await putSetting('ai_last_error_code', result.statusCode?.toString() ?? '');
  }

  Future<AiTestResult?> lastTest() async {
    final db = await _db;
    final rows = await db.query('app_settings');
    final map = {
      for (final r in rows) (r['key'] as String): (r['value'] as String? ?? '')
    };

    final atStr = map['ai_last_test_at'];
    if (atStr == null || atStr.isEmpty) return null;

    final ok = map['ai_last_test_ok'] == 'true';
    final latency = int.tryParse(map['ai_last_test_latency_ms'] ?? '') ?? 0;
    final status = int.tryParse(map['ai_last_error_code'] ?? '');

    return AiTestResult(
      ok: ok,
      latencyMs: latency,
      resolvedModel: '',
      messageFa: ok ? 'اتصال برقرار است' : 'مشکل در اتصال',
      statusCode: status,
    );
  }

  /// فقط برای نمایش. هرگز کلید برنمی‌گرداند.
  Future<List<AiChainEntry>> describeChain({AiSlot slot = AiSlot.assistant}) async {
    final config = await load(slot: slot);
    final chain = <AiChainEntry>[];

    String extractHost(String url) {
      try {
        final uri = Uri.tryParse(url);
        return uri?.host ?? url;
      } catch (_) {
        return url;
      }
    }

    if (config.baseUrl.isNotEmpty) {
      chain.add(AiChainEntry(
        labelFa: 'کلید اصلی',
        host: extractHost(config.baseUrl),
        model: config.model.isNotEmpty ? config.model : 'پیش‌فرض',
      ));
    }

    if (config.backupBaseUrl.isNotEmpty) {
      chain.add(AiChainEntry(
        labelFa: 'کلید پشتیبان',
        host: extractHost(config.backupBaseUrl),
        model: config.model.isNotEmpty ? config.model : 'پشتیبان',
      ));
    }

    if (config.separateFeaturesConfig) {
      final featuresConfig = await load(slot: AiSlot.features);
      if (featuresConfig.baseUrl.isNotEmpty) {
        chain.add(AiChainEntry(
          labelFa: 'تحلیل‌ها',
          host: extractHost(featuresConfig.baseUrl),
          model: featuresConfig.model.isNotEmpty ? featuresConfig.model : 'تحلیل',
        ));
      }
    }

    return chain;
  }
}
