import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ritmo/core/database/database_helper.dart';

/// SecureKeyStore uses Keystore/Keychain via FlutterSecureStorage for sensitive API keys,
/// automatically migrating legacy keys out of plaintext SQLite app_settings.
class SecureKeyStore {
  SecureKeyStore._();
  static const _storage = FlutterSecureStorage();

  static Future<String?> getKey(String keyName) async {
    try {
      final value = await _storage.read(key: keyName);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (e) {
      debugPrint('[SecureKeyStore] SecureStorage read error for $keyName: $e');
    }

    // Fallback & Auto-Migration from legacy SQLite app_settings
    try {
      final db = await DatabaseHelper.instance.database;
      final rows =
          await db.query('app_settings', where: 'key = ?', whereArgs: [keyName]);
      if (rows.isNotEmpty) {
        final legacyVal = rows.first['value'] as String?;
        if (legacyVal != null && legacyVal.isNotEmpty) {
          await setKey(keyName, legacyVal);
          await db.delete('app_settings',
              where: 'key = ?', whereArgs: [keyName]);
          return legacyVal;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<void> setKey(String keyName, String value) async {
    try {
      await _storage.write(key: keyName, value: value);
      // Remove any legacy plaintext entry in SQLite
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('app_settings',
            where: 'key = ?', whereArgs: [keyName]);
      } catch (_) {}
    } catch (e) {
      debugPrint('[SecureKeyStore] SecureStorage write error for $keyName: $e');
    }
  }

  static Future<void> deleteKey(String keyName) async {
    try {
      await _storage.delete(key: keyName);
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('app_settings',
            where: 'key = ?', whereArgs: [keyName]);
      } catch (_) {}
    } catch (e) {
      debugPrint('[SecureKeyStore] SecureStorage delete error for $keyName: $e');
    }
  }
}
