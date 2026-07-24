import 'package:sqflite/sqflite.dart';

class AiTables {
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_memory (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_memory_created '
      'ON ai_memory(created_at DESC);',
    );
  }
}
