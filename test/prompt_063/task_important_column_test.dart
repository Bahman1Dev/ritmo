import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';

void main() {
  test('SimpleTask domain model correctly handles isImportant and importantAt', () {
    final now = DateTime.now();
    final task = SimpleTask(
      id: 'task_1',
      title: 'Important Test',
      isImportant: true,
      importantAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final map = task.toMap();
    expect(map['isImportant'], equals(1));
    expect(map['importantAt'], equals(now.millisecondsSinceEpoch));

    final restored = SimpleTask.fromMap(map);
    expect(restored.isImportant, isTrue);
    expect(restored.importantAt?.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

    final cleared = restored.copyWith(isImportant: false, clearImportantAt: true);
    expect(cleared.isImportant, isFalse);
    expect(cleared.importantAt, isNull);
  });
}
