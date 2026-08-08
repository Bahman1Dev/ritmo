import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';

void main() {
  test('Completed tasks sort to the bottom of their bucket without any setting toggle', () {
    final now = DateTime(2026, 8, 8);
    final completedTask = SimpleTask(
      id: 't1',
      title: 'Completed Task',
      dueDate: '2026-08-08',
      isDone: true,
      orderIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final activeTask = SimpleTask(
      id: 't2',
      title: 'Active Task',
      dueDate: '2026-08-08',
      isDone: false,
      orderIndex: 1,
      createdAt: now,
      updatedAt: now,
    );

    final tasks = [completedTask, activeTask];
    tasks.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.orderIndex.compareTo(b.orderIndex);
    });

    expect(tasks.first.id, equals('t2'));
    expect(tasks.last.id, equals('t1'));
  });
}
