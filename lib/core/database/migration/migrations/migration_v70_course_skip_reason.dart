import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV70CourseSkipReason extends Migration {
  @override
  int get version => 70;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'course_sessions', 'skipReason', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {}
}
