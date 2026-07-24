import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/execution/post_commit_pipeline.dart';

void main() {
  test('PostCommitPipeline continues after one task fails', () async {
    final calls = <String>[];

    await PostCommitPipeline.run([
      () async {
        calls.add('first');
        throw Exception('boom');
      },
      () async {
        calls.add('second');
      },
    ]);

    expect(calls, ['first', 'second']);
  });

  test('PostCommitPipeline executes all tasks in exact sequential order', () async {
    final order = <int>[];

    await PostCommitPipeline.run([
      () async => order.add(1),
      () async => order.add(2),
      () async => order.add(3),
    ]);

    expect(order, [1, 2, 3]);
  });
}
