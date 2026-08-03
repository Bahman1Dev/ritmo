import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/handlers/archive_routine_handler.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 6 Archive Routine Kernel Command Tests (K-33)', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            isArchived INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL DEFAULT 0
          );
        ''');
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('ArchiveRoutineHandler and UnarchiveRoutineHandler update isArchived via Kernel', () async {
      await db.insert('routines', {'id': 'r_arch', 'title': 'Routine to Archive', 'isArchived': 0});

      // Archive via Handler
      await db.transaction((txn) async {
        final context = CommandContext(txn: txn, now: DateTime.now());
        const handler = ArchiveRoutineHandler();
        await handler.handle(context, const ArchiveRoutineCommand(routineId: 'r_arch'));
      });

      final archivedRows = await db.query('routines', where: 'id = ?', whereArgs: ['r_arch']);
      expect(archivedRows.first['isArchived'], equals(1));

      // Unarchive via Handler
      await db.transaction((txn) async {
        final context = CommandContext(txn: txn, now: DateTime.now());
        const handler = UnarchiveRoutineHandler();
        await handler.handle(context, const UnarchiveRoutineCommand(routineId: 'r_arch'));
      });

      final unarchivedRows = await db.query('routines', where: 'id = ?', whereArgs: ['r_arch']);
      expect(unarchivedRows.first['isArchived'], equals(0));
    });
  });
}
