import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';

/// Local automatic backup service with user password AES encryption support.
class LocalBackupService {
  LocalBackupService._();
  static final LocalBackupService instance = LocalBackupService._();

  static const String _backupDirName = 'ritmo_backups';

  /// Performs automatic weekly local backup keeping maximum 3 rotating copies.
  Future<void> performAutoBackup(String dbPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${docDir.path}/$_backupDirName');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetFile = File('${backupDir.path}/backup_$timestamp.db');

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(targetFile.path);
      }

      // Rotate: keep only 3 newest backups
      final files = backupDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      if (files.length > 3) {
        for (int i = 3; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (_) {}
  }

  /// Encrypts database bytes with user-provided password.
  List<int> encryptBackup(List<int> rawBytes, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);

    // Header: "RITMO_ENC" + IV bytes + encrypted payload
    final header = utf8.encode('RITMO_ENC');
    return [...header, ...iv.bytes, ...encrypted.bytes];
  }

  /// Decrypts encrypted backup bytes using user-provided password.
  List<int> decryptBackup(List<int> encryptedBytes, String password) {
    final headerStr = utf8.decode(encryptedBytes.sublist(0, 9));
    if (headerStr != 'RITMO_ENC') {
      throw FormatException('Invalid encrypted backup header.');
    }

    final ivBytes = Uint8List.fromList(encryptedBytes.sublist(9, 25));
    final payloadBytes = Uint8List.fromList(encryptedBytes.sublist(25));

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(ivBytes);

    final encrypter = enc.Encrypter(enc.AES(key));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(payloadBytes), iv: iv);
    return decrypted;
  }
}
