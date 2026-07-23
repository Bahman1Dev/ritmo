import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupPasscodeManager {
  static const _storage = FlutterSecureStorage();
  static const _key = 'backup_passcode_v1';
  static const _hintKey = 'backup_passcode_hint_v1';

  Future<void> setPasscode(String passcode, {String? hint}) async {
    await _storage.write(key: _key, value: passcode);
    final prefs = await SharedPreferences.getInstance();
    if (hint != null && hint.isNotEmpty) {
      await prefs.setString(_hintKey, hint);
    } else {
      await prefs.remove(_hintKey);
    }
  }

  Future<String?> getPasscode() async {
    return _storage.read(key: _key);
  }

  Future<String?> getHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hintKey);
  }

  Future<bool> hasPasscode() async {
    final code = await getPasscode();
    return code != null && code.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hintKey);
  }
}
