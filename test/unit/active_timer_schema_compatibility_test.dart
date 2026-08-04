import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/ritmo_timer_service.dart';
import 'package:sqflite/sqflite.dart';

class LegacySchemaMockDb implements Database {
  final List<Map<String, dynamic>> activeTimers = [];

  @override
  bool get isOpen => true;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    // Validate NOT NULL constraints from old system_tables.dart schema
    if (values['routineId'] == null) {
      throw Exception('NOT NULL constraint failed: active_timers.routineId');
    }
    if (values['startedAt'] == null) {
      throw Exception('NOT NULL constraint failed: active_timers.startedAt');
    }
    if (values['plannedDurationMinutes'] == null) {
      throw Exception('NOT NULL constraint failed: active_timers.plannedDurationMinutes');
    }

    final row = Map<String, dynamic>.from(values);
    if (conflictAlgorithm == ConflictAlgorithm.replace && row.containsKey('id')) {
      activeTimers.removeWhere((r) => r['id'] == row['id']);
    }
    activeTimers.add(row);
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
    return activeTimers;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final beforeLen = activeTimers.length;
    activeTimers.removeWhere((r) => r['id'] == whereArgs?[0]);
    return beforeLen - activeTimers.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Active Timer Schema Compatibility Tests', () {
    late LegacySchemaMockDb db;

    setUp(() {
      db = LegacySchemaMockDb();
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('RitmoTimerService.startTimer satisfies legacy NOT NULL constraints (routineId, startedAt, plannedDurationMinutes)', () async {
      await RitmoTimerService.instance.startTimer(
        id: 'routine_schema_test_1',
        domain: 'routine',
        itemId: 'schema_test_1',
        mode: 'FULL',
        durationMinutes: 25,
      );

      expect(db.activeTimers.length, equals(1));
      final inserted = db.activeTimers.first;

      // Verify new fields
      expect(inserted['id'], equals('routine_schema_test_1'));
      expect(inserted['itemId'], equals('schema_test_1'));
      expect(inserted['durationSeconds'], equals(1500));

      // Verify legacy fields
      expect(inserted['routineId'], equals('schema_test_1'));
      expect(inserted['plannedDurationMinutes'], equals(25));
      expect(inserted['startedAt'], isNotNull);
    });
  });
}
