import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/utils/persian_text.dart';
import 'package:ritmo/features/simple_tasks/data/task_attachment_repository.dart';
import 'package:ritmo/features/simple_tasks/data/task_step_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';
import 'package:sqflite/sqflite.dart';

class SimpleTaskRepository {
  SimpleTaskRepository._();
  static final SimpleTaskRepository instance = SimpleTaskRepository._();

  Future<Database> get _db async {
    final db = await DatabaseHelper.instance.database;
    await _ensureTable(db);
    return db;
  }

  Future<void> _ensureTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS simple_tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            note TEXT,
            isDone INTEGER NOT NULL DEFAULT 0,
            doneAt INTEGER,
            dueDate TEXT,
            dueTime TEXT,
            reminderAtMs INTEGER,
            reminderId TEXT,
            linkedRoutineId TEXT,
            orderIndex INTEGER NOT NULL DEFAULT 0,
            origin TEXT NOT NULL DEFAULT 'SIMPLE',
            isImportant INTEGER NOT NULL DEFAULT 0,
            importantAt INTEGER,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
        );
      ''');
    } catch (_) {}
  }

  /// Returns active tasks due today OR overdue past tasks (isDone = 0 AND dueDate <= todayIso)
  Future<List<SimpleTask>> today(String todayIso) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'simple_tasks',
        where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate <= ?',
        whereArgs: [todayIso],
        orderBy: 'orderIndex ASC, createdAt ASC',
      );
      return rows.map((m) => SimpleTask.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns upcoming tasks (isDone = 0 AND dueDate > todayIso)
  Future<List<SimpleTask>> upcoming(String todayIso) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'simple_tasks',
        where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate > ?',
        whereArgs: [todayIso],
        orderBy: 'dueDate ASC, orderIndex ASC',
      );
      return rows.map((m) => SimpleTask.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns someday tasks with no dueDate (isDone = 0 AND dueDate IS NULL)
  Future<List<SimpleTask>> someday() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'simple_tasks',
        where: 'isDone = 0 AND dueDate IS NULL',
        orderBy: 'orderIndex ASC, createdAt ASC',
      );
      return rows.map((m) => SimpleTask.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns tasks completed today
  Future<List<SimpleTask>> doneToday(String todayIso) async {
    try {
      final db = await _db;
      final dt = DateTime.tryParse(todayIso) ?? DateTime.now();
      final startOfDayMs = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
      final endOfDayMs = DateTime(dt.year, dt.month, dt.day + 1).millisecondsSinceEpoch;

      final rows = await db.query(
        'simple_tasks',
        where: 'isDone = 1 AND (dueDate = ? OR (doneAt >= ? AND doneAt < ?))',
        whereArgs: [todayIso, startOfDayMs, endOfDayMs],
        orderBy: 'doneAt DESC, updatedAt DESC',
      );
      return rows.map((m) => SimpleTask.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns all active and done tasks grouped into TaskBucket sections
  Future<Map<TaskBucket, List<SimpleTask>>> buckets(String todayIso) async {
    try {
      final db = await _db;
      final dt = DateTime.tryParse(todayIso) ?? DateTime.now();
      final startOfDayMs = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
      final endOfDayMs = DateTime(dt.year, dt.month, dt.day + 1).millisecondsSinceEpoch;

      final rows = await db.query(
        'simple_tasks',
        where: 'isDone = 0 OR (dueDate = ? OR (doneAt >= ? AND doneAt < ?))',
        whereArgs: [todayIso, startOfDayMs, endOfDayMs],
      );

      final tasks = rows.map((m) => SimpleTask.fromMap(m)).toList();
      return groupTasks(tasks, now: dt);
    } catch (_) {
      return {};
    }
  }

  /// Creates a new SimpleTask
  Future<SimpleTask> create({
    required String title,
    String? dueDate,
    String? dueTime,
    String? note,
    int? reminderAtMs,
    String? reminderId,
    bool isImportant = false,
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
      isImportant: isImportant,
      importantAt: isImportant ? now : null,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('simple_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return task;
  }

  /// Toggle task importance star
  Future<void> setImportant(String id, {required bool important}) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'simple_tasks',
      {
        'isImportant': important ? 1 : 0,
        'importantAt': important ? nowMs : null,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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

  /// Delete task + steps + attachments + cancel alarm
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

    await TaskStepRepository.instance.deleteForTask(id);
    await TaskAttachmentRepository.instance.deleteForTask(id);
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

  /// Search tasks by title, note, or sub-step title
  Future<List<SimpleTask>> search(String query) async {
    final normalized = normalizeFa(query);
    if (normalized.isEmpty) return [];
    final db = await _db;
    final q = '%$normalized%';
    final rows = await db.rawQuery('''
      SELECT DISTINCT t.* FROM simple_tasks t
      LEFT JOIN task_steps s ON s.taskId = t.id
      WHERE t.title LIKE ? OR t.note LIKE ? OR s.title LIKE ?
      ORDER BY t.isDone ASC, t.isImportant DESC, t.updatedAt DESC
      LIMIT 20
    ''', [q, q, q]);
    return rows.map((m) => SimpleTask.fromMap(m)).toList();
  }
}
