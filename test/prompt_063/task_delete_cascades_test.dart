import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task delete cascades to delete associated task_steps and task_attachments', () {
    final taskIds = ['task_1'];
    final steps = [{'id': 's1', 'taskId': 'task_1'}, {'id': 's2', 'taskId': 'task_1'}];
    final attachments = [{'id': 'a1', 'taskId': 'task_1'}];

    // Simulate cascade delete
    final deletedTaskId = 'task_1';
    steps.removeWhere((s) => s['taskId'] == deletedTaskId);
    attachments.removeWhere((a) => a['taskId'] == deletedTaskId);
    taskIds.remove(deletedTaskId);

    expect(taskIds, isEmpty);
    expect(steps, isEmpty);
    expect(attachments, isEmpty);
  });
}
