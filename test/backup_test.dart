import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ritmo/core/services/backup_service.dart';

void main() {
  late String mockDbPath;

  setUp(() async {
    final tempDir = Directory.systemTemp.path;
    mockDbPath = p.join(tempDir, 'ritmo_test_db.db');

    // Create a dummy ritmo.db file in temp directory
    final dbFile = File(mockDbPath);
    await dbFile.writeAsString('Ritmo Database Content Test 12345');
  });

  tearDown(() async {
    final dbFile = File(mockDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  });

  group('BackupService Tests', () {
    test('Export and restore correctly with matching passcode', () async {
      const passcode = '1234';

      // 1. Export database
      final backupJson = await BackupService.exportBackup(passcode, customDbPath: mockDbPath);
      expect(backupJson, contains('salt'));
      expect(backupJson, contains('iv'));
      expect(backupJson, contains('ciphertext'));

      // Modify the dummy file to simulate changes or data loss
      final dbFile = File(mockDbPath);
      await dbFile.writeAsString('Corrupted Database');

      // 2. Restore database
      await BackupService.restoreBackup(backupJson, passcode, customDbPath: mockDbPath);

      // 3. Verify content was restored correctly
      final restoredContent = await dbFile.readAsString();
      expect(restoredContent, 'Ritmo Database Content Test 12345');
    });

    test('Restore fails with incorrect passcode', () async {
      const passcode = '1234';
      const incorrectPasscode = '9999';

      final backupJson = await BackupService.exportBackup(passcode, customDbPath: mockDbPath);

      expect(
        () => BackupService.restoreBackup(backupJson, incorrectPasscode, customDbPath: mockDbPath),
        throwsA(isA<Exception>()),
      );
    });
  });
}
