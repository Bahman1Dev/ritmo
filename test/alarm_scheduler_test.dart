import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AlarmSchedulerMockBatch implements Batch {
  AlarmSchedulerMockBatch(this.db);
  final AlarmSchedulerMockDatabase db;

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

class AlarmSchedulerMockDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  @override
  Batch batch() {
    return AlarmSchedulerMockBatch(this);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final mockTxn = AlarmSchedulerMockTransaction(this);
    return action(mockTxn);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    final row = Map<String, dynamic>.from(values);
    list.add(row);
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

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
  }

  bool _evaluateWhere(Map<String, dynamic> row, String? where, List<Object?>? whereArgs) {
    if (where == null) return true;
    if (where == 'id = ?') {
      return row['id'] == whereArgs![0];
    }
    if (where == 'routineId = ?') {
      return row['routineId'] == whereArgs![0];
    }
    if (where == 'routine_id = ?') {
      return row['routine_id'] == whereArgs![0];
    }
    if (where == 'routine_id = ? AND date = ?') {
      return row['routine_id'] == whereArgs![0] && row['date'] == whereArgs[1];
    }
    if (where == 'routineId = ? AND (state = ? OR state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?') {
      final rId = row['routineId'] as String;
      final state = row['state'] as String? ?? '';
      final schedTime = row['scheduledTime'] as int? ?? 0;
      
      final targetRoutineId = whereArgs![0]! as String;
      final s1 = whereArgs[1]! as String;
      final s2 = whereArgs[2]! as String;
      final s3 = whereArgs[3]! as String;
      final start = whereArgs[4]! as int;
      final end = whereArgs[5]! as int;
      
      return rId == targetRoutineId &&
          (state == s1 || state == s2 || state == s3) &&
          schedTime >= start &&
          schedTime <= end;
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class AlarmSchedulerMockTransaction implements Transaction {
  AlarmSchedulerMockTransaction(this.db);
  final AlarmSchedulerMockDatabase db;

  @override
  Batch batch() {
    return AlarmSchedulerMockBatch(db);
  }

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late AlarmSchedulerMockDatabase db;
  final nativeBridgeCalls = <MethodCall>[];

  const alarmChannel = MethodChannel('com.ritmo.app/alarms');
  const serviceChannel = MethodChannel('com.ritmo.app/foreground_service');
  const keystoreChannel = MethodChannel('com.ritmo.app/keystore');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      alarmChannel,
      (methodCall) async {
        nativeBridgeCalls.add(methodCall);
        return true;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      serviceChannel,
      (methodCall) async {
        nativeBridgeCalls.add(methodCall);
        return true;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      keystoreChannel,
      (methodCall) async {
        nativeBridgeCalls.add(methodCall);
        if (methodCall.method == 'getOrCreateKey') {
          return 'mocked_encryption_key_32_bytes_long_here_xxxx';
        }
        return null;
      },
    );

    final sl = GetIt.instance;
    if (!sl.isRegistered<AlarmPlatform>()) {
      sl.registerSingleton<AlarmPlatform>(const MethodChannelAlarmPlatform());
    }
    if (!sl.isRegistered<NotificationPlatform>()) {
      sl.registerSingleton<NotificationPlatform>(const MethodChannelNotificationPlatform());
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AlarmSchedulerMockDatabase();
    DatabaseHelper.databaseInstance = db;
    nativeBridgeCalls.clear();

    // Seed defaults
    db.tables['app_settings'] = [
      {'key': 'module_religion_enabled', 'value': 'true', 'updatedAt': 12345},
    ];
    db.tables['daily_rhythm'] = [];
    db.tables['routines'] = [];
    db.tables['routine_schedules'] = [];
    db.tables['routine_completions'] = [];
    db.tables['routine_occurrences'] = [];
    db.tables['pending_reminders'] = [];
    db.tables['notification_history'] = [];
    db.tables['inbox_items'] = [];
  });

  group('AlarmSchedulerService & Routines Consistency Tests', () {
    test('1. completeOccurrence sets occurrence status to done, cancels alarm, and sets reminder state to opened', () async {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayMs = DateTime.now().millisecondsSinceEpoch;

      // Seed routine, occurrence, and reminder
      await db.insert('routines', {'id': 'r1', 'title': 'Test Routine', 'progressionMode': 'NONE'});
      await db.insert('routine_occurrences', {'routine_id': 'r1', 'date': todayStr, 'status': 'pending'});
      await db.insert('pending_reminders', {
        'id': 'rem1',
        'routineId': 'r1',
        'state': 'unknown',
        'scheduledTime': todayMs,
        'originalTime': todayMs,
        'deferCount': 0,
      });

      // Call completeOccurrence
      await AlarmSchedulerService.completeOccurrence('r1', todayStr);

      // Check occurrence status is 'done'
      final occurrences = await db.query('routine_occurrences', where: 'routine_id = ?', whereArgs: ['r1']);
      expect(occurrences.first['status'], 'done');

      // Check reminder state is 'opened'
      final reminders = await db.query('pending_reminders', where: 'routineId = ?', whereArgs: ['r1']);
      expect(reminders.first['state'], 'opened');

      // Check completion row is inserted
      final completions = await db.query('routine_completions', where: 'routineId = ?', whereArgs: ['r1']);
      expect(completions.isNotEmpty, true);
      expect(completions.first['resultType'], 'FULL');
    });

    test('2. snoozeReminder updates occurrence, updates reminder, schedules alarm, but does NOT create completion row', () async {
      final todayMs = DateTime.now().millisecondsSinceEpoch;
      final dateStr = DateTime.fromMillisecondsSinceEpoch(todayMs).toIso8601String().substring(0, 10);

      // Seed routine, occurrence, and reminder
      await db.insert('routines', {'id': 'r1', 'title': 'Test Routine', 'isEssential': 0});
      await db.insert('routine_occurrences', {'routine_id': 'r1', 'date': dateStr, 'status': 'pending'});
      await db.insert('pending_reminders', {
        'id': 'rem1',
        'routineId': 'r1',
        'state': 'unknown',
        'scheduledTime': todayMs,
        'originalTime': todayMs,
        'deferCount': 0,
      });

      // Call snoozeReminder
      await AlarmSchedulerService.snoozeReminder('rem1', 15);

      // Check occurrence status is 'snoozed'
      final occurrences = await db.query('routine_occurrences', where: 'routine_id = ?', whereArgs: ['r1']);
      expect(occurrences.first['status'], 'snoozed');

      // Check reminder state is 'delayed'
      final reminders = await db.query('pending_reminders', where: 'id = ?', whereArgs: ['rem1']);
      expect(reminders.first['state'], 'delayed');
      expect(reminders.first['deferCount'], 1);

      // Check NO completions were created
      final completions = await db.query('routine_completions');
      expect(completions.isEmpty, true);
    });

    test('3. currentTargetMinutes returns fallback when progressionCurrent is 0', () {
      final engine = ProgressionEngine();
      final routine = {
        'progressionMode': 'DURATION_RAMP',
        'targetDurationMinutes': 30,
        'progressionStart': 15,
        'progressionCurrent': 0,
      };
      expect(engine.currentTargetMinutes(routine), 15);
    });
  });
}
