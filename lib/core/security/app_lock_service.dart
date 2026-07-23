import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AppLockService {
  AppLockService._privateConstructor();
  static final AppLockService instance = AppLockService._privateConstructor();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<Map<String, String>> _loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final list = await db.query('app_settings');
      return {for (final s in list) s['key']! as String: s['value']! as String};
    } catch (e) {
      debugPrint('Error loading app lock settings from db: $e');
      return {};
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {'key': key, 'value': value, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving app lock setting ($key: $value): $e');
    }
  }

  // --- Getters ---
  Future<bool> isLockEnabled() async {
    final settings = await _loadSettings();
    return settings['app_lock_enabled'] == 'true';
  }

  Future<String?> getLockPassword() async {
    final settings = await _loadSettings();
    return settings['app_lock_password'];
  }

  Future<bool> useDeviceLock() async {
    final settings = await _loadSettings();
    return settings['app_use_device_lock'] == 'true';
  }

  Future<bool> isBiometricEnabled() async {
    final settings = await _loadSettings();
    return settings['app_biometric_enabled'] == 'true';
  }

  Future<int> getLockTimeoutSeconds() async {
    final settings = await _loadSettings();
    return int.tryParse(settings['app_lock_timeout_seconds'] ?? '300') ?? 300;
  }

  // --- Setters ---
  Future<void> setLockEnabled(bool enabled) async {
    await _saveSetting('app_lock_enabled', enabled.toString());
  }

  Future<void> setLockPassword(String? password) async {
    if (password == null) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('app_settings', where: 'key = ?', whereArgs: ['app_lock_password']);
    } else {
      await _saveSetting('app_lock_password', password);
    }
  }

  Future<void> setUseDeviceLock(bool useDeviceLock) async {
    await _saveSetting('app_use_device_lock', useDeviceLock.toString());
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _saveSetting('app_biometric_enabled', enabled.toString());
  }

  // --- Auth Capabilities ---
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking if device is supported: $e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      debugPrint('Error checking canCheckBiometrics: $e');
      return false;
    }
  }

  Future<bool> authenticateWithDevice({
    required String reason,
    required bool biometricOnly,
  }) async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheck) {
        return false;
      }
      
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Error authenticating with device: $e');
      return false;
    }
  }
}
