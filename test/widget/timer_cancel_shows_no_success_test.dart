import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/features/today/presentation/active_timer_overlay.dart';
import 'package:sqflite/sqflite.dart';

class MockNotificationPlatform implements NotificationPlatform {
  @override
  Future<bool> startTimerMode({
    required String title,
    required int durationSeconds,
    required int elapsedSeconds,
  }) async => true;

  @override
  Future<bool> startStatusMode({
    required String zone,
    required String energy,
    required String proposedTask,
    String? proposedTaskId,
    int completedRoutines = 0,
    int totalRoutines = 0,
    int completedPrayers = 0,
    int totalPrayers = 0,
    List<String>? zoneNames,
    List<String>? zoneIds,
  }) async => true;

  @override
  Future<bool> stopForegroundService() async => true;

  @override
  Future<void> refreshWidgets() async {}

  @override
  Future<Map<String, dynamic>?> getLaunchIntent() async => null;
}

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
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    return 0;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = tables[table] ?? [];
    final beforeLen = list.length;
    list.removeWhere((row) => row['id'] == whereArgs?[0] || row['routineId'] == whereArgs?[0]);
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
    return tables[table] ?? [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return <Map<String, Object?>>[];
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
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) => db.query(table);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async => <Map<String, Object?>>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    if (!sl.isRegistered<NotificationPlatform>()) {
      sl.registerSingleton<NotificationPlatform>(MockNotificationPlatform());
    }
  });

  final testRoutine = Routine(
    id: 'r_cancel_test',
    title: 'تست لغو تایمر',
    category: Category.work,
    routineType: RoutineType.timeBased,
    notificationLevel: NotificationLevel.normal,
    targetDurationMinutes: 10,
    isEssential: false,
    energyRule: EnergyRule.none,
  );

  group('Timer Cancel Behavior Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    testWidgets('Cancelling timer invokes onCancelled callback, shows no success text and writes no completion', (tester) async {
      bool completedFired = false;
      bool cancelledFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveTimerOverlay(
            routine: testRoutine,
            completionMode: 'FULL',
            dateStr: '2026-08-04',
            onCompleted: (_) => completedFired = true,
            onCancelled: () => cancelledFired = true,
          ),
        ),
      );

      await tester.pump();

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(cancelledFired, isTrue);
      expect(completedFired, isFalse);
      expect(find.text('ثبت شد'), findsNothing);
      expect(find.text('تایمر به پایان رسید و روتین ثبت شد'), findsNothing);

      final completions = db.tables['routine_completions'] ?? [];
      expect(completions, isEmpty);
    });
  });
}
