import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 5 routine_actual_completions SQL VIEW Tests (K-29)', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE routine_completions (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            completionDate TEXT NOT NULL,
            completionTime INTEGER NOT NULL,
            resultType TEXT NOT NULL,
            resultSource TEXT NOT NULL DEFAULT 'USER',
            createdAt INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE VIEW routine_actual_completions AS
          SELECT * FROM routine_completions
          WHERE resultType IN ('FULL', 'PARTIAL', 'MINIMAL', 'DONE', 'LIGHT', 'COMPLETED');
        ''');
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('routine_actual_completions includes actual completions and excludes SKIPPED / RESCHEDULED', () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.insert('routine_completions', {'id': 'c1', 'routineId': 'r1', 'completionDate': '2026-08-03', 'completionTime': nowMs, 'resultType': 'FULL', 'createdAt': nowMs});
      await db.insert('routine_completions', {'id': 'c2', 'routineId': 'r1', 'completionDate': '2026-08-03', 'completionTime': nowMs, 'resultType': 'LIGHT', 'createdAt': nowMs});
      await db.insert('routine_completions', {'id': 'c3', 'routineId': 'r1', 'completionDate': '2026-08-03', 'completionTime': nowMs, 'resultType': 'SKIPPED', 'createdAt': nowMs});
      await db.insert('routine_completions', {'id': 'c4', 'routineId': 'r1', 'completionDate': '2026-08-03', 'completionTime': nowMs, 'resultType': 'RESCHEDULED', 'createdAt': nowMs});

      final allRows = await db.query('routine_completions');
      expect(allRows.length, equals(4));

      final actualRows = await db.query('routine_actual_completions');
      expect(actualRows.length, equals(2));
      final resultTypes = actualRows.map((r) => r['resultType']).toList();
      expect(resultTypes, containsAll(['FULL', 'LIGHT']));
      expect(resultTypes, isNot(contains('SKIPPED')));
      expect(resultTypes, isNot(contains('RESCHEDULED')));
    });
  });
}
