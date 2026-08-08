import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/simple_tasks/domain/task_attachment.dart';
import 'package:sqflite/sqflite.dart';

class TaskAttachmentRepository {
  TaskAttachmentRepository._();
  static final TaskAttachmentRepository instance = TaskAttachmentRepository._();

  static const int maxSizeBytes = 10 * 1024 * 1024; // 10 MB

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<String> get _docsDir async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> resolveAbsolutePath(String relativePath) async {
    final docs = await _docsDir;
    return p.join(docs, relativePath);
  }

  Future<List<TaskAttachment>> forTask(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'task_attachments',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => TaskAttachment.fromMap(r)).toList();
  }

  Future<TaskAttachment> add({
    required String taskId,
    required File sourceFile,
    required String fileName,
    String? mimeType,
  }) async {
    final size = await sourceFile.length();
    if (size > maxSizeBytes) {
      throw Exception('حجم فایل بیشتر از ۱۰ مگابایت است');
    }

    final id = TaskAttachment.generateId();
    final relativePath = p.join('task_attachments', taskId, '${id}_$fileName');
    final absolutePath = await resolveAbsolutePath(relativePath);

    final destFile = File(absolutePath);
    await destFile.parent.create(recursive: true);
    await sourceFile.copy(absolutePath);

    final attachment = TaskAttachment(
      id: id,
      taskId: taskId,
      fileName: fileName,
      fileSizeBytes: size,
      mimeType: mimeType,
      localPath: relativePath,
      createdAt: DateTime.now(),
    );

    final db = await _db;
    await db.insert('task_attachments', attachment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return attachment;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    final rows = await db.query('task_attachments', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final attachment = TaskAttachment.fromMap(rows.first);
      try {
        final absPath = await resolveAbsolutePath(attachment.localPath);
        final file = File(absPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      await db.delete('task_attachments', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteForTask(String taskId) async {
    final db = await _db;
    final attachments = await forTask(taskId);
    for (final att in attachments) {
      try {
        final absPath = await resolveAbsolutePath(att.localPath);
        final file = File(absPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    await db.delete('task_attachments', where: 'taskId = ?', whereArgs: [taskId]);
  }

  Future<Map<String, int>> countsFor(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};
    final db = await _db;
    final placeholders = List.filled(taskIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT taskId, COUNT(*) AS total
      FROM task_attachments WHERE taskId IN ($placeholders) GROUP BY taskId
    ''', taskIds);

    final result = <String, int>{};
    for (final r in rows) {
      final tid = r['taskId'] as String;
      final total = r['total'] as int? ?? 0;
      result[tid] = total;
    }
    return result;
  }
}
