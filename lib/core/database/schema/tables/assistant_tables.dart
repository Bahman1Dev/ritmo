import 'package:sqflite/sqflite.dart';

class AssistantTables {
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_message_at INTEGER NOT NULL,
        summary TEXT,
        message_count INTEGER NOT NULL DEFAULT 0,
        chat_type TEXT DEFAULT 'assistant'
      );
    ''');
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
  }
}
