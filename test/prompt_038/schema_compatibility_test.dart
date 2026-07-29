import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/migration/migration_runner.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v1 migration chain runs cleanly to v59', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
      // Basic v1 schema
      await db.execute('CREATE TABLE routines (id TEXT PRIMARY KEY, title TEXT);');
    });

    // Run migration chain from 1 to 59
    await MigrationRunner.run(db, 1, 59);

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    expect(tables, isNotEmpty);

    await db.close();
  });
}
