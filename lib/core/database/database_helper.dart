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

  @visibleForTesting
  static set databaseInstance(Database? db) => _database = db;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ritmo_secure.db');
    await _ensurePerformanceIndexes(_database!);
    await _ensureChatTables(_database!);
    await _ensureReminderColumns(_database!);
    await _ensureRpeColumn(_database!);
    await SeedService.seedSupplementarySports(_database!);
    await _ensureAiMemoryTable(_database!);
    await _ensureDayPlanCommitsTable(_database!);
    await _ensureDayPlanTemplatesTable(_database!);
    return _database!;
  }

  Future<void> _ensureAiMemoryTable(Database db) async {
    try {
      // Drop legacy test table
      await db.execute('DROP TABLE IF EXISTS ss_ai_memory;');
      
      // Create new cognitive memory table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_memory (
          id TEXT PRIMARY KEY,
          content TEXT NOT NULL,
          type TEXT NOT NULL,
          domain TEXT NOT NULL DEFAULT 'core',
          source TEXT NOT NULL,
          importance INTEGER NOT NULL,
          pinned INTEGER NOT NULL DEFAULT 0,
          sensitive INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          sessionId TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          lastAccessedAt INTEGER NOT NULL,
          accessCount INTEGER NOT NULL DEFAULT 0,
          expiresAt INTEGER
        );
      ''');
    } catch (e) {
      debugPrint('[DATABASE] Error ensuring ai_memory table: $e');
    }
  }

  Future<void> _ensureDayPlanCommitsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS day_plan_commits (
          id TEXT PRIMARY KEY,
          commitDate TEXT NOT NULL,
          createdItemIds TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          groupId TEXT
        );
      ''');
      try {
        await db.execute('ALTER TABLE day_plan_commits ADD COLUMN groupId TEXT;');
      } catch (_) {}
    } catch (e) {
      debugPrint('[DATABASE] Error ensuring day_plan_commits table: $e');
    }
  }

  Future<void> _ensureDayPlanTemplatesTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS day_plan_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT,
          itemsJson TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          lastUsedAt INTEGER NOT NULL,
          useCount INTEGER NOT NULL DEFAULT 0
        );
      ''');
    } catch (e) {
      debugPrint('[DATABASE] Error ensuring day_plan_templates table: $e');
    }
  }

  Future<void> _ensureReminderColumns(Database db) async {
    try {
      await db.execute('ALTER TABLE routines ADD COLUMN reminderOffsetMinutes INTEGER DEFAULT 0;');
    } catch (_) {
      // Column already exists
    }
  }

  Future<void> _ensureRpeColumn(Database db) async {
    try {
      await db.execute('ALTER TABLE workout_set_logs ADD COLUMN rpe INTEGER DEFAULT 0;');
    } catch (_) {
      // Column already exists
    }
  }

  Future<void> _ensureChatTables(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS assistant_chats;');
      await db.execute('DROP TABLE IF EXISTS assistant_threads;');
      await db.execute("DELETE FROM app_settings WHERE key='assistant_memory_summary';");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_sessions (
          id TEXT PRIMARY KEY,
          created_at INTEGER NOT NULL,
          last_message_at INTEGER NOT NULL,
          summary TEXT,
          message_count INTEGER NOT NULL DEFAULT 0,
          chat_type TEXT DEFAULT 'assistant'
        );
      ''');
      try {
        await db.execute("ALTER TABLE chat_sessions ADD COLUMN chat_type TEXT DEFAULT 'assistant';");
      } catch (_) {}
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_sessions_last '
        'ON chat_sessions(last_message_at DESC);',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          tokens_used INTEGER,
          actions TEXT,
          FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_session_time '
        'ON chat_messages(session_id, timestamp);',
      );
    } catch (e) {
      debugPrint('[CHAT] Chat tables bootstrap error (non-fatal): $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 41,
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
        version: 42,
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

  Future<void> _ensurePerformanceIndexes(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_perf_completions_routine_date '
        'ON routine_completions(routineId, completionDate);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_perf_occurrences_routine_date '
        'ON routine_occurrences(routine_id, date);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_perf_occurrences_date_status '
        'ON routine_occurrences(date, status);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_perf_wp_type_active '
        'ON worship_practices(practiceType, isActive);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_perf_reminders_routine_state '
        'ON pending_reminders(routineId, state);',
      );
      debugPrint('[PERF] Performance indexes bootstrap complete.');
    } catch (e) {
      debugPrint('[PERF] Index bootstrap error (non-fatal): $e');
    }
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