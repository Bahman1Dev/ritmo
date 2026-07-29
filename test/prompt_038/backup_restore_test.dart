import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/local_backup_service.dart';

void main() {
  group('LocalBackupService Encryption & Restore Tests', () {
    test('encrypts and decrypts payload correctly with user password', () {
      final sampleData = utf8.encode('Ritmo SQLite Database Backup Payload Content 2026');
      final password = 'UserSecurePassword123!';

      final encrypted = LocalBackupService.instance.encryptBackup(sampleData, password);
      expect(encrypted.length, greaterThan(sampleData.length));

      final decrypted = LocalBackupService.instance.decryptBackup(encrypted, password);
      expect(utf8.decode(decrypted), equals('Ritmo SQLite Database Backup Payload Content 2026'));
    });

    test('throws error on wrong password decryption attempt', () {
      final sampleData = utf8.encode('Ritmo Payload');
      final password = 'UserPassword1';

      final encrypted = LocalBackupService.instance.encryptBackup(sampleData, password);

      expect(
        () => LocalBackupService.instance.decryptBackup(encrypted, 'WrongPassword'),
        throwsA(anything),
      );
    });
  });
}
