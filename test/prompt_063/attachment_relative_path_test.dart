import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/simple_tasks/domain/task_attachment.dart';

void main() {
  test('TaskAttachment stores relative path, surviving sandbox root changes', () {
    final att = TaskAttachment(
      id: 'att_123',
      taskId: 'task_55',
      fileName: 'doc.pdf',
      fileSizeBytes: 1024,
      localPath: 'task_attachments/task_55/att_123_doc.pdf',
      createdAt: DateTime.now(),
    );

    expect(att.localPath, isNot(startsWith('/')));
    expect(att.localPath, isNot(startsWith('C:')));
    expect(att.localPath, startsWith('task_attachments/task_55/'));

    final map = att.toMap();
    expect(map['localPath'], equals('task_attachments/task_55/att_123_doc.pdf'));
  });
}
