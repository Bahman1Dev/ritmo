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

  static GoalLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ANNUAL':
        return GoalLevel.annual;
      case 'MONTHLY':
        return GoalLevel.monthly;
      case 'WEEKLY':
        return GoalLevel.weekly;
      case 'DAILY':
      default:
        assert(false, 'GOALS: unknown GoalLevel "$value"');
        debugPrint('GOALS_WARN unknown GoalLevel "$value" -> daily');
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
    this.completedAt,
    this.completionSource,
    this.lastActivityAt,
    this.weight = 1.0,
    this.whyItMatters,
    this.pastFailure,
    this.selfPromise,
    this.metricUnit,
    this.metricTarget,
    this.metricStart,
    this.pausedAt,
    this.abandonedAt,
    this.abandonReason,
    this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      parentGoalId: map['parentGoalId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      goalType: GoalLevel.fromString(map['goalType'] as String?),
      status: map['status'] as String? ?? 'ACTIVE',
      targetDate: map['targetDate'] as String?,
      progressCache: (map['progressCache'] as num?)?.toDouble() ?? 0.0,
      isPrivate: map['isPrivate'] as int? ?? 0,
      completedAt: map['completedAt'] as int?,
      completionSource: map['completionSource'] as String?,
      lastActivityAt: map['lastActivityAt'] as int?,
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
      whyItMatters: map['whyItMatters'] as String?,
      pastFailure: map['pastFailure'] as String?,
      selfPromise: map['selfPromise'] as String?,
      metricUnit: map['metricUnit'] as String?,
      metricTarget: (map['metricTarget'] as num?)?.toDouble(),
      metricStart: (map['metricStart'] as num?)?.toDouble(),
      pausedAt: map['pausedAt'] as int?,
      abandonedAt: map['abandonedAt'] as int?,
      abandonReason: map['abandonReason'] as String?,
      iconKey: map['iconKey'] as String?,
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
    );
  }

  final String id;
  final String? parentGoalId;
  final String title;
  final String? description;
  final GoalLevel goalType;
  final String status; // 'ACTIVE', 'COMPLETED', 'PAUSED', 'ABANDONED'
  final String? targetDate; // ISO 'YYYY-MM-DD'
  final double progressCache;
  final int isPrivate;
  final int? completedAt;
  final String? completionSource; // 'AUTO', 'MANUAL'
  final int? lastActivityAt;
  final double weight;
  final String? whyItMatters;
  final String? pastFailure;
  final String? selfPromise;
  final String? metricUnit;
  final double? metricTarget;
  final double? metricStart;
  final int? pausedAt;
  final int? abandonedAt;
  final String? abandonReason;
  final String? iconKey;
  final int createdAt;
  final int updatedAt;

  bool isOverdueAt(DateTime today) {
    if (status == 'COMPLETED' || status == 'PAUSED' || status == 'ABANDONED' || targetDate == null || targetDate!.isEmpty) {
      return false;
    }
    final todayStr = today.toIso8601String().substring(0, 10);
    return targetDate!.compareTo(todayStr) < 0;
  }

  @Deprecated('Use isOverdueAt(today) instead')
  bool get isOverdue => isOverdueAt(DateTime.now());

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
      'completedAt': completedAt,
      'completionSource': completionSource,
      'lastActivityAt': lastActivityAt,
      'weight': weight,
      'whyItMatters': whyItMatters,
      'pastFailure': pastFailure,
      'selfPromise': selfPromise,
      'metricUnit': metricUnit,
      'metricTarget': metricTarget,
      'metricStart': metricStart,
      'pausedAt': pausedAt,
      'abandonedAt': abandonedAt,
      'abandonReason': abandonReason,
      'iconKey': iconKey,
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
    int? completedAt,
    String? completionSource,
    int? lastActivityAt,
    double? weight,
    String? whyItMatters,
    String? pastFailure,
    String? selfPromise,
    String? metricUnit,
    double? metricTarget,
    double? metricStart,
    int? pausedAt,
    int? abandonedAt,
    String? abandonReason,
    String? iconKey,
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
      completedAt: completedAt ?? this.completedAt,
      completionSource: completionSource ?? this.completionSource,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      weight: weight ?? this.weight,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      pastFailure: pastFailure ?? this.pastFailure,
      selfPromise: selfPromise ?? this.selfPromise,
      metricUnit: metricUnit ?? this.metricUnit,
      metricTarget: metricTarget ?? this.metricTarget,
      metricStart: metricStart ?? this.metricStart,
      pausedAt: pausedAt ?? this.pausedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      abandonReason: abandonReason ?? this.abandonReason,
      iconKey: iconKey ?? this.iconKey,
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
    this.completedAt,
    this.scheduledDate,
    this.linkedRoutineId,
    this.completionRule = 'MANUAL',
    this.ruleConfig,
    this.dependsOnStepId,
    this.reminderEnabled = false,
    this.reminderTime,
    this.estimatedMinutes,
    this.notes,
  });

  factory GoalStep.fromMap(Map<String, dynamic> map) {
    return GoalStep(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      displayOrder: map['displayOrder'] as int? ?? 0,
      createdAt: map['createdAt'] as int? ?? 0,
      completedAt: map['completedAt'] as int?,
      scheduledDate: map['scheduledDate'] as String?,
      linkedRoutineId: map['linkedRoutineId'] as String?,
      completionRule: map['completionRule'] as String? ?? 'MANUAL',
      ruleConfig: map['ruleConfig'] as String?,
      dependsOnStepId: map['dependsOnStepId'] as String?,
      reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
      reminderTime: map['reminderTime'] as String?,
      estimatedMinutes: map['estimatedMinutes'] as int?,
      notes: map['notes'] as String?,
    );
  }

  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final int displayOrder;
  final int createdAt;
  final int? completedAt;
  final String? scheduledDate; // ISO 'YYYY-MM-DD'
  final String? linkedRoutineId;
  final String completionRule; // 'MANUAL', 'ROUTINE_STREAK', 'METRIC'
  final String? ruleConfig;
  final String? dependsOnStepId;
  final bool reminderEnabled;
  final String? reminderTime; // 'HH:mm'
  final int? estimatedMinutes;
  final String? notes;

  bool isOverdueAt(DateTime today) {
    if (isCompleted || scheduledDate == null || scheduledDate!.isEmpty) return false;
    final todayStr = today.toIso8601String().substring(0, 10);
    return scheduledDate!.compareTo(todayStr) < 0;
  }

  @Deprecated('Use isOverdueAt(today) instead')
  bool get isOverdue => isOverdueAt(DateTime.now());

  bool get hasLinkedRoutine => linkedRoutineId != null && linkedRoutineId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'displayOrder': displayOrder,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'scheduledDate': scheduledDate,
      'linkedRoutineId': linkedRoutineId,
      'completionRule': completionRule,
      'ruleConfig': ruleConfig,
      'dependsOnStepId': dependsOnStepId,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderTime': reminderTime,
      'estimatedMinutes': estimatedMinutes,
      'notes': notes,
    };
  }

  GoalStep copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isCompleted,
    int? displayOrder,
    int? createdAt,
    int? completedAt,
    String? scheduledDate,
    String? linkedRoutineId,
    String? completionRule,
    String? ruleConfig,
    String? dependsOnStepId,
    bool? reminderEnabled,
    String? reminderTime,
    int? estimatedMinutes,
    String? notes,
  }) {
    return GoalStep(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      linkedRoutineId: linkedRoutineId ?? this.linkedRoutineId,
      completionRule: completionRule ?? this.completionRule,
      ruleConfig: ruleConfig ?? this.ruleConfig,
      dependsOnStepId: dependsOnStepId ?? this.dependsOnStepId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      notes: notes ?? this.notes,
    );
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

class RoutineRef {
  RoutineRef({
    required this.id,
    required this.title,
    this.iconKey,
    this.scheduleSummary,
    this.isArchived = false,
  });

  factory RoutineRef.fromMap(Map<String, dynamic> map) {
    return RoutineRef(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      iconKey: map['iconKey'] as String?,
      scheduleSummary: map['scheduleSummary'] as String?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
    );
  }

  final String id;
  final String title;
  final String? iconKey;
  final String? scheduleSummary;
  final bool isArchived;

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'title') return title;
    if (key == 'iconKey') return iconKey;
    if (key == 'scheduleSummary') return scheduleSummary;
    if (key == 'isArchived') return isArchived;
    return null;
  }
}

class GoalDeletionImpact {
  GoalDeletionImpact({
    required this.subGoalCount,
    required this.stepCount,
    required this.completedStepCount,
    required this.linkedRoutineCount,
    required this.scheduledReminderCount,
  });

  final int subGoalCount;
  final int stepCount;
  final int completedStepCount;
  final int linkedRoutineCount;
  final int scheduledReminderCount;
}

