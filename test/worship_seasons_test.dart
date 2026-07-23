import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
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
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class WorshipSeasonsDatabase extends MockDatabase {
  final Map<String, List<Map<String, dynamic>>> tables = {
    'worship_seasons': [],
    'routines': [],
    'routine_completions': [],
    'routine_occurrences': [],
  };

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
      if (where.contains('isActive = 1') || where.contains('is_active = 1')) {
        final dateVal = whereArgs![0]! as String;
        return list.where((row) {
          final start = (row['start_date'] ?? row['startDate']) as String;
          final end = (row['end_date'] ?? row['endDate']) as String;
          final active = (row['is_active'] ?? row['isActive'] ?? 1) == 1;
          return active && dateVal.compareTo(start) >= 0 && dateVal.compareTo(end) <= 0;
        }).toList();
      }
      if (where.contains('end_date < ?') || where.contains('endDate < ?')) {
        final dateVal = whereArgs![0]! as String;
        return list.where((row) {
          final end = (row['end_date'] ?? row['endDate']) as String;
          return end.compareTo(dateVal) < 0;
        }).toList();
      }
      return list;
    }

    if (table == 'routines') {
      if (where.contains('category = ?')) {
        final cat = whereArgs![0]! as String;
        return list.where((row) => row['category'] == cat && (row['isArchived'] ?? 0) == 0).toList();
      }
      return list;
    }

    if (table == 'routine_completions' || table == 'routine_occurrences') {
      if (where.contains('routineId IN') || where.contains('routine_id IN')) {
        final ids = whereArgs!;
        final idField = table == 'routine_completions' ? 'routineId' : 'routine_id';
        return list.where((row) => ids.contains(row[idField])).toList();
      }
      return list;
    }

    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    final id = values['id'] ?? 'id_${DateTime.now().millisecondsSinceEpoch}';
    list.removeWhere((row) => row['id'] == id);
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = tables[table] ?? [];
    if (where != null && where.contains('id = ?')) {
      final id = whereArgs!.first! as String;
      list.removeWhere((row) => row['id'] == id);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables[table] ?? [];
    if (where != null && where.contains('id = ?')) {
      final id = whereArgs!.first! as String;
      for (final row in list) {
        if (row['id'] == id) {
          values.forEach((k, v) => row[k] = v);
        }
      }
      return 1;
    }
    return 0;
  }
}

