import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:sqflite/sqflite.dart';

/// Safely handles database files, header validation, and emergency recovery without losing user data.
class LegacyDatabaseRecovery {
  /// Validates whether a file is a valid, non-corrupt SQLite database with a proper 16-byte header.
  static Future<bool> isValidSqliteHeader(File file) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 100) return false; // Minimum SQLite file size header is 100 bytes

    try {
      final raf = await file.open(mode: FileMode.read);
      final headerBytes = await raf.read(16);
      await raf.close();
      if (headerBytes.length < 16) return false;
      final headerStr = String.fromCharCodes(headerBytes);
      return headerStr == 'SQLite format 3\0';
    } catch (_) {
      return false;
    }
  }

  /// Ensures safe database file transition and quarantines corrupted/0-byte files.
  static Future<String> getSafeDatabasePath() async {
    final dbPath = await getDatabasesPath();
    final legacyPath = join(dbPath, 'ritmo_secure.db');
    final targetPath = join(dbPath, 'ritmo.db');

    final legacyFile = File(legacyPath);
    final targetFile = File(targetPath);

    // 1. If target file exists but is corrupted or 0-bytes, quarantine it
    if (await targetFile.exists() && !(await isValidSqliteHeader(targetFile))) {
      await _quarantineCorruptFile(targetFile, 'target_invalid_header');
    }

    // 2. If legacy file exists and target file does not exist (or was quarantined)
    if (await legacyFile.exists() && !(await targetFile.exists())) {
      if (await isValidSqliteHeader(legacyFile)) {
        try {
          await legacyFile.rename(targetPath);
          RitmoLog.info('LegacyDatabaseRecovery', 'Successfully renamed valid legacy ritmo_secure.db to ritmo.db');
        } catch (e, st) {
          RitmoLog.error('LegacyDatabaseRecovery', 'Failed to rename legacy database, copying instead', e, st);
          try {
            await legacyFile.copy(targetPath);
          } catch (copyErr, copySt) {
            RitmoLog.error('LegacyDatabaseRecovery', 'Failed to copy legacy database', copyErr, copySt);
          }
        }
      } else {
        await _quarantineCorruptFile(legacyFile, 'legacy_invalid_header');
      }
    }

    return targetFile.path;
  }

  /// Quarantines a corrupted database file to app documents directory to protect user data while allowing a fresh boot.
  static Future<void> _quarantineCorruptFile(File file, String reason) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final corruptPath = join(docsDir.path, 'ritmo_corrupt_${reason}_$timestamp.db');
      await file.rename(corruptPath);
      RitmoLog.warning('LegacyDatabaseRecovery', 'Quarantined corrupt database file ($reason) to: $corruptPath');
    } catch (e, st) {
      RitmoLog.error('LegacyDatabaseRecovery', 'Failed to quarantine corrupt database file', e, st);
      try {
        if (await file.exists() && await file.length() == 0) {
          await file.delete(); // Delete empty 0-byte file if rename failed
        }
      } catch (_) {}
    }
  }

  /// Creates a raw backup copy of the database before any dangerous operation.
  static Future<String?> createEmergencyBackup(String dbPath) async {
    try {
      final file = File(dbPath);
      if (!await file.exists() || !(await isValidSqliteHeader(file))) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(docsDir.path, 'ritmo_recovery_$timestamp.db');
      
      await file.copy(backupPath);
      RitmoLog.info('LegacyDatabaseRecovery', 'Emergency database backup created at: $backupPath');
      return backupPath;
    } catch (e, st) {
      RitmoLog.error('LegacyDatabaseRecovery', 'Failed to create emergency backup', e, st);
      return null;
    }
  }
}
