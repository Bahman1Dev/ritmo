import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/logic/task_bucketing.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  test('Dates after current Shamsi week map to later, null dueDate maps to someday', () {
    // Saturday 18 Mordad 1405 = 2026-08-08 (Friday of week is 24 Mordad = 2026-08-14)
    final sat = Jalali(1405, 5, 18).toDateTime();
    final nextWeekTask = SimpleTask(
      id: 't1',
      title: 'Next Week Task',
      dueDate: '2026-08-16', // Next Sunday
      createdAt: sat,
      updatedAt: sat,
    );
    final somedayTask = SimpleTask(
      id: 't2',
      title: 'Undated Task',
      dueDate: null,
      createdAt: sat,
      updatedAt: sat,
    );

    expect(bucketOf(nextWeekTask, now: sat), equals(TaskBucket.later));
    expect(bucketOf(somedayTask, now: sat), equals(TaskBucket.someday));
  });
}
