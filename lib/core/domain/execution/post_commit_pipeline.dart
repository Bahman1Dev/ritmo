import 'package:flutter/foundation.dart';
import 'post_commit_task.dart';

class PostCommitPipeline {
  static Future<void> run(List<PostCommitTask> tasks) async {
    for (final task in tasks) {
      try {
        await task();
      } catch (e, st) {
        debugPrint('Post-commit task failed: $e\n$st');
      }
    }
  }
}
