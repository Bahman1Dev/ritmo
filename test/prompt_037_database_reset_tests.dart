import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/backup_service.dart';

void main() {
  group('Prompt 037 - Database Reset & Backup Version Tests', () {
    test('BackupService.restoreBackup rejects future backup versions (> 2)', () async {
      final futureBackupMap = {
        'version': 99,
        'salt': 'c2FsdHNhbHRzYWx0c2FsdA==',
        'iv': 'aXZpdml2aXZpdml2',
        'ciphertext': 'ZHVtbXljaXBoZXJ0ZXh0',
      };
      final futureJson = json.encode(futureBackupMap);

      expect(
        () async => await BackupService.restoreBackup(futureJson, 'passcode123'),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('نسخه فایل پشتیبان جدیدتر از این نسخه اپلیکیشن است')),
        ),
      );
    });

    test('BackupService.restoreBackup rejects malformed JSON without salt/iv', () async {
      final invalidJson = json.encode({'version': 1});

      expect(
        () async => await BackupService.restoreBackup(invalidJson, 'passcode123'),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('فرمت فایل پشتیبان معتبر نیست')),
        ),
      );
    });
  });
}
