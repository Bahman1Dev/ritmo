import 'package:sqflite/sqflite.dart';

abstract class Migration {
  int get version;
  Future<void> up(Database db);
  Future<void> down(Database db);

  Future<void> safeAddColumn(Database db, String table, String column, String typeDefinition) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final columnExists = columns.any((c) => c['name']?.toString().toLowerCase() == column.toLowerCase());
    if (!columnExists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $typeDefinition;');
    }
  }
}
