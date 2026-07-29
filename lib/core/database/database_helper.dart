import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/database/legacy_database_recovery.dart';
import 'package:ritmo/core/database/migration/migration_runner.dart';
import 'package:ritmo/core/database/schema/schema_manager.dart';
import 'package:ritmo/core/database/schema/tables/ai_tables.dart';
import 'package:ritmo/core/database/schema/tables/day_plan_tables.dart';
import 'package:ritmo/core/database/schema/tables/supplementary_sports_tables.dart';
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:ritmo/core/services/end_of_day_sweep.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {

  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _dbVersion = 59;

  @visibleForTesting
  static set databaseInstance(Database? db) => _database = db;

  static Completer<Database>? _dbInitCompleter;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    if (_dbInitCompleter != null) return _dbInitCompleter!.future;

    _dbInitCompleter = Completer<Database>();
    try {
      // NOTE: Database is stored locally in the Android private app sandbox ('ritmo.db' / 'ritmo_secure.db').
      // It is protected by Android OS app sandboxing, biometric app lock, and encrypted manual export backups.
      final db = await _initDB('ritmo.db');
      _database = db;
      _dbInitCompleter!.complete(db);
      return db;
    } catch (e, st) {
      _dbInitCompleter!.completeError(e, st);
      _dbInitCompleter = null;
      rethrow;
    }
  }

  /// Explicitly warms up background database tasks and seed verification.
  static Future<void> warmUp(Database db) async {
    try {
      await SeedService.seedSupplementarySports(db);
      _checkDailySweep(db);
    } catch (e, st) {
      RitmoLog.error('DatabaseHelper', 'Warmup error', e, st);
    }
  }

  static void _checkDailySweep(Database db) {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    db.query('app_settings', where: "key = 'last_worship_sweep_date'").then((rows) {
      final lastDate = rows.isNotEmpty ? rows.first['value'] as String? : null;
      if (lastDate != todayStr) {
        EndOfDaySweep.runSweep(db);
      }
    }).catchError((e, st) {
      RitmoLog.error('DatabaseHelper', 'Daily sweep error', e, st);
    });
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
      final path = await LegacyDatabaseRecovery.getSafeDatabasePath();

      try {
        return await openDatabase(
          path,
          version: _dbVersion,
          onCreate: _createDB,
          onConfigure: _onConfigure,
          onUpgrade: onUpgrade,
        );
      } catch (e, st) {
        RitmoLog.error('DatabaseHelper', 'Database open failed ($e). Quarantining file and creating fresh database', e, st);
        final dbFile = File(path);
        if (await dbFile.exists()) {
          try {
            final docsDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final corruptPath = join(docsDir.path, 'ritmo_corrupt_open_$timestamp.db');
            await dbFile.rename(corruptPath);
          } catch (_) {
            if (await dbFile.length() == 0) {
              await dbFile.delete();
            }
          }
        }
        return await openDatabase(
          path,
          version: _dbVersion,
          onCreate: _createDB,
          onConfigure: _onConfigure,
          onUpgrade: onUpgrade,
        );
      }
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

    final activePeriods = await db.query(
      'cycle_periods',
      where: 'startDate <= ? AND (endDate IS NULL OR endDate >= ?)',
      whereArgs: [dateStr, dateStr],
    );
    if (activePeriods.isEmpty) {
      return;
    }

    final activePeriod = activePeriods.first;
    final periodId = activePeriod['id']?.toString() ?? 'period';
    final startDateStr = activePeriod['startDate']! as String;
    final endDateStr = (activePeriod['endDate'] as String?) ?? dateStr;

    final debtId = 'fast_debt_$periodId';
    final existingDebt = await db.query(
      'fasting_debt',
      where: 'id = ? OR dateIso = ?',
      whereArgs: [debtId, dateStr],
    );
    if (existingDebt.isNotEmpty) {
      return;
    }

    final startKey = DayKey.parse(startDateStr);
    final endKey = DayKey.parse(endDateStr);
    final daysOwed = endKey.differenceInDays(startKey) + 1;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.insert('fasting_debt', {
      'id': debtId,
      'dateIso': dateStr,
      'daysOwed': daysOwed,
      'isResolved': 0,
      'reason': 'عذر شرعی (دوره ماهانه)',
      'createdAt': nowMs,
      'updatedAt': nowMs,
    });
  }

  /// Fetches user gender ('FEMALE' or 'MALE') from app_settings, ss_user_profile, or SharedPreferences.
  Future<String> getUserGender({DatabaseExecutor? executor}) async {
    final exec = executor ?? await database;
    try {
      final genderQuery = await exec.query('app_settings', where: 'key = ?', whereArgs: ['user_gender']);
      if (genderQuery.isNotEmpty && genderQuery.first['value'] != null) {
        final val = genderQuery.first['value'].toString().toUpperCase();
        if (val == 'FEMALE' || val == 'WOMAN' || val == 'ZAN' || val == 'زن') return 'FEMALE';
        if (val == 'MALE' || val == 'MAN' || val == 'MARD' || val == 'مرد') return 'MALE';
      }

      final ssProfileRows = await exec.query('ss_user_profile', limit: 1);
      if (ssProfileRows.isNotEmpty && ssProfileRows.first['gender'] != null) {
        final val = ssProfileRows.first['gender'].toString().toUpperCase();
        if (val == 'FEMALE' || val == 'WOMAN' || val == 'ZAN' || val == 'زن') return 'FEMALE';
        if (val == 'MALE' || val == 'MAN' || val == 'MARD' || val == 'مرد') return 'MALE';
      }

      final prefs = await SharedPreferences.getInstance();
      final spGender = prefs.getString('ss_onboarding_gender') ?? prefs.getString('user_gender');
      if (spGender != null && spGender.isNotEmpty) {
        final val = spGender.toUpperCase();
        if (val == 'FEMALE' || val == 'WOMAN' || val == 'ZAN' || val == 'زن') return 'FEMALE';
        if (val == 'MALE' || val == 'MAN' || val == 'MARD' || val == 'مرد') return 'MALE';
      }
    } catch (e, st) {
      RitmoLog.error('DatabaseHelper', 'Error getting user gender', e, st);
    }
    return 'MALE';
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