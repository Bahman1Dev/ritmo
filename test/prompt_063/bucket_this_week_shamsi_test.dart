import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';

void main() {
  test('Shamsi week bucketing starts on Saturday and ends on Friday', () {
    // Shanbe (Saturday) 2026-08-08
    final sat = DateTime(2026, 8, 8);
    final mondayTask = SimpleTask(
      id: 't1',
      title: 'Monday Task',
      dueDate: '2026-08-10', // Monday (Doshambe)
      createdAt: sat,
      updatedAt: sat,
    );

    expect(bucketOf(mondayTask, now: sat), equals(TaskBucket.thisWeek));
  });

  test('On Thursday and Friday, thisWeek bucket remains empty', () {
    // Panjshambe (Thursday) 2026-08-13
    final thu = DateTime(2026, 8, 13);
    // Friday is tomorrow (2026-08-14), so no days between tomorrow and Friday.
    final friTask = SimpleTask(
      id: 't2',
      title: 'Friday Task',
      dueDate: '2026-08-14',
      createdAt: thu,
      updatedAt: thu,
    );
    expect(bucketOf(friTask, now: thu), equals(TaskBucket.tomorrow));

    final groups = groupTasks([friTask], now: thu);
    expect(groups.containsKey(TaskBucket.thisWeek), isFalse);

    // Jomeh (Friday) 2026-08-14
    final fri = DateTime(2026, 8, 14);
    // Tomorrow is Shanbe of next week (2026-08-15) -> tomorrow bucket
    final nextSatTask = SimpleTask(
      id: 't3',
      title: 'Next Sat Task',
      dueDate: '2026-08-15',
      createdAt: fri,
      updatedAt: fri,
    );
    expect(bucketOf(nextSatTask, now: fri), equals(TaskBucket.tomorrow));

    final friGroups = groupTasks([nextSatTask], now: fri);
    expect(friGroups.containsKey(TaskBucket.thisWeek), isFalse);
  });
}
