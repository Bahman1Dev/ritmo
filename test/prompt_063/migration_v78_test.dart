import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v79_task_upgrade.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseForMigration implements Database {
  final Map<String, List<Map<String, Object?>>> tables = {};
  final List<String> executedSql = [];

  @override
  bool get isOpen => true;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
    final trimmed = sql.trim();
    if (trimmed.contains('CREATE TABLE IF NOT EXISTS ')) {
      final tableName = trimmed.split('CREATE TABLE IF NOT EXISTS ')[1].trim().split(' ')[0].trim();
      tables.putIfAbsent(tableName, () => []);
    }
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables.putIfAbsent(table, () => []);
    final keyField = values.containsKey('key') ? 'key' : 'id';
    if (conflictAlgorithm == ConflictAlgorithm.ignore) {
      if (list.any((r) => r[keyField] == values[keyField])) {
        return 0;
      }
    }
    list.removeWhere((r) => r[keyField] == values[keyField]);
    list.add(Map<String, Object?>.from(values));
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return tables[table] ?? [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('PRAGMA table_info(simple_tasks)')) {
      return [
        {'name': 'id'},
        {'name': 'title'},
        {'name': 'isImportant'},
        {'name': 'importantAt'},
      ];
    }
    if (sql.contains('SELECT COUNT(*) FROM simple_tasks')) {
      return [{'COUNT(*)': tables['simple_tasks']?.length ?? 0}];
    }
    if (sql.contains('SELECT COUNT(*) FROM routines')) {
      return [{'COUNT(*)': tables['routines']?.length ?? 0}];
    }
    if (sql.contains('SELECT COUNT(*) FROM goals')) {
      return [{'COUNT(*)': tables['goals']?.length ?? 0}];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('MigrationV79TaskUpgrade upgrades schema cleanly and preserves data', () async {
    final db = MockDatabaseForMigration();

    // Seed data
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (int i = 1; i <= 5; i++) {
      await db.insert('simple_tasks', {'id': 'task_$i', 'title': 'Task $i'});
    }
    for (int i = 1; i <= 3; i++) {
      await db.insert('routines', {'id': 'routine_$i', 'title': 'Routine $i'});
    }
    for (int i = 1; i <= 2; i++) {
      await db.insert('goals', {'id': 'goal_$i', 'title': 'Goal $i'});
    }
    await db.insert('app_settings', {
      'key': 'tasks_confirm_delete',
      'value': 'false',
      'updatedAt': nowMs,
    });

    // Run migration
    final migration = MigrationV79TaskUpgrade();
    await migration.up(db);

    // 1. Verify simple_tasks columns ALTER executed
    expect(db.executedSql.any((s) => s.contains('isImportant')), isTrue);
    expect(db.executedSql.any((s) => s.contains('importantAt')), isTrue);

    // 2. Verify task_steps table created
    expect(db.tables.containsKey('task_steps'), isTrue);

    // 3. Verify task_attachments table created
    expect(db.tables.containsKey('task_attachments'), isTrue);

    // 4. Verify default app_settings
    final settingsRows = await db.query('app_settings');
    final settingsMap = {for (var r in settingsRows) r['key'] as String: r['value'] as String};
    expect(settingsMap['tasks_completion_sound_enabled'], equals('false'));
    expect(settingsMap['daily_planning_nudge_enabled'], equals('false'));
    expect(settingsMap['daily_planning_nudge_time'], equals('08:30'));
    // Verify ignore algorithm: pre-existing 'false' value was not overwritten
    expect(settingsMap['tasks_confirm_delete'], equals('false'));

    // 5. Verify row counts preserved
    final tasksCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM simple_tasks'));
    final routinesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM routines'));
    final goalsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM goals'));
    expect(tasksCount, equals(5));
    expect(routinesCount, equals(3));
    expect(goalsCount, equals(2));
  });
}
