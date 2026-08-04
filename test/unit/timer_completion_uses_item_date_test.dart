import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
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
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return <Map<String, Object?>>[];
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 1;

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
    if (where.contains('routineId = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      if (row['routineId'] != whereArgs[0] && row['id'] != whereArgs[0]) return false;
    }
    if (where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      if (row['id'] != whereArgs[0] && row['routineId'] != whereArgs[0]) return false;
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
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    return db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) {
    return db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 1;

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return db.delete(table, where: where, whereArgs: whereArgs);
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
  }) {
    return db.query(table, columns: columns, where: where, whereArgs: whereArgs, limit: limit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Timer Completion Item Date Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('Timer completion with yesterday dateStr writes completionDate as yesterday', () async {
      const routineId = 'r_yesterday_test';
      const yesterdayDateStr = '2026-08-03';

      await db.insert('routines', {'id': routineId, 'title': 'Yesterday Routine'});

      final outcome = await CompletionGateway.instance.submit(
        const RoutineCompletion(
          routineId: routineId,
          dateStr: yesterdayDateStr,
          result: CompletionResult.full,
          durationMinutes: 30,
        ),
      );

      expect(outcome.didWrite, isTrue);

      final completions = db.tables['routine_completions'] ?? [];
      expect(completions.length, equals(1));
      expect(completions.first['completionDate'], equals(yesterdayDateStr));
    });
  });
}
