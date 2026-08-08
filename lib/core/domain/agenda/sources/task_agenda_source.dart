import 'package:flutter/foundation.dart' hide Category;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

class TaskAgendaSource {
  TaskAgendaSource({
    required this.tasksByDate,
    required this.overdueTasks,
    required this.stepCounts,
  });

  /// dateStr -> rows of simple_tasks
  final Map<String, List<Map<String, dynamic>>> tasksByDate;

  /// کارهای انجام‌نشده با dueDate قبل از امروز
  final List<Map<String, dynamic>> overdueTasks;

  /// taskId -> (done, total)
  final Map<String, ({int done, int total})> stepCounts;

  static Future<TaskAgendaSource> load(
    Database db,
    DateTime start,
    DateTime end,
    String todayStr,
  ) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      // 1) All tasks scheduled within range (dueDate >= startStr AND dueDate <= endStr)
      final rangeRows = await db.query(
        'simple_tasks',
        where: 'dueDate >= ? AND dueDate <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'dueTime ASC, isImportant DESC, updatedAt DESC',
      );

      final tasksByDate = <String, List<Map<String, dynamic>>>{};
      final taskIds = <String>{};
      for (final r in rangeRows) {
        final dStr = r['dueDate'] as String?;
        if (dStr != null) {
          tasksByDate.putIfAbsent(dStr, () => []).add(r);
          taskIds.add(r['id'].toString());
        }
      }

      // 2) Overdue tasks: isDone = 0 AND dueDate IS NOT NULL AND dueDate < todayStr
      final overdueRows = await db.query(
        'simple_tasks',
        where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate < ?',
        whereArgs: [todayStr],
        orderBy: 'dueDate DESC, isImportant DESC',
        limit: 20, // Cap at 20 overdue tasks
      );
      for (final r in overdueRows) {
        taskIds.add(r['id'].toString());
      }

      // 3) Step counts for all loaded tasks
      final stepCounts = <String, ({int done, int total})>{};
      if (taskIds.isNotEmpty) {
        final placeholders = List.filled(taskIds.length, '?').join(',');
        final stepRows = await db.rawQuery('''
          SELECT taskId, 
                 SUM(CASE WHEN isDone = 1 THEN 1 ELSE 0 END) as doneCount,
                 COUNT(*) as totalCount
          FROM task_steps
          WHERE taskId IN ($placeholders)
          GROUP BY taskId
        ''', taskIds.toList());

        for (final sr in stepRows) {
          final tId = sr['taskId'].toString();
          final doneC = (sr['doneCount'] as num?)?.toInt() ?? 0;
          final totalC = (sr['totalCount'] as num?)?.toInt() ?? 0;
          stepCounts[tId] = (done: doneC, total: totalC);
        }
      }

      return TaskAgendaSource(
        tasksByDate: tasksByDate,
        overdueTasks: overdueRows,
        stepCounts: stepCounts,
      );
    } catch (e) {
      debugPrint('[TaskAgendaSource] Load error: $e');
      return TaskAgendaSource(tasksByDate: const {}, overdueTasks: const [], stepCounts: const {});
    }
  }

  List<AgendaItem> itemsForDate(String dateStr, {required bool isToday}) {
    final result = <AgendaItem>[];

    // 1) Regular tasks for this date
    final dayRows = tasksByDate[dateStr] ?? const [];
    for (final row in dayRows) {
      final taskId = row['id'].toString();
      final title = row['title'] as String? ?? '';
      final note = row['note'] as String?;
      final dueTime = row['dueTime'] as String?;
      final isDone = (row['isDone'] as int? ?? 0) == 1;
      final isImportant = (row['isImportant'] as int? ?? 0) == 1;
      final steps = stepCounts[taskId];

      String? subtitle;
      if (steps != null && steps.total > 0) {
        subtitle = '${toPersianDigits(steps.done)} از ${toPersianDigits(steps.total)}';
      } else if (note != null && note.trim().isNotEmpty) {
        final trimmed = note.trim();
        subtitle = trimmed.length > 50 ? '${trimmed.substring(0, 50)}…' : trimmed;
      }

      result.add(AgendaItem(
        id: 'task:$taskId:$dateStr',
        domain: AgendaDomain.task,
        sourceId: taskId,
        title: title,
        subtitle: subtitle,
        dateStr: dateStr,
        timeOfDay: dueTime,
        durationMinutes: null,
        category: Category.personal,
        completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
        priority: isImportant ? 2.0 : 1.0,
        isEssential: false,
        deepLink: AgendaDeepLink(domain: AgendaDomain.task, targetId: taskId),
        meta: {
          'taskRow': row,
          'stepsDone': steps?.done ?? 0,
          'stepsTotal': steps?.total ?? 0,
          'isImportant': isImportant,
        },
      ));
    }

    // 2) Overdue tasks (Only if isToday is true)
    if (isToday && overdueTasks.isNotEmpty) {
      for (final row in overdueTasks) {
        final taskId = row['id'].toString();
        final title = row['title'] as String? ?? '';
        final origDateStr = row['dueDate'] as String? ?? '';
        final isImportant = (row['isImportant'] as int? ?? 0) == 1;

        String jalaliSubtitle = 'معوقه از $origDateStr';
        try {
          final parts = origDateStr.split('-');
          if (parts.length == 3) {
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            final j = Jalali.fromDateTime(dt);
            jalaliSubtitle = 'معوقه از ${toPersianDigits(j.day)} ${j.formatter.mN}';
          }
        } catch (_) {}

        result.add(AgendaItem(
          id: 'task:$taskId:overdue:$dateStr',
          domain: AgendaDomain.task,
          sourceId: taskId,
          title: title,
          subtitle: jalaliSubtitle,
          dateStr: dateStr,
          timeOfDay: null,
          durationMinutes: null,
          category: Category.personal,
          completion: AgendaCompletion.overdue,
          priority: 3.0,
          isEssential: false,
          deepLink: AgendaDeepLink(domain: AgendaDomain.task, targetId: taskId),
          meta: {
            'taskRow': row,
            'isOverdue': true,
            'originalDueDate': origDateStr,
            'isImportant': isImportant,
          },
        ));
      }
    }

    return result;
  }
}
