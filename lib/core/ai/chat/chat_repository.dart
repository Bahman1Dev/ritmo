import 'dart:math';

import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for storing and retrieving AI chat sessions and messages.
class ChatRepository {
  ChatRepository._();

  /// Singleton instance of [ChatRepository].
  static final ChatRepository instance = ChatRepository._();

  bool _migrated = false;

  Future<Database> _getDb() async {
    final db = await DatabaseHelper.instance.database;
    if (!_migrated) {
      try {
        await db.execute(
          "ALTER TABLE chat_sessions ADD COLUMN chat_type TEXT DEFAULT 'assistant';",
        );
      } catch (_) {}
      _migrated = true;
    }
    return db;
  }

  /// Creates a new [ChatSession] with an optional [chatType].
  Future<ChatSession> createSession({String chatType = 'assistant'}) async {
    final db = await _getDb();
    final now = DateTime.now();
    final id = 'sess_${now.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

    final session = ChatSession(
      id: id,
      createdAt: now,
      lastMessageAt: now,
      chatType: chatType,
    );

    await db.insert('chat_sessions', {
      'id': session.id,
      'title': '',
      'created_at': session.createdAt.millisecondsSinceEpoch,
      'last_message_at': session.lastMessageAt.millisecondsSinceEpoch,
      'summary': null,
      'message_count': 0,
      'chat_type': chatType,
    });

    return session;
  }

  /// Lists chat sessions matching [chatType], ordered by most recent.
  Future<List<ChatSession>> listSessions({
    String chatType = 'assistant',
    int limit = 50,
  }) async {
    final db = await _getDb();
    final maps = await db.query(
      'chat_sessions',
      where: 'chat_type = ?',
      whereArgs: [chatType],
      orderBy: 'last_message_at DESC',
      limit: limit,
    );
    return maps.map(ChatSession.fromMap).toList();
  }

  /// Fetches a [ChatSession] by its [id].
  Future<ChatSession?> getSession(String id) async {
    final db = await _getDb();
    final maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChatSession.fromMap(maps.first);
  }

  /// Updates the summary text of a chat session.
  Future<void> updateSessionSummary(String id, String summary) async {
    final db = await _getDb();
    await db.update(
      'chat_sessions',
      {'summary': summary},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a chat session and all associated messages.
  Future<void> deleteSession(String id) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await txn.delete(
        'chat_messages',
        where: 'session_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'chat_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Persists a new [ChatMessage] and updates the parent session metadata.
  Future<void> addMessage(ChatMessage m) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await txn.insert('chat_messages', m.toMap());
      await txn.rawUpdate(
        'UPDATE chat_sessions SET message_count = message_count + 1, '
        'last_message_at = ? WHERE id = ?',
        [m.timestamp.millisecondsSinceEpoch, m.sessionId],
      );
    });
  }

  /// Retrieves all messages in a session ordered by timestamp.
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await _getDb();
    final maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return maps.map(ChatMessage.fromMap).toList();
  }

  /// Updates an existing message content or actions.
  Future<void> updateMessage(ChatMessage m) async {
    final db = await _getDb();
    await db.update(
      'chat_messages',
      {
        'content': m.content,
        'actions': m.toMap()['actions'],
      },
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  /// Fetches recent turns (up to [limit]) for prompt context building.
  Future<List<ChatMessage>> getRecentTurns(
    String sessionId, {
    int limit = 10,
  }) async {
    final db = await _getDb();
    final maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    final list = maps.map(ChatMessage.fromMap).toList();
    return list.reversed.toList();
  }

  /// Updates the `last_message_at` timestamp of a session.
  Future<void> touchSession(String id, DateTime at) async {
    final db = await _getDb();
    await db.update(
      'chat_sessions',
      {'last_message_at': at.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a specific message by its [id].
  Future<void> deleteMessage(String id) async {
    final db = await _getDb();
    await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
