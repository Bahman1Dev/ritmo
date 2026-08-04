import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/ritmo_timer_service.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  @override
  bool get isOpen => true;

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    return action(MockTransaction(this));
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    final row = Map<String, dynamic>.from(values);
    if (conflictAlgorithm == ConflictAlgorithm.replace && row.containsKey('id')) {
      final existingIndex = list.indexWhere((r) => r['id'] == row['id']);
      if (existingIndex >= 0) {
        list[existingIndex] = row;
        return 1;
      }
    }
    list.add(row);
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables[table] ?? [];
    var count = 0;
    for (var i = 0; i < list.length; i++) {
      if (_matchWhere(list[i], where, whereArgs)) {
        list[i] = Map<String, dynamic>.from(list[i])..addAll(values);
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = tables[table] ?? [];
    final beforeLen = list.length;
    list.removeWhere((row) => _matchWhere(row, where, whereArgs));
    return beforeLen - list.length;
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
    final list = tables[table] ?? [];
    final res = list.where((row) => _matchWhere(row, where, whereArgs)).toList();
    if (limit != null && res.length > limit) return res.sublist(0, limit);
    return res;
  }

  bool _matchWhere(Map<String, dynamic> row, String? where, List<Object?>? whereArgs) {
    if (where == null) return true;
    if (where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      if (row['id'] != whereArgs[0]) return false;
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockTransaction implements Transaction {
  MockTransaction(this.db);
  final MockDatabase db;

  @override
  bool get isOpen => true;

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) => db.insert(table, values);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) => db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) => db.query(table, where: where, whereArgs: whereArgs);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Single Active Timer Row Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('Starting timer creates 1 row in active_timers, cancelling removes it', () async {
      const timerId = 'routine_single_timer_test';

      // Start timer
      await RitmoTimerService.instance.startTimer(
        id: timerId,
        domain: 'routine',
        itemId: 'single_timer_test',
        mode: 'FULL',
        durationMinutes: 15,
      );

      final activeTimers = db.tables['active_timers'] ?? [];
      expect(activeTimers.length, equals(1));
      expect(activeTimers.first['id'], equals(timerId));

      // Cancel timer
      await RitmoTimerService.instance.cancelTimer(timerId);

      final activeTimersAfter = db.tables['active_timers'] ?? [];
      expect(activeTimersAfter, isEmpty);
    });
  });
}
