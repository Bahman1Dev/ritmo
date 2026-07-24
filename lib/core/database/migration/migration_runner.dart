import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/database/migration/migrations_registry.dart';
import 'package:sqflite/sqflite.dart';

class MigrationRunner {
  static final List<Migration> _migrations = [
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
    MigrationV8(),
    MigrationV9(),
    MigrationV10(),
    MigrationV11(),
    MigrationV12(),
    MigrationV13(),
    MigrationV14(),
    MigrationV15(),
    MigrationV16(),
    MigrationV17(),
    MigrationV18(),
    MigrationV19(),
    MigrationV20(),
    MigrationV21(),
    MigrationV22(),
    MigrationV23(),
    MigrationV24(),
    MigrationV25(),
    MigrationV26(),
    MigrationV27(),
    MigrationV28(),
    MigrationV29(),
    MigrationV30(),
    MigrationV31(),
    MigrationV32(),
    MigrationV33(),
    MigrationV34(),
    MigrationV35(),
    MigrationV36(),
    MigrationV37(),
    MigrationV38(),
    MigrationV39(),
    MigrationV40(),
    MigrationV41(),
    MigrationV42(),
    MigrationV43(),
    MigrationV44(),
    MigrationV45(),
    MigrationV46(),
    MigrationV47(),
    MigrationV48(),
    MigrationV49(),
    MigrationV50(),
    MigrationV51(),
    MigrationV52(),
    MigrationV53(),
  ];

  static Future<void> run(Database db, int oldVersion, int newVersion) async {
    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await migration.up(db);
      }
    }
  }
}
