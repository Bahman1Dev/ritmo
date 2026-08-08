import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';

void main() {
  test('Starred/important tasks sort to the top of their bucket', () {
    final now = DateTime(2026, 8, 8);
    final normalTask = SimpleTask(
      id: 't1',
      title: 'Normal Task',
      dueDate: '2026-08-08',
      isImportant: false,
      orderIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final starredTask = SimpleTask(
      id: 't2',
      title: 'Starred Task',
      dueDate: '2026-08-08',
      isImportant: true,
      orderIndex: 1,
      createdAt: now,
      updatedAt: now,
    );

    final groups = groupTasks([normalTask, starredTask], now: now);
    final todayTasks = groups[TaskBucket.today]!;
    expect(todayTasks.first.id, equals('t2'));
    expect(todayTasks.last.id, equals('t1'));
  });
}
