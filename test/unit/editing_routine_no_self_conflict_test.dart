import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class MockConflictDb implements Database {
  @override
  bool get isOpen => true;

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
    if (table == 'routines') {
      return [
        {
          'id': 'r_water',
          'title': 'نوشیدن آب',
          'category': 'medical',
          'routineType': 'HABIT',
          'notificationLevel': 'DEFAULT',
          'isEssential': 0,
          'displayOrder': 1,
          'createdAt': 0,
          'updatedAt': 0,
          'isArchived': 0,
        }
      ];
    }
    if (table == 'routine_schedules') {
      return [
        {
          'id': 'sched_water',
          'routineId': 'r_water',
          'scheduleType': 'FIXED',
          'timeOfDay': '08:00',
          'intervalHours': 0,
          'createdAt': 0,
          'updatedAt': 0,
        }
      ];
    }
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Editing Routine No Self-Conflict Tests', () {
    late MockConflictDb db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = MockConflictDb();
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('Editing routine excludes self from todayOtherRoutines', () async {
      final routineToEdit = {
        'id': 'r_water',
        'title': 'نوشیدن آب',
        'category': 'medical',
        'routineType': 'HABIT',
        'targetDurationMinutes': 15,
        'timeOfDay': '08:00',
      };

      final controller = PlannerController(
        routineToEdit: routineToEdit,
        onSaved: () {},
        onPageChanged: (_) {},
      );

      controller.init();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final selfFoundInOther = controller.todayOtherRoutines.any((r) => r['id'] == 'r_water' || r['title'] == 'نوشیدن آب');
      expect(selfFoundInOther, isFalse);
    });
  });
}
