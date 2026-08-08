import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:shamsi_date/shamsi_date.dart';

TaskBucket bucketOf(SimpleTask task, {required DateTime now}) {
  final todayDt = DateTime(now.year, now.month, now.day);
  final todayStr = _formatIso(todayDt);

  if (task.isDone) {
    return TaskBucket.doneToday;
  }

  if (task.dueDate == null) {
    return TaskBucket.someday;
  }

  final dueStr = task.dueDate!;
  if (dueStr.compareTo(todayStr) < 0) {
    return TaskBucket.overdue;
  }

  if (dueStr == todayStr) {
    return TaskBucket.today;
  }

  final tomorrowDt = todayDt.add(const Duration(days: 1));
  final tomorrowStr = _formatIso(tomorrowDt);
  if (dueStr == tomorrowStr) {
    return TaskBucket.tomorrow;
  }

  final jalaliNow = Jalali.fromDateTime(now);
  final daysUntilFriday = 7 - jalaliNow.weekDay;
  final fridayJalali = jalaliNow + daysUntilFriday;
  final fridayDt = fridayJalali.toDateTime();
  final fridayStr = _formatIso(fridayDt);

  if (dueStr.compareTo(tomorrowStr) > 0 && dueStr.compareTo(fridayStr) <= 0) {
    return TaskBucket.thisWeek;
  }

  return TaskBucket.later;
}

Map<TaskBucket, List<SimpleTask>> groupTasks(List<SimpleTask> tasks, {required DateTime now}) {
  final result = <TaskBucket, List<SimpleTask>>{};

  for (final task in tasks) {
    final b = bucketOf(task, now: now);
    result.putIfAbsent(b, () => []).add(task);
  }

  // Sort tasks within each bucket
  for (final bucketTasks in result.values) {
    bucketTasks.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      if (a.isImportant != b.isImportant) {
        return a.isImportant ? -1 : 1;
      }
      if (a.dueTime != b.dueTime) {
        if (a.dueTime == null) return 1;
        if (b.dueTime == null) return -1;
        return a.dueTime!.compareTo(b.dueTime!);
      }
      return a.orderIndex.compareTo(b.orderIndex);
    });
  }

  return result;
}

String _formatIso(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
