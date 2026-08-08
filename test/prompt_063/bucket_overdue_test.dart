import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';

void main() {
  test('Past due dates map to overdue bucket', () {
    final now = DateTime(2026, 8, 8); // Saturday
    final task = SimpleTask(
      id: 't1',
      title: 'Past Task',
      dueDate: '2026-08-07',
      createdAt: now,
      updatedAt: now,
    );

    final bucket = bucketOf(task, now: now);
    expect(bucket, equals(TaskBucket.overdue));
  });
}
