import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class AiTables {
  static Future<void> create(Database db) async {
    await ensureSchema(db);
  }

  /// Self-healing schema check and initialization for `ai_memory`.
  /// Ensures all required columns and indexes exist regardless of database version
  /// or previous migration history.
  static Future<void> ensureSchema(Database db) async {
    try {
      // 1. Create table with full schema if it does not exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_memory (
          id TEXT PRIMARY KEY,
          content TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'preference',
          domain TEXT NOT NULL DEFAULT 'core',
          source TEXT NOT NULL DEFAULT 'implicit',
          importance INTEGER NOT NULL DEFAULT 5,
          pinned INTEGER NOT NULL DEFAULT 0,
          sensitive INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          sessionId TEXT,
          createdAt INTEGER NOT NULL DEFAULT 0,
          updatedAt INTEGER NOT NULL DEFAULT 0,
          lastAccessedAt INTEGER NOT NULL DEFAULT 0,
          accessCount INTEGER NOT NULL DEFAULT 0,
          expiresAt INTEGER,
          category TEXT DEFAULT 'general',
          created_at INTEGER,
          updated_at INTEGER
        );
      ''');

      // 2. Fetch existing table columns to perform self-healing column additions
      final pragmaRows = await db.rawQuery("PRAGMA table_info('ai_memory');");
      final rawColumnNames = pragmaRows.map((r) => r['name'] as String).toSet();
      final lowerColumnNames = rawColumnNames.map((n) => n.toLowerCase()).toSet();

      final requiredAdditions = <String, String>{
        'type': "TEXT NOT NULL DEFAULT 'preference'",
        'domain': "TEXT NOT NULL DEFAULT 'core'",
        'source': "TEXT NOT NULL DEFAULT 'implicit'",
        'importance': "INTEGER NOT NULL DEFAULT 5",
        'pinned': "INTEGER NOT NULL DEFAULT 0",
        'sensitive': "INTEGER NOT NULL DEFAULT 0",
        'status': "TEXT NOT NULL DEFAULT 'active'",
        'sessionId': "TEXT",
        'createdAt': "INTEGER NOT NULL DEFAULT 0",
        'updatedAt': "INTEGER NOT NULL DEFAULT 0",
        'lastAccessedAt': "INTEGER NOT NULL DEFAULT 0",
        'accessCount': "INTEGER NOT NULL DEFAULT 0",
        'expiresAt': "INTEGER",
        'category': "TEXT DEFAULT 'general'",
        'created_at': "INTEGER",
        'updated_at': "INTEGER",
      };

      for (final entry in requiredAdditions.entries) {
        final colName = entry.key;
        final colDef = entry.value;
        if (!rawColumnNames.contains(colName) && !lowerColumnNames.contains(colName.toLowerCase())) {
          try {
            await db.execute('ALTER TABLE ai_memory ADD COLUMN $colName $colDef;');
          } catch (e) {
            debugPrint('[AI_TABLES] Note adding column $colName: $e');
          }
        }
      }

      // 3. Drop legacy index if pointing to old created_at column and recreate on createdAt
      try {
        await db.execute('DROP INDEX IF EXISTS idx_ai_memory_created;');
      } catch (_) {}

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ai_memory_created '
        'ON ai_memory(createdAt DESC);',
      );
    } catch (e, st) {
      debugPrint('[AI_TABLES] Error in ensureSchema for ai_memory: $e\n$st');
    }
  }
}
