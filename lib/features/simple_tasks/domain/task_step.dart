import 'dart:math';

class TaskStep {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskStep({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.displayOrder = 0,
    required this.createdAt,
    this.completedAt,
  });

  static String generateId() =>
      'step_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  factory TaskStep.fromMap(Map<String, dynamic> m) {
    return TaskStep(
      id: m['id'] as String,
      taskId: m['taskId'] as String,
      title: m['title'] as String,
      isCompleted: (m['isCompleted'] as int? ?? 0) == 1,
      displayOrder: m['displayOrder'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      completedAt: m['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['completedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'displayOrder': displayOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  TaskStep copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? displayOrder,
    DateTime? createdAt,
    bool clearCompletedAt = false,
    DateTime? completedAt,
  }) {
    return TaskStep(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
