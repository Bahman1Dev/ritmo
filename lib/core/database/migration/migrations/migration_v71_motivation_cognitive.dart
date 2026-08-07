import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV71MotivationCognitive extends Migration {
  @override
  int get version => 71;

  @override
  Future<void> up(Database db) async {
    // 1. Routine table extensions for cognitive load, first physical step & temptation bundling
    await safeAddColumn(db, 'routines', 'cognitiveLoad', 'TEXT');
    await safeAddColumn(db, 'routines', 'firstPhysicalStep', 'TEXT');
    await safeAddColumn(db, 'routines', 'temptationBundle', 'TEXT');

    // 2. Goals table extension for identity-based habits
    await safeAddColumn(db, 'goals', 'identityStatement', 'TEXT');

    // 3. Routine completions table extensions for skip reason logging and behavioral activation ratings
    await safeAddColumn(db, 'routine_completions', 'skipReason', 'TEXT');
    await safeAddColumn(db, 'routine_completions', 'masteryRating', 'INTEGER');
    await safeAddColumn(db, 'routine_completions', 'pleasureRating', 'INTEGER');
  }

  @override
  Future<void> down(Database db) async {}
}
