import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';

void main() {
  test('Today and tomorrow boundaries map correctly', () {
    final now = DateTime(2026, 8, 8); // 2026-08-08
    final todayTask = SimpleTask(
      id: 't1',
      title: 'Today Task',
      dueDate: '2026-08-08',
      createdAt: now,
      updatedAt: now,
    );
    final tomorrowTask = SimpleTask(
      id: 't2',
      title: 'Tomorrow Task',
      dueDate: '2026-08-09',
      createdAt: now,
      updatedAt: now,
    );

    expect(bucketOf(todayTask, now: now), equals(TaskBucket.today));
    expect(bucketOf(tomorrowTask, now: now), equals(TaskBucket.tomorrow));
  });
}
