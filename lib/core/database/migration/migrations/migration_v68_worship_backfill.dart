import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV68 extends Migration {
  @override
  int get version => 68;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    try {
      final practices = await db.query(
        'worship_practices',
        where: 'dailyDone > 0 AND dailyDoneDate IS NOT NULL AND dailyDoneDate != ""',
      );

      for (final p in practices) {
        final practiceId = p['id']! as String;
        final dateStr = p['dailyDoneDate']! as String;
        final countDone = p['dailyDone']! as int;
        final countTarget = (p['dailyTarget'] as int? ?? 1);

        final existing = await db.query(
          'worship_completions',
          where: 'practiceId = ? AND date = ?',
          whereArgs: [practiceId, dateStr],
          limit: 1,
        );

        if (existing.isEmpty) {
          final resultType = countDone >= countTarget ? 'DONE' : 'PARTIAL';
          await db.insert('worship_completions', {
            'id': 'comp_${practiceId}_${dateStr}_backfill',
            'practiceId': practiceId,
            'date': dateStr,
            'countDone': countDone,
            'countTarget': countTarget,
            'resultType': resultType,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}
