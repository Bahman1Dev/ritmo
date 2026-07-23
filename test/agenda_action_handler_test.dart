import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:sqflite/sqflite.dart';

class MockBatch implements Batch {
  MockBatch(this.db);
  final MockDatabase db;
  final List<Function> _ops = [];

  @override
  void insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    _ops.add(() => db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm));
  }

  @override
  void update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) {
    _ops.add(() => db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm));
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _ops.add(() => db.delete(table, where: where, whereArgs: whereArgs));
  }

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError}) async {
    final results = <Object?>[];
    for (final op in _ops) {
      results.add(await op());
    }
    return results;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  @override
  Batch batch() => MockBatch(this);

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final mockTxn = MockTransaction(this);
    return action(mockTxn);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables[table] ?? [];
    var count = 0;
    for (var i = 0; i < list.length; i++) {
      if (_evaluateWhere(list[i], where, whereArgs)) {
        final updatedRow = Map<String, dynamic>.from(list[i])..addAll(values);
        list[i] = updatedRow;
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = tables[table] ?? [];
    final beforeLength = list.length;
    list.removeWhere((row) => _evaluateWhere(row, where, whereArgs));
    return beforeLength - list.length;
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
    final filtered = list.where((row) => _evaluateWhere(row, where, whereArgs)).toList();
    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  bool _evaluateWhere(Map<String, dynamic> row, String? where, List<Object?>? whereArgs) {
    if (where == null) return true;
    if (where == 'id = ?') {
      return row['id'] == whereArgs![0];
    }
    if (where == 'debtType = ? AND title = ? AND isArchived = 0') {
      return row['debtType'] == whereArgs![0] &&
          row['title'] == whereArgs[1] &&
          (row['isArchived'] == 0 || row['isArchived'] == false);
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockTransaction implements Transaction {
  MockTransaction(this.db);
  final MockDatabase db;

  @override
  Batch batch() => MockBatch(db);

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    return db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) {
    return db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
  }

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
    return db.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return db.noSuchMethod(invocation);
  }
}

void main() {
  group('AgendaActionHandler Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    test('Snooze increments deferCount up to 3 and schedules a reminder', () async {
      await db.insert('worship_practices', {
        'id': 'wp_fajr',
        'deferCount': 1,
        'lastDeferredUntil': null,
      });

      await AgendaActionHandler.instance.snoozePrayer(
        practiceIds: ['wp_fajr'],
        minutes: 15,
        dateStr: '2026-07-05',
      );

      final practices = db.tables['worship_practices']!;
      expect(practices.first['deferCount'], equals(2));
      expect(practices.first['lastDeferredUntil'], isNotNull);

      final reminders = db.tables['pending_reminders']!;
      expect(reminders.length, equals(1));
      expect(reminders.first['routineId'], equals('worship_wp_fajr'));
      expect(reminders.first['deferCount'], equals(2));
    });

    test('Snooze throws exception when deferCount limit (3) is exceeded', () async {
      await db.insert('worship_practices', {
        'id': 'wp_fajr',
        'deferCount': 3,
        'lastDeferredUntil': null,
      });

      expect(
        () => AgendaActionHandler.instance.snoozePrayer(
          practiceIds: ['wp_fajr'],
          minutes: 15,
          dateStr: '2026-07-05',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Skip prayer updates status to -1 and adds to qada debts', () async {
      await db.insert('worship_practices', {
        'id': 'wp_fajr',
        'subType': 'FAJR',
        'title': 'نماز صبح',
        'practiceType': 'PRAYER',
        'dailyDone': 0,
      });

      await AgendaActionHandler.instance.skipPrayer(
        practices: [
          {
            'id': 'wp_fajr',
            'subType': 'FAJR',
            'title': 'نماز صبح',
            'practiceType': 'PRAYER',
          }
        ],
        addToQada: true,
        dateStr: '2026-07-05',
      );

      final practices = db.tables['worship_practices']!;
      expect(practices.first['dailyDone'], equals(-1));

      final debts = db.tables['worship_debts']!;
      expect(debts.length, equals(1));
      expect(debts.first['debtType'], equals('PRAYER'));
      expect(debts.first['title'], equals('نماز صبح'));
      expect(debts.first['remainingCount'], equals(1));
    });
  });
}
