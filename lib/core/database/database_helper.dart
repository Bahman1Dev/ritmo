import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:ritmo/core/database/migration/migration_runner.dart';
import 'package:ritmo/core/database/schema/schema_manager.dart';
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {

  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _dbVersion = 46;

  @visibleForTesting
  static set databaseInstance(Database? db) => _database = db;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ritmo_secure.db');
    await SeedService.seedSupplementarySports(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _createDB,
          onUpgrade: onUpgrade,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      const storage = FlutterSecureStorage();
      final oldKeyExists = await storage.containsKey(key: 'db_encryption_key');
      if (oldKeyExists) {
        try {
          await storage.delete(key: 'db_encryption_key');
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            debugPrint('[DATABASE] Deleted legacy encrypted database at: $path');
          }
        } catch (e) {
          debugPrint('[DATABASE] Error deleting legacy encrypted database: $e');
        }
      }

      return openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDB,
        onConfigure: _onConfigure,
        onUpgrade: onUpgrade,
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await SchemaManager.createAll(db);
    await SeedService.seedAll(db);
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    await MigrationRunner.run(db, oldVersion, newVersion);
  }

  Future<void> _onConfigure(Database db) async {
    await db.rawQuery('PRAGMA journal_mode=WAL;');
    await db.rawQuery('PRAGMA synchronous=NORMAL;');
  }

  Future<void> logNotificationEvent({
    required String? routineId,
    required String actionTaken,
    required String notificationType,
    DatabaseExecutor? executor,
  }) async {
    final exec = executor ?? await database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await exec.insert('notification_history', {
      'id': 'notif_${nowMs}_${routineId ?? "sys"}',
      'routineId': routineId,
      'notificationType': notificationType,
      'sentAt': nowMs,
      'actionTaken': actionTaken,
    });
  }

  Future<void> addFastingDebtIfNeeded(DatabaseExecutor db, String dateStr) async {
    final consentQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['cycle_consent_worship'],
    );
    if (consentQuery.isEmpty || consentQuery.first['value'].toString().toLowerCase() != 'true') {
      return;
    }

    final existingDebt = await db.query(
      'fasting_debt',
      where: 'dateIso = ?',
      whereArgs: [dateStr],
    );
    if (existingDebt.isNotEmpty) {
      return;
    }

    final activePeriods = await db.query(
      'cycle_periods',
      where: 'startDate <= ? AND (endDate IS NULL OR endDate >= ?)',
      whereArgs: [dateStr, dateStr],
    );
    if (activePeriods.isEmpty) {
      return;
    }

    final activePeriod = activePeriods.first;
    final startDateStr = activePeriod['startDate']! as String;
    final endDateStr = (activePeriod['endDate'] as String?) ?? dateStr;

    final start = DateTime.parse(startDateStr);
    final end = DateTime.parse(endDateStr);
    final daysOwed = end.difference(start).inDays + 1;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.insert('fasting_debt', {
      'id': 'fast_debt_${startDateStr}_$endDateStr',
      'dateIso': dateStr,
      'daysOwed': daysOwed,
      'isResolved': 0,
      'reason': 'عذر شرعی (دوره ماهانه)',
      'createdAt': nowMs,
      'updatedAt': nowMs,
    });
  }

  Future<bool> isUserMenstruating({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    
    final genderQuery = await exec.query('app_settings', where: 'key = ?', whereArgs: ['user_gender']);
    if (genderQuery.isEmpty || genderQuery.first['value'].toString().toUpperCase() != 'FEMALE') {
      return false;
    }
    
    final cycleEnabledQuery = await exec.query('app_settings', where: 'key = ?', whereArgs: ['module_cycle_enabled']);
    if (cycleEnabledQuery.isEmpty || cycleEnabledQuery.first['value'].toString().toLowerCase() != 'true') {
      return false;
    }
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final activePeriods = await exec.query(
      'cycle_periods',
      where: 'startDate <= ? AND (endDate IS NULL OR endDate >= ?)',
      whereArgs: [todayStr, todayStr],
    );
    
    return activePeriods.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getCycleLogs({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    return exec.query('cycle_logs', orderBy: 'cycleStartDate DESC');
  }

  Future<void> deleteNotificationHistory({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    await exec.delete('notification_history');
  }

  Future<List<Map<String, dynamic>>> getCustomCategories({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    return exec.query('custom_categories', where: 'isArchived = 0', orderBy: 'sortOrder ASC');
  }

  Future<void> insertCustomCategory(Map<String, dynamic> category, {DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    await exec.insert('custom_categories', category, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnlockedMilestones({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    return exec.query('milestones_unlocked');
  }

  Future<void> unlockMilestone(String milestoneId, int unlockedAt, {DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    await exec.insert(
      'milestones_unlocked',
      {
        'id': milestoneId,
        'unlockedAt': unlockedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}