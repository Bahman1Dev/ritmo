import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/inbox_policy.dart';
import 'package:sqflite/sqflite.dart';

class CentralInboxService {
  static Future<void> push({
    required InboxCategory category,
    required String sourceSystem,
    required String entityId,
    required String eventType,
    required String title,
    String? body,
    int priority = 0,
    String? linkModule,
    String? linkEntityId,
    String? linkAction,
    Map<String, dynamic>? payload,
    String? dateBucket,
    DatabaseExecutor? executor,
  }) async {
    final pr = InboxPriority.values[priority.clamp(0, 2)];
    
    // 1. Guard check
    if (!InboxPolicy.shouldPush(category: category, priority: pr, sourceSystem: sourceSystem)) {
      return;
    }

    // 2. Rate limit check
    if (!await InboxPolicy.withinRateLimit(category)) {
      return;
    }

    // 3. Prepare parameters
    final db = executor ?? await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ttlDays = InboxPolicy.defaultTtlDays(category);
    final expiresAt = now + (ttlDays * 24 * 60 * 60 * 1000);
    final dedupeKey = InboxPolicy.buildDedupeKey(
      sourceSystem: sourceSystem,
      entityId: entityId,
      eventType: eventType,
      dateBucket: dateBucket,
    );
    final id = 'inbox_${category.name.toLowerCase()}_${entityId}_$now';

    // 4. Insert into database
    await db.insert(
      'inbox_items',
      {
        'id': id,
        'category': category.name,
        'sourceSystem': sourceSystem,
        'title': title,
        'body': body,
        'priority': pr.index,
        'linkModule': linkModule,
        'linkEntityId': linkEntityId,
        'linkAction': linkAction,
        'payloadJson': jsonEncode(payload ?? {}),
        'status': InboxStatus.UNREAD.name,
        'createdAt': now,
        'expiresAt': expiresAt,
        'dedupeKey': dedupeKey,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // 5. Notify observers
    RitmoEventBus().fire(RitmoEvent(
      type: 'inbox_updated',
      timestamp: DateTime.now(),
      payload: {},
    ));
  }

  static Future<int> unreadCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM inbox_items WHERE status = 'UNREAD'"
      );
      return res.isNotEmpty ? (res.first['cnt'] as int? ?? 0) : 0;
    } catch (e, st) {
      debugPrint('Error in CentralInboxService.unreadCount: $e\n$st');
      return 0;
    }
  }

  static Future<List<InboxItem>> getItems({
    InboxStatus? statusFilter,
    InboxCategory? categoryFilter,
    int? limit,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      var whereClause = "status != 'EXPIRED'";
      final whereArgs = <dynamic>[];

      if (statusFilter != null) {
        whereClause += ' AND status = ?';
        whereArgs.add(statusFilter.name);
      }
      if (categoryFilter != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(categoryFilter.name);
      }

      final queryLimit = limit != null ? ' LIMIT $limit' : '';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM inbox_items WHERE $whereClause ORDER BY priority DESC, createdAt DESC$queryLimit',
        whereArgs,
      );

      return maps.map(InboxItem.fromMap).toList();
    } catch (e, st) {
      debugPrint('Error in CentralInboxService.getItems: $e\n$st');
      return [];
    }
  }

  static Future<void> markRead(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.READ.name,
          'readAt': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> markActioned(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.ACTIONED.name,
          'readAt': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> markActionedForEntity(String sourceSystem, String entityId, {DatabaseExecutor? executor}) async {
    try {
      final db = executor ?? await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.ACTIONED.name,
          'readAt': now,
        },
        where: 'sourceSystem = ? AND entityId = ? AND status = ?',
        whereArgs: [sourceSystem, entityId, InboxStatus.UNREAD.name],
      );
      
      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> markAllRead() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.READ.name,
          'readAt': now,
        },
        where: "status = 'UNREAD'",
      );

      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> archive(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.ARCHIVED.name,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> expireOverdue() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        'inbox_items',
        {
          'status': InboxStatus.EXPIRED.name,
        },
        where: "expiresAt < ? AND status != 'ARCHIVED'",
        whereArgs: [now],
      );

      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> purgeOld(int retentionDays) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final cutoff = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .millisecondsSinceEpoch;
      
      await db.delete(
        'inbox_items',
        where: "(status = 'ARCHIVED' OR status = 'EXPIRED' OR status = 'ACTIONED') AND createdAt < ?",
        whereArgs: [cutoff],
      );

      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }

  static Future<void> clearAll() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('inbox_items');
      RitmoEventBus().fire(RitmoEvent(
        type: 'inbox_updated',
        timestamp: DateTime.now(),
        payload: {},
      ));
    } catch (e, st) {
      debugPrint('Error in CentralInboxService: $e\n$st');
    }
  }
}
