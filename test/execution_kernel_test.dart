import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/post_commit_pipeline.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final List<Map<String, dynamic>> loggedInserts = [];
  final List<Map<String, dynamic>> loggedUpdates = [];
  final List<Map<String, dynamic>> loggedDeletes = [];

  @override
  Batch batch() {
    return MockBatch(this);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final mockTxn = MockTransaction(this);
    return action(mockTxn);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    final row = Map<String, dynamic>.from(values);
    list.add(row);
    loggedInserts.add({'table': table, 'values': row});
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
        loggedUpdates.add({
          'table': table,
          'values': values,
          'where': where,
          'whereArgs': whereArgs,
        });
      }
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = tables[table] ?? [];
    final beforeLength = list.length;
    
    for (final row in list) {
      if (_evaluateWhere(row, where, whereArgs)) {
        loggedDeletes.add({'table': table, 'row': row});
      }
    }
    
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
    if (sql.contains('SELECT MIN(completionDate)')) {
      final completions = tables['routine_completions'] ?? [];
      if (completions.isEmpty) return [];
      String? minDate;
      for (final c in completions) {
        final date = c['completionDate'] as String?;
        if (date != null) {
          if (minDate == null || date.compareTo(minDate) < 0) {
            minDate = date;
          }
        }
      }
      return [{'minDate': minDate}];
    }
    
    if (sql.contains('SELECT pr.id, pr.routineId, pr.scheduledTime, r.title, r.isEssential')) {
      final reminders = tables['pending_reminders'] ?? [];
      final routines = tables['routines'] ?? [];
      final results = <Map<String, Object?>>[];
      for (final pr in reminders) {
        final state = pr['state'] as String? ?? 'unknown';
        if (state == 'unknown' || state == 'delayed') {
          final rId = pr['routineId'] as String?;
          final routine = routines.firstWhere((r) => r['id'] == rId, orElse: () => <String, dynamic>{});
          if (routine.isNotEmpty && routine['isArchived'] != 1) {
            results.add({
              'id': pr['id'],
              'routineId': pr['routineId'],
              'scheduledTime': pr['scheduledTime'],
              'title': routine['title'],
              'isEssential': routine['isEssential'],
            });
          }
        }
      }
      return results;
    }
    
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
    if (where == 'routine_id = ? AND date >= ?') {
      final rId = row['routine_id'] as String;
      final date = row['date'] as String;
      final targetId = whereArgs![0]! as String;
      final targetDate = whereArgs[1]! as String;
      return rId == targetId && date.compareTo(targetDate) >= 0;
    }
    if (where == "routineId = ? AND (state = 'unknown' OR state = 'delayed')") {
      final state = row['state'] as String? ?? '';
      return row['routineId'] == whereArgs![0] && (state == 'unknown' || state == 'delayed');
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
    if (where == 'isArchived = 0') {
      return row['isArchived'] == 0 || row['isArchived'] == false;
    }
    if (where == 'routineId = ? AND (state = ? OR state = ?) AND scheduledTime >= ? AND scheduledTime <= ?') {
      final rId = row['routineId'] as String;
      final state = row['state'] as String? ?? '';
      final schedTime = row['scheduledTime'] as int? ?? 0;
      
      final targetRoutineId = whereArgs![0]! as String;
      final s1 = whereArgs[1]! as String;
      final s2 = whereArgs[2]! as String;
      final start = whereArgs[3]! as int;
      final end = whereArgs[4]! as int;
      
      return rId == targetRoutineId &&
          (state == s1 || state == s2) &&
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

class MockTransaction implements Transaction {
  MockTransaction(this.db);
  final MockDatabase db;

  @override
  Batch batch() {
    return MockBatch(db);
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

  late MockDatabase db;
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
    db = MockDatabase();
    DatabaseHelper.databaseInstance = db;
    nativeBridgeCalls.clear();

    // Seed defaults
    db.tables['app_settings'] = [
      {'key': 'module_religion_enabled', 'value': 'true', 'updatedAt': 12345},
      {'key': 'energy_validity_minutes', 'value': '180', 'updatedAt': 12345},
    ];
  });

  group('RitmoExecutionKernel Tests', () {
    test('1. CreateRoutineCommand inserts routine, schedule and generates future occurrences', () async {
      const routineId = 'r_test_1';
      final command = CreateRoutineCommand(
        routineData: {
          'id': routineId,
          'title': 'روتین تست صبحگاهی',
          'category': 'personal',
          'routineType': 'timeBased',
          'notificationLevel': 'normal',
          'isEssential': 0,
          'isArchived': 0,
          'displayOrder': 1,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        scheduleData: {
          'id': 's_test_1',
          'routineId': routineId,
          'scheduleType': 'daily',
          'timeOfDay': '08:00',
          'recurrenceRule': jsonEncode({
            'weekdays': [1, 2, 3, 4, 5, 6, 7], // Every day
            'reminderTimes': ['08:00'],
          }),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify DB Insertions
      final routines = db.tables['routines'] ?? [];
      expect(routines.any((r) => r['id'] == routineId), true);
      
      final schedules = db.tables['routine_schedules'] ?? [];
      expect(schedules.any((s) => s['routineId'] == routineId), true);

      // Verify occurrences are generated
      final occurrences = db.tables['routine_occurrences'] ?? [];
      expect(occurrences.isNotEmpty, true);
      expect(occurrences.first['routine_id'], routineId);
      expect(occurrences.first['status'], 'pending');

      // Verify Event Bus
      expect(firedEvents.length, 1);
      expect(firedEvents.first.type, 'RoutineCreated');
      expect(firedEvents.first.payload['routineId'], routineId);
    });

    test('2. EditRoutineCommand edits routine, cancels existing alarms, regenerates future occurrences', () async {
      const routineId = 'r_edit_test';
      
      // Setup initial routine and schedules
      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین قدیمی',
          'category': 'personal',
          'routineType': 'timeBased',
          'notificationLevel': 'normal',
          'isEssential': 0,
          'isArchived': 0,
          'displayOrder': 1,
        }
      ];
      
      db.tables['routine_schedules'] = [
        {
          'id': 's_edit_test',
          'routineId': routineId,
          'scheduleType': 'daily',
          'timeOfDay': '08:00',
          'recurrenceRule': jsonEncode({
            'weekdays': [1, 2, 3, 4, 5, 6, 7],
            'reminderTimes': ['08:00'],
          }),
        }
      ];

      // Seed pending reminders (active)
      db.tables['pending_reminders'] = [
        {
          'id': 'rem_1',
          'routineId': routineId,
          'originalTime': DateTime.now().millisecondsSinceEpoch,
          'scheduledTime': DateTime.now().millisecondsSinceEpoch,
          'state': 'unknown', // active state
          'deferCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      final command = EditRoutineCommand(
        routineId: routineId,
        routineData: {
          'id': routineId,
          'title': 'روتین ویرایش‌شده',
          'category': 'personal',
          'routineType': 'timeBased',
          'notificationLevel': 'normal',
          'isEssential': 0,
          'isArchived': 0,
          'displayOrder': 1,
        },
        scheduleData: {
          'id': 's_edit_test',
          'routineId': routineId,
          'scheduleType': 'daily',
          'timeOfDay': '09:30', // Updated time
          'recurrenceRule': jsonEncode({
            'weekdays': [1, 2, 3, 4, 5, 6, 7],
            'reminderTimes': ['09:30'],
          }),
        },
        applyToAll: true,
      );

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify title updated
      final updatedRoutine = db.tables['routines']!.firstWhere((r) => r['id'] == routineId);
      expect(updatedRoutine['title'], 'روتین ویرایش‌شده');

      // Verify old alarms cancelled in DB and platform channel invoked
      final reminder = db.tables['pending_reminders']!.firstWhere((r) => r['id'] == 'rem_1');
      expect(reminder['state'], 'CANCELLED');
      
      expect(nativeBridgeCalls.any((call) => call.method == 'cancelAlarm' && call.arguments['id'] == 'rem_1'), true);

      // Verify Event Bus
      expect(firedEvents.any((e) => e.type == 'RoutineEdited' && e.payload['routineId'] == routineId), true);
    });

    test('3. DeleteRoutineCommand archives routine, cancels alarms, removes occurrences', () async {
      const routineId = 'r_delete_test';
      
      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین موقت',
          'isArchived': 0,
        }
      ];

      db.tables['pending_reminders'] = [
        {
          'id': 'rem_delete',
          'routineId': routineId,
          'originalTime': DateTime.now().millisecondsSinceEpoch,
          'scheduledTime': DateTime.now().millisecondsSinceEpoch,
          'state': 'delayed', // active state
          'deferCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      db.tables['routine_occurrences'] = [
        {
          'routine_id': routineId,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'scheduled_time': '08:00',
          'status': 'pending',
        }
      ];

      const command = DeleteRoutineCommand(routineId: routineId);

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify archived
      final routine = db.tables['routines']!.firstWhere((r) => r['id'] == routineId);
      expect(routine['isArchived'], 1);

      // Verify reminders cancelled in DB and NativeBridge
      final reminder = db.tables['pending_reminders']!.firstWhere((r) => r['id'] == 'rem_delete');
      expect(reminder['state'], 'CANCELLED');
      expect(nativeBridgeCalls.any((call) => call.method == 'cancelAlarm' && call.arguments['id'] == 'rem_delete'), true);

      // Verify future occurrences deleted
      final occurrences = db.tables['routine_occurrences'] ?? [];
      expect(occurrences.isEmpty, true);

      // Verify Event Bus
      expect(firedEvents.any((e) => e.type == 'RoutineDeleted' && e.payload['routineId'] == routineId), true);
    });

    test("4. CompleteOccurrenceCommand logs completion, updates status, and cancels today's remaining alarms", () async {
      const routineId = 'r_complete_test';
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayStartMs = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;

      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین نهایی',
          'isEssential': 0,
          'isArchived': 0,
        }
      ];

      db.tables['routine_occurrences'] = [
        {
          'routine_id': routineId,
          'date': todayStr,
          'scheduled_time': '12:00',
          'status': 'pending',
        }
      ];

      db.tables['pending_reminders'] = [
        {
          'id': 'rem_comp',
          'routineId': routineId,
          'originalTime': todayStartMs + 12 * 60 * 60 * 1000,
          'scheduledTime': todayStartMs + 12 * 60 * 60 * 1000,
          'state': 'sent',
          'deferCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      final command = CompleteOccurrenceCommand(
        routineId: routineId,
        dateStr: todayStr,
        resultType: 'FULL',
        durationMinutes: 30,
        note: 'احساس خوبی دارم',
      );

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify completion inserted
      final completions = db.tables['routine_completions'] ?? [];
      expect(completions.isNotEmpty, true);
      expect(completions.first['routineId'], routineId);
      expect(completions.first['resultType'], 'FULL');

      // Verify occurrence status is 'done'
      final occurrence = db.tables['routine_occurrences']!.firstWhere((o) => o['routine_id'] == routineId && o['date'] == todayStr);
      expect(occurrence['status'], 'done');

      // Verify reminder state updated to 'opened' and NativeBridge cancelAlarm triggered
      final reminder = db.tables['pending_reminders']!.firstWhere((r) => r['id'] == 'rem_comp');
      expect(reminder['state'], 'opened');
      expect(nativeBridgeCalls.any((call) => call.method == 'cancelAlarm' && call.arguments['id'] == 'rem_comp'), true);

      // Verify Event Bus
      expect(firedEvents.any((e) => e.type == 'RoutineCompleted' && e.payload['routineId'] == routineId), true);
    });

    test('5. SkipOccurrenceCommand logs skip completion, updates status, and cancels remaining alarms', () async {
      const routineId = 'r_skip_test';
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayStartMs = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;

      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین ورزشی',
          'isEssential': 0,
          'isArchived': 0,
        }
      ];

      db.tables['routine_occurrences'] = [
        {
          'routine_id': routineId,
          'date': todayStr,
          'scheduled_time': '15:00',
          'status': 'pending',
        }
      ];

      db.tables['pending_reminders'] = [
        {
          'id': 'rem_skip',
          'routineId': routineId,
          'originalTime': todayStartMs + 15 * 60 * 60 * 1000,
          'scheduledTime': todayStartMs + 15 * 60 * 60 * 1000,
          'state': 'unknown',
          'deferCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      final command = SkipOccurrenceCommand(
        routineId: routineId,
        dateStr: todayStr,
        reason: 'خستگی مفرط',
      );

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify completion type is 'SKIPPED'
      final completions = db.tables['routine_completions'] ?? [];
      expect(completions.isNotEmpty, true);
      expect(completions.first['resultType'], 'SKIPPED');
      expect(completions.first['note'], 'خستگی مفرط');

      // Verify occurrence status is 'skipped'
      final occurrence = db.tables['routine_occurrences']!.firstWhere((o) => o['routine_id'] == routineId && o['date'] == todayStr);
      expect(occurrence['status'], 'skipped');

      // Verify Event Bus
      expect(firedEvents.any((e) => e.type == 'RoutineSkipped' && e.payload['routineId'] == routineId), true);
    });

    test('6. SnoozeReminderCommand updates snooze time and schedules new alarm', () async {
      const reminderId = 'rem_snooze_test';
      const routineId = 'r_snooze';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین قرص صبح',
          'isEssential': 1, // Essential task
          'isArchived': 0,
        }
      ];

      db.tables['pending_reminders'] = [
        {
          'id': reminderId,
          'routineId': routineId,
          'originalTime': nowMs,
          'scheduledTime': nowMs,
          'state': 'sent',
          'deferCount': 1,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      db.tables['routine_occurrences'] = [
        {
          'routine_id': routineId,
          'date': DateTime.fromMillisecondsSinceEpoch(nowMs).toIso8601String().substring(0, 10),
          'scheduled_time': '08:00',
          'status': 'pending',
        }
      ];

      const command = SnoozeReminderCommand(reminderId: reminderId, dateStr: '2026-07-25', snoozeMinutes: 15);

      final firedEvents = <RitmoEvent>[];
      final subscription = RitmoEventBus().onEvents.listen(firedEvents.add);

      await RitmoExecutionKernel.instance.execute(command);
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      // Verify reminder state is 'delayed' and deferCount incremented
      final reminder = db.tables['pending_reminders']!.firstWhere((r) => r['id'] == reminderId);
      expect(reminder['state'], 'delayed');
      expect(reminder['deferCount'], 2);

      // Verify occurrence status is 'snoozed'
      final occurrence = db.tables['routine_occurrences']!.firstWhere((o) => o['routine_id'] == routineId);
      expect(occurrence['status'], 'snoozed');

      // Verify NativeBridge cancels old alarm and schedules exact alarm 15 mins later
      expect(nativeBridgeCalls.any((call) => call.method == 'cancelAlarm' && call.arguments['id'] == reminderId), true);
      expect(nativeBridgeCalls.any((call) => call.method == 'scheduleExactAlarm' && call.arguments['id'] == reminderId && call.arguments['isEssential'] == true), true);

      // Verify Event Bus
      expect(firedEvents.any((e) => e.type == 'RoutineEdited' && e.payload['reminderId'] == reminderId), true);
    });

    test('7. ConfirmReshuffleCommand shifts scheduled times for active reminders', () async {
      const routineId = 'r_reshuffle';
      final now = DateTime.now();
      final newTime = now.add(const Duration(minutes: 45));

      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین بااهمیت',
          'isEssential': 1,
          'isArchived': 0,
        }
      ];

      db.tables['pending_reminders'] = [
        {
          'id': 'rem_reshuffle',
          'routineId': routineId,
          'originalTime': now.millisecondsSinceEpoch,
          'scheduledTime': now.millisecondsSinceEpoch,
          'state': 'unknown',
          'deferCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      final command = ConfirmReshuffleCommand(actions: [
        ReshuffleAction(
          routineId: routineId,
          routineTitle: 'روتین بااهمیت',
          actionType: ReshuffleActionType.shiftWithinZone,
          originalTime: now,
          newTime: newTime,
        )
      ]);

      await RitmoExecutionKernel.instance.execute(command);

      // Verify reminder's scheduledTime is updated
      final reminder = db.tables['pending_reminders']!.firstWhere((r) => r['id'] == 'rem_reshuffle');
      expect(reminder['scheduledTime'], newTime.millisecondsSinceEpoch);

      // Verify NativeBridge schedules new exact alarm
      expect(nativeBridgeCalls.any((call) => call.method == 'scheduleExactAlarm' && call.arguments['id'] == 'rem_reshuffle' && call.arguments['time'] == newTime.millisecondsSinceEpoch), true);
    });

    test('8. CompleteOccurrenceCommand triggers ProgressionEngine and updates progressionCurrent', () async {
      const routineId = 'r_progression_test';
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      db.tables['routines'] = [
        {
          'id': routineId,
          'title': 'روتین تدریجی',
          'isEssential': 0,
          'isArchived': 0,
          'progressionMode': 'DURATION_RAMP',
          'progressionStart': 10,
          'progressionTarget': 20,
          'progressionStep': 5,
          'progressionEveryN': 1,
          'progressionCurrent': 10,
          'progressionDoneSinceAdvance': 0,
        }
      ];

      db.tables['routine_occurrences'] = [
        {
          'routine_id': routineId,
          'date': todayStr,
          'scheduled_time': '12:00',
          'status': 'pending',
        }
      ];

      final command = CompleteOccurrenceCommand(
        routineId: routineId,
        dateStr: todayStr,
        resultType: 'FULL',
        durationMinutes: 10,
      );

      await RitmoExecutionKernel.instance.execute(command);

      // Verify that progressionCurrent went from 10 to 15
      final routine = db.tables['routines']!.firstWhere((r) => r['id'] == routineId);
      expect(routine['progressionCurrent'], 15);
      expect(routine['progressionDoneSinceAdvance'], 0);
    });

    test('9. PostCommitPipeline continues after one task failure (failure isolation)', () async {
      final calls = <String>[];

      final tasks = <Future<void> Function()>[
        () async {
          calls.add('first');
          throw Exception('boom');
        },
        () async {
          calls.add('second');
        },
      ];

      await PostCommitPipeline.run(tasks);

      expect(calls, ['first', 'second']);
    });

    test('10. PostCommitPipeline executes all tasks in order', () async {
      final calls = <int>[];

      final tasks = <Future<void> Function()>[
        () async => calls.add(1),
        () async => calls.add(2),
        () async => calls.add(3),
      ];

      await PostCommitPipeline.run(tasks);

      expect(calls, [1, 2, 3]);
    });
  });
}

