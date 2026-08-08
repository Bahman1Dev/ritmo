import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/task_step.dart';

void main() {
  test('TaskStep domain model serialization, copyWith, and ID generation', () {
    final now = DateTime.now();
    final step = TaskStep(
      id: TaskStep.generateId(),
      taskId: 'task_100',
      title: 'First step',
      isCompleted: false,
      displayOrder: 0,
      createdAt: now,
    );

    expect(step.id, startsWith('step_'));
    expect(step.taskId, equals('task_100'));
    expect(step.title, equals('First step'));
    expect(step.isCompleted, isFalse);

    final map = step.toMap();
    expect(map['taskId'], equals('task_100'));
    expect(map['title'], equals('First step'));
    expect(map['isCompleted'], equals(0));

    final restored = TaskStep.fromMap(map);
    expect(restored.id, equals(step.id));
    expect(restored.title, equals(step.title));
    expect(restored.isCompleted, isFalse);

    final updated = restored.copyWith(isCompleted: true, completedAt: now);
    expect(updated.isCompleted, isTrue);
    expect(updated.completedAt?.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
  });
}
