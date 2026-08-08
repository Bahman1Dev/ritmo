import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/simple_tasks/domain/task_step.dart';
import 'package:sqflite/sqflite.dart';

class TaskStepRepository {
  TaskStepRepository._();
  static final TaskStepRepository instance = TaskStepRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<TaskStep>> forTask(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'task_steps',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'displayOrder ASC, createdAt ASC',
    );
    return rows.map((r) => TaskStep.fromMap(r)).toList();
  }

  Future<TaskStep> add({required String taskId, required String title}) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task step title cannot be empty');
    }
    final db = await _db;
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(displayOrder) as maxOrder FROM task_steps WHERE taskId = ?',
      [taskId],
    );
    final currentMax = (maxOrderResult.first['maxOrder'] as int?) ?? -1;
    final nextOrder = currentMax + 1;

    final now = DateTime.now();
    final step = TaskStep(
      id: TaskStep.generateId(),
      taskId: taskId,
      title: trimmedTitle,
      isCompleted: false,
      displayOrder: nextOrder,
      createdAt: now,
    );

    await db.insert('task_steps', step.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return step;
  }

  Future<void> setCompleted(String id, {required bool completed}) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'task_steps',
      {
        'isCompleted': completed ? 1 : 0,
        'completedAt': completed ? nowMs : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> rename(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final db = await _db;
    await db.update(
      'task_steps',
      {'title': trimmed},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('task_steps', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(String taskId, List<String> orderedIds) async {
    final db = await _db;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'task_steps',
        {'displayOrder': i},
        where: 'id = ? AND taskId = ?',
        whereArgs: [orderedIds[i], taskId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteForTask(String taskId) async {
    final db = await _db;
    await db.delete('task_steps', where: 'taskId = ?', whereArgs: [taskId]);
  }

  Future<Map<String, (int done, int total)>> countsFor(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};
    final db = await _db;
    final placeholders = List.filled(taskIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT taskId, COUNT(*) AS total, SUM(isCompleted) AS done
      FROM task_steps WHERE taskId IN ($placeholders) GROUP BY taskId
    ''', taskIds);

    final result = <String, (int, int)>{};
    for (final r in rows) {
      final tid = r['taskId'] as String;
      final total = r['total'] as int? ?? 0;
      final done = r['done'] as int? ?? 0;
      result[tid] = (done, total);
    }
    return result;
  }
}
