import 'dart:math';

class TaskAttachment {
  final String id;
  final String taskId;
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final String localPath; // Relative path, e.g., task_attachments/<taskId>/<id>_<fileName>
  final DateTime createdAt;

  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    required this.localPath,
    required this.createdAt,
  });

  static String generateId() =>
      'att_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  factory TaskAttachment.fromMap(Map<String, dynamic> m) {
    return TaskAttachment(
      id: m['id'] as String,
      taskId: m['taskId'] as String,
      fileName: m['fileName'] as String,
      fileSizeBytes: m['fileSizeBytes'] as int? ?? 0,
      mimeType: m['mimeType'] as String?,
      localPath: m['localPath'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'localPath': localPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
