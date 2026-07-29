import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RoutineOccurrenceGenerator Conflict & Regeneration Test', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'HEALTH',
            routineType TEXT NOT NULL DEFAULT 'timeBased',
            notificationLevel TEXT NOT NULL DEFAULT 'normal',
            isArchived INTEGER NOT NULL DEFAULT 0,
            displayOrder INTEGER NOT NULL DEFAULT 1,
            createdAt INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE routine_schedules (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            scheduleType TEXT NOT NULL DEFAULT 'DAILY',
            timeOfDay TEXT NOT NULL DEFAULT '08:00',
            createdAt INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE routine_occurrences (
            routine_id TEXT NOT NULL,
            date TEXT NOT NULL,
            scheduled_time TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            PRIMARY KEY (routine_id, date)
          );
        ''');
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('backfillAndGenerateAll does NOT overwrite existing done status because of ConflictAlgorithm.ignore', () async {
      await db.insert('routines', {'id': 'r1', 'title': 'Routine 1', 'category': 'HEALTH', 'routineType': 'timeBased', 'notificationLevel': 'normal'});
      await db.insert('routine_schedules', {'id': 's1', 'routineId': 'r1', 'scheduleType': 'DAILY', 'timeOfDay': '08:00'});
      
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert('routine_occurrences', {'routine_id': 'r1', 'date': todayStr, 'status': 'done'});

      await RoutineOccurrenceGenerator.backfillAndGenerateAll(db);

      final rows = await db.query('routine_occurrences', where: 'routine_id = ? AND date = ?', whereArgs: ['r1', todayStr]);
      expect(rows.first['status'], equals('done'));
    });
  });
}
