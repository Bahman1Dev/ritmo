import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/completion/undo_token.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 4 UndoToken & True Reschedule Undo Tests (K-25)', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            progressionCurrent INTEGER DEFAULT 0,
            progressionDoneSinceAdvance INTEGER DEFAULT 0,
            updatedAt INTEGER DEFAULT 0
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
            reason TEXT,
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
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('UndoToken serialization and parsing', () {
      final token = const RoutineCompletionUndoToken(
        routineId: 'r1',
        dateStr: '2026-08-03',
        completionId: 'comp1',
        previousProgressionCurrent: 2,
        previousProgressionDoneSinceAdvance: 1,
      );

      final raw = token.serialize();
      expect(raw, equals('routine:r1|2026-08-03|comp1|2|1'));

      final parsed = UndoToken.parse(raw);
      expect(parsed, isA<RoutineCompletionUndoToken>());
      final rParsed = parsed as RoutineCompletionUndoToken;
      expect(rParsed.routineId, equals('r1'));
      expect(rParsed.previousProgressionCurrent, equals(2));
      expect(rParsed.previousProgressionDoneSinceAdvance, equals(1));
    });

    test('True Reschedule Undo reverts status and removes target occurrence', () async {
      await db.insert('routines', {'id': 'r_resc', 'title': 'Reschedule Test'});
      await db.insert('routine_occurrences', {'routine_id': 'r_resc', 'date': '2026-08-03', 'status': 'pending'});

      final outcome = await CompletionGateway.instance.submit(
        const RoutineReschedule(
          routineId: 'r_resc',
          fromDateStr: '2026-08-03',
          toDateStr: '2026-08-04',
          reason: 'Busy today',
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.undoToken, contains('reschedule:r_resc|2026-08-03|2026-08-04'));

      final fromOcc = await db.query('routine_occurrences', where: 'routine_id = ? AND date = ?', whereArgs: ['r_resc', '2026-08-03']);
      expect(fromOcc.first['status'], equals('rescheduled'));

      final toOcc = await db.query('routine_occurrences', where: 'routine_id = ? AND date = ?', whereArgs: ['r_resc', '2026-08-04']);
      expect(toOcc.first['status'], equals('pending'));

      // Perform UNDO
      final undoOutcome = await CompletionGateway.instance.undo(outcome.undoToken!);
      expect(undoOutcome.isSuccess, isTrue);

      final revertedFromOcc = await db.query('routine_occurrences', where: 'routine_id = ? AND date = ?', whereArgs: ['r_resc', '2026-08-03']);
      expect(revertedFromOcc.first['status'], equals('pending'));

      final deletedToOcc = await db.query('routine_occurrences', where: 'routine_id = ? AND date = ?', whereArgs: ['r_resc', '2026-08-04']);
      expect(deletedToOcc.isEmpty, isTrue);
    });
  });
}
