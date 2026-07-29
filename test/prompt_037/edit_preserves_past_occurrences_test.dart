import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/handlers/edit_routine_handler.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WU-10: EditRoutineHandler Occurrence Safety', () {
    test('editing a routine preserves past and completed occurrences', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE routines (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              category TEXT NOT NULL,
              routineType TEXT NOT NULL,
              notificationLevel TEXT NOT NULL,
              isEssential INTEGER NOT NULL DEFAULT 0,
              energyRule TEXT NOT NULL DEFAULT 'NONE',
              priority REAL NOT NULL DEFAULT 1.0,
              targetDurationMinutes INTEGER,
              lightDurationMinutes INTEGER,
              minimalDurationMinutes INTEGER,
              isArchived INTEGER NOT NULL DEFAULT 0,
              displayOrder INTEGER NOT NULL DEFAULT 1,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE routine_schedules (
              id TEXT PRIMARY KEY,
              routineId TEXT NOT NULL,
              scheduleType TEXT NOT NULL,
              timeOfDay TEXT,
              daysOfWeek TEXT,
              recurrenceRule TEXT,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL
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

          await db.execute('''
            CREATE TABLE pending_reminders (
              id TEXT PRIMARY KEY,
              routineId TEXT NOT NULL,
              state TEXT NOT NULL DEFAULT 'unknown',
              updatedAt INTEGER NOT NULL
            );
          ''');
        },
      );

      final routineId = 'test_routine_1';
      final pastDate = '2026-05-10';
      final futureDate = '2026-08-01';

      // Insert routine & schedule
      await db.insert('routines', {
        'id': routineId,
        'title': 'قدیمی',
        'category': 'personal',
        'routineType': 'timeBased',
        'notificationLevel': 'normal',
        'displayOrder': 1,
        'createdAt': 1000,
        'updatedAt': 1000,
      });

      await db.insert('routine_schedules', {
        'id': 'sched_$routineId',
        'routineId': routineId,
        'scheduleType': 'EVERY_DAY',
        'timeOfDay': '08:00',
        'recurrenceRule': '{"weekdays":[1,2,3,4,5,6,7]}',
        'createdAt': 1000,
        'updatedAt': 1000,
      });

      // Insert past completed occurrence and future pending occurrence
      await db.insert('routine_occurrences', {
        'routine_id': routineId,
        'date': pastDate,
        'scheduled_time': '08:00',
        'status': 'done',
      });

      await db.insert('routine_occurrences', {
        'routine_id': routineId,
        'date': futureDate,
        'scheduled_time': '08:00',
        'status': 'pending',
      });

      // Edit routine using handler
      final handler = const EditRoutineHandler();
      await db.transaction((txn) async {
        final context = CommandContext(txn: txn, now: DateTime(2026, 7, 29));
        await handler.handle(
          context,
          EditRoutineCommand(
            routineId: routineId,
            routineData: {'title': 'جدید (ویرایش‌شده)'},
            scheduleData: {
              'scheduleType': 'EVERY_DAY',
              'timeOfDay': '09:00',
              'recurrenceRule': '{"weekdays":[1,2,3,4,5,6,7],"reminderTimes":["09:00"]}',
              'updatedAt': 2000,
            },
            applyToAll: true,
          ),
        );
      });

      // Verify past occurrence was NOT deleted or touched
      final pastRow = await db.query(
        'routine_occurrences',
        where: 'routine_id = ? AND date = ?',
        whereArgs: [routineId, pastDate],
      );

      expect(pastRow.length, equals(1));
      expect(pastRow.first['status'], equals('done'));
      expect(pastRow.first['scheduled_time'], equals('08:00'));

      await db.close();
    });
  });
}
