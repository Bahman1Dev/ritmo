import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Search finds tasks by matching sub-step title', () {
    final tasks = [{'id': 't1', 'title': 'Project A'}];
    final steps = [{'id': 's1', 'taskId': 't1', 'title': 'Buy printer ink'}];

    final query = 'printer';
    final matchingTaskIds = steps
        .where((s) => (s['title'] as String).contains(query))
        .map((s) => s['taskId'] as String)
        .toSet();

    final results = tasks.where((t) => matchingTaskIds.contains(t['id'])).toList();
    expect(results.length, equals(1));
    expect(results.first['title'], equals('Project A'));
  });
}
