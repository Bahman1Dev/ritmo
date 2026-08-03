import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/handlers/complete_occurrence_handler.dart';
import 'package:ritmo/core/domain/execution/handlers/skip_occurrence_handler.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 2 Write Stabilization & Idempotency Tests (K-16)', () {
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
            isEssential INTEGER NOT NULL DEFAULT 0,
            displayOrder INTEGER NOT NULL DEFAULT 1,
            createdAt INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE routine_completions (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            completionDate TEXT NOT NULL,
            completionTime INTEGER NOT NULL,
            resultType TEXT NOT NULL,
            resultSource TEXT NOT NULL DEFAULT 'USER',
            debtId TEXT,
            durationMinutes INTEGER,
            actual_duration_minutes INTEGER,
            note TEXT,
            partialRatio REAL,
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
            scheduledTime INTEGER NOT NULL,
            state TEXT NOT NULL DEFAULT 'unknown',
            deferCount INTEGER NOT NULL DEFAULT 0,
            snoozeUntil INTEGER,
            updatedAt INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE skip_reasons (
            id TEXT PRIMARY KEY,
            itemId TEXT NOT NULL,
            domain TEXT NOT NULL,
            dateStr TEXT NOT NULL,
            reason TEXT NOT NULL,
            note TEXT,
            createdAt INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_uniq_routine_completions_routine_date_result
          ON routine_completions(routineId, completionDate, resultType);
        ''');
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('CompleteOccurrenceHandler upserts occurrence when row does not exist', () async {
      await db.insert('routines', {'id': 'r1', 'title': 'Routine 1'});

      await db.transaction((txn) async {
        final context = CommandContext(txn: txn, now: DateTime.now());
        const handler = CompleteOccurrenceHandler();
        await handler.handle(
          context,
          const CompleteOccurrenceCommand(
            routineId: 'r1',
            dateStr: '2026-08-03',
            resultType: 'FULL',
            durationMinutes: 30,
          ),
        );
      });

      final completions = await db.query('routine_completions', where: 'routineId = ?', whereArgs: ['r1']);
      expect(completions.length, equals(1));
      expect(completions.first['resultType'], equals('FULL'));

      final occurrences = await db.query('routine_occurrences', where: 'routine_id = ?', whereArgs: ['r1']);
      expect(occurrences.length, equals(1));
      expect(occurrences.first['status'], equals('done'));
    });

    test('SkipOccurrenceHandler upserts occurrence idempotently', () async {
      await db.insert('routines', {'id': 'r2', 'title': 'Routine 2'});

      await db.transaction((txn) async {
        final context = CommandContext(txn: txn, now: DateTime.now());
        const handler = SkipOccurrenceHandler();
        await handler.handle(
          context,
          const SkipOccurrenceCommand(
            routineId: 'r2',
            dateStr: '2026-08-03',
            reason: 'Feeling tired',
          ),
        );
      });

      final completions = await db.query('routine_completions', where: 'routineId = ?', whereArgs: ['r2']);
      expect(completions.length, equals(1));
      expect(completions.first['resultType'], equals('SKIPPED'));

      final occurrences = await db.query('routine_occurrences', where: 'routine_id = ?', whereArgs: ['r2']);
      expect(occurrences.length, equals(1));
      expect(occurrences.first['status'], equals('skipped'));
    });
  });
}
