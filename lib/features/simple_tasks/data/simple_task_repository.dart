import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:sqflite/sqflite.dart';

class SimpleTaskRepository {
  SimpleTaskRepository._();
  static final SimpleTaskRepository instance = SimpleTaskRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Returns active tasks due today OR overdue past tasks (isDone = 0 AND dueDate <= todayIso)
  Future<List<SimpleTask>> today(String todayIso) async {
    final db = await _db;
    final rows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate <= ?',
      whereArgs: [todayIso],
      orderBy: 'orderIndex ASC, createdAt ASC',
    );
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }

  /// Returns upcoming tasks (isDone = 0 AND dueDate > todayIso)
  Future<List<SimpleTask>> upcoming(String todayIso) async {
    final db = await _db;
    final rows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate > ?',
      whereArgs: [todayIso],
      orderBy: 'dueDate ASC, orderIndex ASC',
    );
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }

  /// Returns someday tasks with no dueDate (isDone = 0 AND dueDate IS NULL)
  Future<List<SimpleTask>> someday() async {
    final db = await _db;
    final rows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NULL',
      orderBy: 'orderIndex ASC, createdAt ASC',
    );
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }

  /// Returns tasks completed today
  Future<List<SimpleTask>> doneToday(String todayIso) async {
    final db = await _db;
    final startOfDayMs = DateTime.parse(todayIso).millisecondsSinceEpoch;
    final endOfDayMs = DateTime.parse(todayIso).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final rows = await db.query(
      'simple_tasks',
      where: 'isDone = 1 AND (dueDate = ? OR (doneAt >= ? AND doneAt < ?))',
      whereArgs: [todayIso, startOfDayMs, endOfDayMs],
      orderBy: 'doneAt DESC, updatedAt DESC',
    );
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }

  /// Creates a new SimpleTask
  Future<SimpleTask> create({
    required String title,
    String? dueDate,
    String? dueTime,
    String? note,
    int? reminderAtMs,
    String? reminderId,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    final maxOrderRows = await db.rawQuery('SELECT MAX(orderIndex) as maxOrder FROM simple_tasks');
    final maxOrder = (maxOrderRows.first['maxOrder'] as int?) ?? 0;

    final task = SimpleTask(
      id: SimpleTask.generateId(),
      title: title.trim(),
      note: note?.trim(),
      isDone: false,
      dueDate: dueDate,
      dueTime: dueTime,
      reminderAtMs: reminderAtMs,
      reminderId: reminderId,
      orderIndex: maxOrder + 1,
      origin: 'SIMPLE',
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('simple_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return task;
  }

  /// Toggle task completion status + cancel alarm if completed
  Future<void> setDone(String id, {required bool done}) async {
    final db = await _db;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final rows = await db.query('simple_tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;

    final task = SimpleTask.fromMap(rows.first);

    if (done && task.reminderId != null && task.reminderId!.isNotEmpty) {
      try {
        await sl<AlarmPlatform>().cancelAlarm(task.reminderId!);
      } catch (_) {}
    }

    await db.update(
      'simple_tasks',
      {
        'isDone': done ? 1 : 0,
        'doneAt': done ? nowMs : null,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update full task data
  Future<void> updateTask(SimpleTask task) async {
    final db = await _db;
    final updated = task.copyWith(updatedAt: DateTime.now());
    await db.update(
      'simple_tasks',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Save a pending reminder for a task
  Future<void> addPendingReminder({
    required String reminderId,
    required String title,
    required String body,
    required int scheduledTimeMs,
    required String taskId,
  }) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'pending_reminders',
      {
        'id': reminderId,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTimeMs,
        'payloadJson': '{"taskId":"$taskId"}',
        'createdAt': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Restore a deleted task (for undo)
  Future<void> restoreTask(SimpleTask task) async {
    final db = await _db;
    await db.insert('simple_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Delete task + cancel alarm if present
  Future<void> delete(String id) async {
    final db = await _db;
    final rows = await db.query('simple_tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final task = SimpleTask.fromMap(rows.first);
      if (task.reminderId != null && task.reminderId!.isNotEmpty) {
        try {
          await sl<AlarmPlatform>().cancelAlarm(task.reminderId!);
        } catch (_) {}
      }
    }
    await db.delete('simple_tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Reorder tasks by ordered list of IDs
  Future<void> reorder(List<String> orderedIds) async {
    final db = await _db;
    final batch = db.batch();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'simple_tasks',
        {'orderIndex': i, 'updatedAt': nowMs},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Mark task as promoted to routine
  Future<void> promoteToRoutine(String id, String routineId) async {
    final db = await _db;
    await db.update(
      'simple_tasks',
      {
        'linkedRoutineId': routineId,
        'origin': 'PROMOTED',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search tasks by title or note
  Future<List<SimpleTask>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _db;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      'simple_tasks',
      where: 'title LIKE ? OR note LIKE ?',
      whereArgs: [q, q],
      orderBy: 'isDone ASC, updatedAt DESC',
      limit: 20,
    );
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }
}
