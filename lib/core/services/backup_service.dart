import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:pointycastle/export.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  /// Exports the local database to an encrypted JSON backup string.
  static Future<String> exportBackup(String passcode, {String? customDbPath}) async {
    if (kIsWeb) {
      throw Exception('پشتیبان‌گیری در نسخه وب پشتیبانی نمی‌شود.');
    }
    // 1. Get database path
    final String path;
    if (customDbPath != null) {
      path = customDbPath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'ritmo_secure.db');
    }
    final file = File(path);

    if (!await file.exists()) {
      throw Exception('پایگاه داده یافت نشد.');
    }

    // Read database bytes
    final dbBytes = await file.readAsBytes();

    // 2. Generate cryptographically secure salt & IV
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }

    final ivBytes = Uint8List(12); // GCM standard IV is 12 bytes
    for (var i = 0; i < 12; i++) {
      ivBytes[i] = random.nextInt(256);
    }

    // 3. Derive 32-byte key from passcode using PBKDF2
    final keyBytes = _deriveKey(passcode, saltBytes);

    // 4. Encrypt with AES-GCM
    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(dbBytes, iv: iv);

    // 5. Build export JSON structure
    final backupMap = {
      'version': 2,
      'salt': base64.encode(saltBytes),
      'iv': base64.encode(ivBytes),
      'ciphertext': encrypted.base64,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
    };

    return json.encode(backupMap);
  }

  /// Restores the database from an encrypted JSON backup string.
  static Future<void> restoreBackup(String backupJson, String passcode, {String? customDbPath}) async {
    if (kIsWeb) {
      throw Exception('پشتیبان‌گیری در نسخه وب پشتیبانی نمی‌شود.');
    }
    // 1. Parse JSON structure
    final Map<String, dynamic> backupMap = json.decode(backupJson);
    if (!backupMap.containsKey('salt') || !backupMap.containsKey('iv') || !backupMap.containsKey('ciphertext')) {
      throw Exception('فرمت فایل پشتیبان معتبر نیست.');
    }

    final saltBytes = base64.decode(backupMap['salt'] as String);
    final ivBytes = base64.decode(backupMap['iv'] as String);
    final ciphertextBase64 = backupMap['ciphertext'] as String;

    // 2. Derive key from passcode using PBKDF2
    final keyBytes = _deriveKey(passcode, saltBytes);

    // 3. Decrypt with AES-GCM
    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    Uint8List decryptedBytes;
    try {
      final encrypted = enc.Encrypted.fromBase64(ciphertextBase64);
      decryptedBytes = Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
    } catch (e) {
      throw Exception('رمز عبور نادرست است یا فایل پشتیبان مخدوش شده است.');
    }

    // 4. Close database connection before replacing the file
    // Only close if using the default database path (not custom/mock path)
    if (customDbPath == null) {
      await DatabaseHelper.instance.close();
    }

    // 5. Replace database file
    final String path;
    if (customDbPath != null) {
      path = customDbPath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'ritmo_secure.db');
    }
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(decryptedBytes);

    // Reopen database connection to verify schema/integrity
    if (customDbPath == null) {
      await DatabaseHelper.instance.database;
    }
  }

  /// Helper to derive key using PBKDF2 Key Derivator from PointyCastle.
  static Uint8List _deriveKey(String password, Uint8List salt) {
    final hmac = HMac(SHA256Digest(), 64);
    final derivator = PBKDF2KeyDerivator(hmac);
    final params = Pbkdf2Parameters(salt, 10000, 32); // 10,000 iterations for mobile performance
    derivator.init(params);
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }
}
