import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV72Cleanup extends Migration {
  @override
  int get version => 72;

  @override
  Future<void> up(Database db) async {
    // 1. Drop unused zone / realm tables
    await db.execute('DROP TABLE IF EXISTS zones;');
    await db.execute('DROP TABLE IF EXISTS zone_schedules;');

    // 2. Drop unused worship seasons table
    await db.execute('DROP TABLE IF EXISTS worship_seasons;');
  }

  @override
  Future<void> down(Database db) async {}
}
