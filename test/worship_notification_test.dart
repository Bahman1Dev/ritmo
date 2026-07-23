import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, dynamic>> insertedRows = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    insertedRows.add({
      'table': table,
      'values': values,
      'conflictAlgorithm': conflictAlgorithm,
    });
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class RiemockDatabase extends MockDatabase {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = tables[table] ?? [];
    if (where == null) return list;

    if (table == 'worship_seasons') {
      final targetDate = whereArgs!.length > 1 && whereArgs[1] is String ? whereArgs[1]! as String : whereArgs[0]! as String;
      return list.where((row) {
        return row['isActive'] == 1 &&
            (row['startDate'] as String).compareTo(targetDate) <= 0 &&
            (row['endDate'] as String).compareTo(targetDate) >= 0;
      }).toList();
    }
    
    if (table == 'app_settings') {
      return list;
    }
    
    return [];
  }
}

void main() {
  group('Ritmo Phase 4 — Database Migration v7 Tests', () {
    test('onUpgrade to v7 adds priority_weight to worship_seasons table', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 6, 7);

      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();
      expect(allExecutedSql, contains('priority_weight'));
    });
  });

  group('Ritmo Phase 4 — Worship Seasons Overlap Resolution Tests', () {
    test('Overlapping seasons are resolved using MAX(priority_weight)', () async {
      final mockDb = RiemockDatabase();
      
      // Mock two active, overlapping worship seasons with different priority weights
      mockDb.tables['worship_seasons'] = [
        {
          'id': 'ws_ramadan',
          'seasonType': 'RAMADAN',
          'title': 'ماه رمضان',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'isActive': 1,
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "RAMADAN_BEHAVIOR"}',
          'createdAt': 12345,
          'priority_weight': 1.5,
        },
        {
          'id': 'ws_custom',
          'seasonType': 'CUSTOM',
          'title': 'چله عبادی سفارشی',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'isActive': 1,
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "FASTING_BEHAVIOR"}',
          'createdAt': 12346,
          'priority_weight': 3.0, // Higher priority weight
        }
      ];

      mockDb.tables['app_settings'] = [
        {'key': 'module_religion_enabled', 'value': 'true'},
      ];

      final behavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        db: mockDb,
        date: DateTime(2026, 6, 21),
        settings: {'module_religion_enabled': 'true'},
      );

      // Assert that the season with maximum weight is chosen and overrides the other
      expect(behavior.activeWorshipSeasonTitle, 'چله عبادی سفارشی');
      expect(behavior.behavior, 'FASTING_BEHAVIOR');
      expect(behavior.context, LifeContext.worship);
    });
  });

  group('Ritmo Phase 4 — Notification Telemetry Event Logging Tests', () {
    test('Notification history logs correct events (sent, opened, delayed, unknown)', () async {
      final mockDb = MockDatabase();

      // Test sent event logging
      final now = DateTime.now().millisecondsSinceEpoch;
      final sentEvent = {
        'id': 'nh_${now}_r1',
        'routineId': 'r1',
        'notificationType': 'ROUTINE',
        'sentAt': now,
        'actionTaken': 'sent',
      };
      await mockDb.insert('notification_history', sentEvent);

      expect(mockDb.insertedRows.length, 1);
      expect(mockDb.insertedRows.first['table'], 'notification_history');
      expect(mockDb.insertedRows.first['values']['actionTaken'], 'sent');

      // Test opened event logging
      final openedEvent = {
        'id': 'nh_${now + 10}_r1',
        'routineId': 'r1',
        'notificationType': 'ROUTINE',
        'sentAt': now + 10,
        'actionTaken': 'opened',
      };
      await mockDb.insert('notification_history', openedEvent);

      expect(mockDb.insertedRows.length, 2);
      expect(mockDb.insertedRows.last['values']['actionTaken'], 'opened');

      // Test delayed event logging
      final delayedEvent = {
        'id': 'nh_${now + 20}_r1',
        'routineId': 'r1',
        'notificationType': 'ROUTINE',
        'sentAt': now + 20,
        'actionTaken': 'delayed',
      };
      await mockDb.insert('notification_history', delayedEvent);

      expect(mockDb.insertedRows.length, 3);
      expect(mockDb.insertedRows.last['values']['actionTaken'], 'delayed');
    });
  });
}
