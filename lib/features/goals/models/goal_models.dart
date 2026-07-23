import 'package:flutter/material.dart';

enum GoalLevel {
  annual,
  monthly,
  weekly,
  daily;

  String get label {
    switch (this) {
      case GoalLevel.annual:
        return 'سالانه';
      case GoalLevel.monthly:
        return 'ماهانه';
      case GoalLevel.weekly:
        return 'هفتگی';
      case GoalLevel.daily:
        return 'روزانه';
    }
  }

  static GoalLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ANNUAL':
        return GoalLevel.annual;
      case 'MONTHLY':
        return GoalLevel.monthly;
      case 'WEEKLY':
        return GoalLevel.weekly;
      case 'DAILY':
      default:
        return GoalLevel.daily;
    }
  }

  String toJson() => toString().split('.').last.toUpperCase();
}

class Goal {

  Goal({
    required this.id,
    this.parentGoalId,
    required this.title,
    this.description,
    required this.goalType,
    this.status = 'ACTIVE',
    this.targetDate,
    this.progressCache = 0.0,
    this.isPrivate = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      parentGoalId: map['parentGoalId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      goalType: GoalLevel.fromString(map['goalType'] as String? ?? 'DAILY'),
      status: map['status'] as String? ?? 'ACTIVE',
      targetDate: map['targetDate'] as String?,
      progressCache: (map['progressCache'] as num?)?.toDouble() ?? 0.0,
      isPrivate: map['isPrivate'] as int? ?? 0,
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
    );
  }
  final String id;
  final String? parentGoalId;
  final String title;
  final String? description;
  final GoalLevel goalType;
  final String status; // 'ACTIVE' or 'COMPLETED'
  final String? targetDate; // ISO 'YYYY-MM-DD'
  final double progressCache;
  final int isPrivate;
  final int createdAt;
  final int updatedAt;

  bool get isOverdue {
    if (status == 'COMPLETED' || targetDate == null || targetDate!.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return targetDate!.compareTo(today) < 0;
  }

  int get daysUntilTarget {
    if (targetDate == null || targetDate!.isEmpty) return 9999;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    try {
      final target = DateTime.parse(targetDate!);
      final targetDateOnly = DateTime(target.year, target.month, target.day);
      return targetDateOnly.difference(todayDateOnly).inDays;
    } catch (_) {
      return 9999;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentGoalId': parentGoalId,
      'title': title,
      'description': description,
      'goalType': goalType.toJson(),
      'status': status,
      'targetDate': targetDate,
      'progressCache': progressCache,
      'isPrivate': isPrivate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Goal copyWith({
    String? id,
    String? parentGoalId,
    String? title,
    String? description,
    GoalLevel? goalType,
    String? status,
    String? targetDate,
    double? progressCache,
    int? isPrivate,
    int? createdAt,
    int? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      parentGoalId: parentGoalId ?? this.parentGoalId,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      progressCache: progressCache ?? this.progressCache,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GoalStep {

  GoalStep({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isCompleted,
    required this.displayOrder,
    required this.createdAt,
    this.scheduledDate,
    this.linkedRoutineId,
  });

  factory GoalStep.fromMap(Map<String, dynamic> map) {
    return GoalStep(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      displayOrder: map['displayOrder'] as int? ?? 0,
      createdAt: map['createdAt'] as int? ?? 0,
      scheduledDate: map['scheduledDate'] as String?,
      linkedRoutineId: map['linkedRoutineId'] as String?,
    );
  }
  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final int displayOrder;
  final int createdAt;
  final String? scheduledDate; // ISO 'YYYY-MM-DD'
  final String? linkedRoutineId;

  bool get isOverdue {
    if (isCompleted || scheduledDate == null || scheduledDate!.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return scheduledDate!.compareTo(today) < 0;
  }

  bool get hasLinkedRoutine => linkedRoutineId != null && linkedRoutineId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'displayOrder': displayOrder,
      'createdAt': createdAt,
      'scheduledDate': scheduledDate,
      'linkedRoutineId': linkedRoutineId,
    };
  }
}

enum TimelineSource {
  goalStep,
  courseSession,
  konkurPlan;

  String get label {
    switch (this) {
      case TimelineSource.goalStep:
        return 'گام هدف';
      case TimelineSource.courseSession:
        return 'جلسه دوره';
      case TimelineSource.konkurPlan:
        return 'برنامه کنکور';
    }
  }

  IconData get icon {
    switch (this) {
      case TimelineSource.goalStep:
        return Icons.flag;
      case TimelineSource.courseSession:
        return Icons.school;
      case TimelineSource.konkurPlan:
        return Icons.assignment;
    }
  }
}

class TimelineItem {

  TimelineItem({
    required this.dateIso,
    required this.title,
    required this.source,
    required this.sourceId,
    required this.isDone,
    this.subtitle,
  });
  final String dateIso;
  final String title;
  final TimelineSource source;
  final String sourceId;
  final bool isDone;
  final String? subtitle;
}
