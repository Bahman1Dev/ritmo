import 'dart:math';

class SimpleTask {
  final String id;
  final String title;
  final String? note;
  final bool isDone;
  final DateTime? doneAt;
  final String? dueDate; // 'YYYY-MM-DD'
  final String? dueTime; // 'HH:mm'
  final int? reminderAtMs;
  final String? reminderId;
  final String? linkedRoutineId;
  final int orderIndex;
  final String origin; // 'SIMPLE' or 'PROMOTED'
  final DateTime createdAt;
  final DateTime updatedAt;

  const SimpleTask({
    required this.id,
    required this.title,
    this.note,
    this.isDone = false,
    this.doneAt,
    this.dueDate,
    this.dueTime,
    this.reminderAtMs,
    this.reminderId,
    this.linkedRoutineId,
    this.orderIndex = 0,
    this.origin = 'SIMPLE',
    required this.createdAt,
    required this.updatedAt,
  });

  static String generateId() {
    return 'task_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  bool get isSomeday => dueDate == null;

  factory SimpleTask.fromMap(Map<String, dynamic> m) {
    return SimpleTask(
      id: m['id'] as String,
      title: m['title'] as String,
      note: m['note'] as String?,
      isDone: (m['isDone'] as int? ?? 0) == 1,
      doneAt: m['doneAt'] != null ? DateTime.fromMillisecondsSinceEpoch(m['doneAt'] as int) : null,
      dueDate: m['dueDate'] as String?,
      dueTime: m['dueTime'] as String?,
      reminderAtMs: m['reminderAtMs'] as int?,
      reminderId: m['reminderId'] as String?,
      linkedRoutineId: m['linkedRoutineId'] as String?,
      orderIndex: m['orderIndex'] as int? ?? 0,
      origin: m['origin'] as String? ?? 'SIMPLE',
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'isDone': isDone ? 1 : 0,
      'doneAt': doneAt?.millisecondsSinceEpoch,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'reminderAtMs': reminderAtMs,
      'reminderId': reminderId,
      'linkedRoutineId': linkedRoutineId,
      'orderIndex': orderIndex,
      'origin': origin,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  SimpleTask copyWith({
    String? id,
    String? title,
    String? note,
    bool? isDone,
    DateTime? doneAt,
    String? dueDate,
    String? dueTime,
    int? reminderAtMs,
    String? reminderId,
    String? linkedRoutineId,
    int? orderIndex,
    String? origin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SimpleTask(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderAtMs: reminderAtMs ?? this.reminderAtMs,
      reminderId: reminderId ?? this.reminderId,
      linkedRoutineId: linkedRoutineId ?? this.linkedRoutineId,
      orderIndex: orderIndex ?? this.orderIndex,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