void main() {
  group('Worship Seasons Module Tests', () {
    late WorshipSeasonsDatabase db;

    setUp(() {
      db = WorshipSeasonsDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    test('1. Active Season Detection', () async {
      const todayStr = '2026-06-23';

      final activeSeason = {
        'id': 'ws_1',
        'seasonType': 'FASTING',
        'title': 'ماه رمضان',
        'startDate': '2026-06-01',
        'endDate': '2026-06-30',
        'calendar': 'HIJRI',
        'behaviorJson': '{"behavior": "NORMAL"}',
        'isActive': 1,
        'createdAt': 12345,
        'priority_weight': 7.0,
        // snake_case
        'start_date': '2026-06-01',
        'end_date': '2026-06-30',
        'type': 'fasting',
        'is_active': 1,
      };

      await db.insert('worship_seasons', activeSeason);

      final activeSeasonsInDb = await db.query(
        'worship_seasons',
        where: 'is_active = 1 AND start_date <= ? AND end_date >= ?',
        whereArgs: [todayStr, todayStr],
      );

      expect(activeSeasonsInDb.length, equals(1));
      expect(activeSeasonsInDb.first['id'], equals('ws_1'));
    });

    test('2. Overlap Conflict Resolution (MAX weight)', () async {
      // Mock two active overlapping seasons
      db.tables['worship_seasons'] = [
        {
          'id': 'ws_low',
          'seasonType': 'FASTING',
          'title': 'رمضان کم اولویت',
          'startDate': '2026-06-01',
          'endDate': '2026-06-30',
          'isActive': 1,
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "NORMAL"}',
          'createdAt': 12345,
          'priority_weight': 3.0,
          'start_date': '2026-06-01',
          'end_date': '2026-06-30',
          'type': 'fasting',
          'is_active': 1,
        },
        {
          'id': 'ws_high',
          'seasonType': 'SPIRITUAL',
          'title': 'اعتکاف پر اولویت',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'isActive': 1,
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "NORMAL"}',
          'createdAt': 12346,
          'priority_weight': 8.0,
          'start_date': '2026-06-20',
          'end_date': '2026-06-25',
          'type': 'spiritual',
          'is_active': 1,
        }
      ];

      final behavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        db: db,
        date: DateTime(2026, 6, 21),
        settings: {'module_religion_enabled': 'true'},
      );

      expect(behavior.context, equals(LifeContext.worship));
      expect(behavior.activeWorshipSeasonTitle, equals('اعتکاف پر اولویت'));
    });

    test('3. CRUD Operations', () async {
      final season = {
        'id': 'ws_test',
        'seasonType': 'CUSTOM',
        'title': 'چله جدید',
        'startDate': '2026-07-01',
        'endDate': '2026-07-10',
        'calendar': 'HIJRI',
        'behaviorJson': '{"behavior": "NORMAL"}',
        'isActive': 1,
        'createdAt': 12347,
        'priority_weight': 5.0,
        'start_date': '2026-07-01',
        'end_date': '2026-07-10',
        'type': 'custom',
        'is_active': 1,
      };

      // Create
      await db.insert('worship_seasons', season);
      final list = db.tables['worship_seasons']!;
      expect(list.length, equals(1));
      expect(list.first['title'], equals('چله جدید'));

      // Update
      await db.update(
        'worship_seasons',
        {'title': 'چله ویرایش شده'},
        where: 'id = ?',
        whereArgs: ['ws_test'],
      );
      expect(list.first['title'], equals('چله ویرایش شده'));

      // Deactivate
      await db.update(
        'worship_seasons',
        {'is_active': 0, 'isActive': 0},
        where: 'id = ?',
        whereArgs: ['ws_test'],
      );
      expect(list.first['is_active'], equals(0));

      // Delete
      await db.delete('worship_seasons', where: 'id = ?', whereArgs: ['ws_test']);
      expect(list.isEmpty, isTrue);
    });

    test('4. calculateWorshipCorrelation with test fixtures', () async {
      // Seed a past worship season
      db.tables['worship_seasons'] = [
        {
          'id': 'ws_past',
          'seasonType': 'FASTING',
          'title': 'رمضان گذشته',
          'startDate': '2026-05-01',
          'endDate': '2026-05-30',
          'isActive': 1,
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "NORMAL"}',
          'createdAt': 10000,
          'priority_weight': 7.0,
          'start_date': '2026-05-01',
          'end_date': '2026-05-30',
          'type': 'fasting',
          'is_active': 1,
        }
      ];

      // Seed a religious routine
      db.tables['routines'] = [
        {
          'id': 'r_rel_1',
          'title': 'نماز اول وقت',
          'category': 'RELIGIOUS',
          'routineType': 'ROUTINE',
          'notificationLevel': 'HIGH',
          'displayOrder': 1,
          'isArchived': 0,
          'createdAt': 10000,
          'updatedAt': 10000,
        }
      ];

      // Seed occurrences inside the past season (May 1 to May 30)
      // and outside the season (June 1 onwards)
      db.tables['routine_occurrences'] = [
        // Inside
        {'routine_id': 'r_rel_1', 'date': '2026-05-05', 'scheduled_time': '12:30', 'status': 'done'},
        {'routine_id': 'r_rel_1', 'date': '2026-05-10', 'scheduled_time': '12:30', 'status': 'done'},
        {'routine_id': 'r_rel_1', 'date': '2026-05-15', 'scheduled_time': '12:30', 'status': 'done'},
        {'routine_id': 'r_rel_1', 'date': '2026-05-20', 'scheduled_time': '12:30', 'status': 'pending'}, // missed
        // Outside
        {'routine_id': 'r_rel_1', 'date': '2026-06-05', 'scheduled_time': '12:30', 'status': 'done'},
        {'routine_id': 'r_rel_1', 'date': '2026-06-10', 'scheduled_time': '12:30', 'status': 'pending'}, // missed
        {'routine_id': 'r_rel_1', 'date': '2026-06-15', 'scheduled_time': '12:30', 'status': 'pending'}, // missed
        {'routine_id': 'r_rel_1', 'date': '2026-06-20', 'scheduled_time': '12:30', 'status': 'pending'}, // missed
      ];

      // Inside: 3 completed out of 4 scheduled -> 75% completion rate
      // Outside: 1 completed out of 4 scheduled -> 25% completion rate
      // Difference: +50% completion rate growth!
      db.tables['routine_completions'] = [
        {'id': 'c1', 'routineId': 'r_rel_1', 'completionDate': '2026-05-05', 'completionTime': 100000000000, 'resultType': 'FULL'},
        {'id': 'c2', 'routineId': 'r_rel_1', 'completionDate': '2026-05-10', 'completionTime': 100000000000, 'resultType': 'FULL'},
        {'id': 'c3', 'routineId': 'r_rel_1', 'completionDate': '2026-05-15', 'completionTime': 100000000000, 'resultType': 'FULL'},
        {'id': 'c4', 'routineId': 'r_rel_1', 'completionDate': '2026-06-05', 'completionTime': 100000000000, 'resultType': 'FULL'},
      ];

      final correlation = await InsightGenerationEngine.calculateWorshipCorrelation();
      expect(correlation, equals('+50%'));
    });
  });
}
