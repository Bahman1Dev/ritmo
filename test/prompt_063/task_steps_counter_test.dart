import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TaskStep countsFor calculates total and completed steps per task correctly', () {
    final mockSteps = [
      {'taskId': 'task_1', 'isCompleted': 1},
      {'taskId': 'task_1', 'isCompleted': 1},
      {'taskId': 'task_1', 'isCompleted': 0},
      {'taskId': 'task_2', 'isCompleted': 0},
      {'taskId': 'task_2', 'isCompleted': 0},
    ];

    final counts = <String, (int done, int total)>{};
    for (final row in mockSteps) {
      final tid = row['taskId'] as String;
      final isDone = (row['isCompleted'] as int) == 1;
      final current = counts[tid] ?? (0, 0);
      counts[tid] = (current.$1 + (isDone ? 1 : 0), current.$2 + 1);
    }

    expect(counts['task_1'], equals((2, 3)));
    expect(counts['task_2'], equals((0, 2)));
    expect(counts['task_3'], isNull);
  });
}
