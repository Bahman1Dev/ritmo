import 'package:flutter/material.dart';

enum CourseType { video, book, skill, custom }

extension CourseTypeExtension on CourseType {
  String get name {
    switch (this) {
      case CourseType.video:
        return 'VIDEO';
      case CourseType.book:
        return 'BOOK';
      case CourseType.skill:
        return 'SKILL';
      case CourseType.custom:
        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case CourseType.video:
        return 'ویدیو / کلاس آنلاین';
      case CourseType.book:
        return 'کتاب / منبع متنی';
      case CourseType.skill:
        return 'تمرین / مهارت عملی';
      case CourseType.custom:
        return 'سایر / دلخواه';
    }
  }

  String get defaultUnitLabel {
    switch (this) {
      case CourseType.video:
        return 'جلسه';
      case CourseType.book:
        return 'فصل';
      case CourseType.skill:
        return 'تمرین';
      case CourseType.custom:
        return 'واحد';
    }
  }

  String get defaultEmoji {
    switch (this) {
      case CourseType.video:
        return '🎥';
      case CourseType.book:
        return '📖';
      case CourseType.skill:
        return '🎯';
      case CourseType.custom:
        return '📚';
    }
  }

  static CourseType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VIDEO':
        return CourseType.video;
      case 'BOOK':
        return CourseType.book;
      case 'SKILL':
        return CourseType.skill;
      case 'CUSTOM':
      default:
        return CourseType.custom;
    }
  }
}

enum CourseActivityKind {
  learn,
  practice,
  review,
  project,
  exam,
}

extension CourseActivityKindExtension on CourseActivityKind {
  String get dbValue {
    switch (this) {
      case CourseActivityKind.learn:
        return 'LEARN';
      case CourseActivityKind.practice:
        return 'PRACTICE';
      case CourseActivityKind.review:
        return 'REVIEW';
      case CourseActivityKind.project:
        return 'PROJECT';
      case CourseActivityKind.exam:
        return 'EXAM';
    }
  }

  String get label {
    switch (this) {
      case CourseActivityKind.learn:
        return 'یادگیری';
      case CourseActivityKind.practice:
        return 'تمرین';
      case CourseActivityKind.review:
        return 'مرور';
      case CourseActivityKind.project:
        return 'پروژه';
      case CourseActivityKind.exam:
        return 'آزمون';
    }
  }

  static CourseActivityKind fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PRACTICE':
        return CourseActivityKind.practice;
      case 'REVIEW':
        return CourseActivityKind.review;
      case 'PROJECT':
        return CourseActivityKind.project;
      case 'EXAM':
        return CourseActivityKind.exam;
      case 'LEARN':
      default:
        return CourseActivityKind.learn;
    }
  }
}

enum SessionStatus {
  pending,
  completed,
  skipped,
}

extension SessionStatusExtension on SessionStatus {
  String get dbValue {
    switch (this) {
      case SessionStatus.pending:
        return 'PENDING';
      case SessionStatus.completed:
        return 'COMPLETED';
      case SessionStatus.skipped:
        return 'SKIPPED';
    }
  }

  static SessionStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return SessionStatus.completed;
      case 'SKIPPED':
        return SessionStatus.skipped;
      case 'PENDING':
      default:
        return SessionStatus.pending;
    }
  }
}

class CourseStatus {
  static const String active = 'ACTIVE';
  static const String completed = 'COMPLETED';
  static const String paused = 'PAUSED';
}

class Course {
  Course({
    required this.id,
    required this.title,
    required this.totalSessions,
    required this.sessionDurationMinutes,
    this.activityType = 'STUDY',
    this.zoneId,
    this.isArchived = false,
    this.energyRule = 'NONE',
    required this.createdAt,
    required this.updatedAt,
    required this.courseType,
    this.unitLabel,
    this.emoji,
    this.colorHex,
    this.provider,
    this.weeklyTargetSessions = 3,
    this.isAdaptive = false,
    required this.preferredDays,
    this.preferredTime,
    this.reminderEnabled = false,
    this.linkedGoalId,
    this.status = CourseStatus.active,
    this.completedAt,
    this.targetEndDate,
    this.adaptiveLastAppliedAt,
    this.masteryScore = 0.0,
    this.reviewEnabled = false,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    final prefDaysStr = map['preferredDays'] as String?;
    final days = <int>[];
    if (prefDaysStr != null && prefDaysStr.trim().isNotEmpty) {
      for (final s in prefDaysStr.split(',')) {
        final val = int.tryParse(s);
        if (val != null) days.add(val);
      }
    }

    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      totalSessions: map['totalSessions'] as int,
      sessionDurationMinutes: map['sessionDurationMinutes'] as int,
      activityType: map['activityType'] as String? ?? 'STUDY',
      zoneId: map['zoneId'] as String?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      energyRule: map['energyRule'] as String? ?? 'NONE',
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      courseType: CourseTypeExtension.fromString(map['courseType'] as String? ?? 'VIDEO'),
      unitLabel: map['unitLabel'] as String?,
      emoji: map['emoji'] as String?,
      colorHex: map['colorHex'] as String?,
      provider: map['provider'] as String?,
      weeklyTargetSessions: map['weeklyTargetSessions'] as int? ?? 3,
      isAdaptive: (map['isAdaptive'] as int? ?? 0) == 1,
      preferredDays: days,
      preferredTime: map['preferredTime'] as String?,
      reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
      linkedGoalId: map['linkedGoalId'] as String?,
      status: map['status'] as String? ?? CourseStatus.active,
      completedAt: map['completedAt'] as int?,
      targetEndDate: map['targetEndDate'] as String?,
      adaptiveLastAppliedAt: map['adaptiveLastAppliedAt'] as int?,
      masteryScore: (map['masteryScore'] as num?)?.toDouble() ?? 0.0,
      reviewEnabled: (map['reviewEnabled'] as int? ?? 0) == 1,
    );
  }

  final String id;
  final String title;
  final int totalSessions;
  final int sessionDurationMinutes;
  final String activityType; // e.g., 'STUDY'
  final String? zoneId;
  final bool isArchived;
  final String energyRule; // NONE, skip, offerLight, highEnergyOnly
  final int createdAt;
  final int updatedAt;

  final CourseType courseType;
  final String? unitLabel;
  final String? emoji;
  final String? colorHex;
  final String? provider;
  final int weeklyTargetSessions;
  final bool isAdaptive;
  final List<int> preferredDays; // CSV of 0..6 (Sunday=0, etc.)
  final String? preferredTime; // 'HH:mm'
  final bool reminderEnabled;
  final String? linkedGoalId;
  final String status; // ACTIVE, COMPLETED, PAUSED
  final int? completedAt;
  final String? targetEndDate;
  final int? adaptiveLastAppliedAt;
  final double masteryScore;
  final bool reviewEnabled;

  Course copyWith({
    String? id,
    String? title,
    int? totalSessions,
    int? sessionDurationMinutes,
    String? activityType,
    String? zoneId,
    bool? isArchived,
    String? energyRule,
    int? createdAt,
    int? updatedAt,
    CourseType? courseType,
    String? unitLabel,
    String? emoji,
    String? colorHex,
    String? provider,
    int? weeklyTargetSessions,
    bool? isAdaptive,
    List<int>? preferredDays,
    String? preferredTime,
    bool preferredTimeSet = false,
    bool? reminderEnabled,
    String? linkedGoalId,
    bool linkedGoalIdSet = false,
    String? status,
    int? completedAt,
    bool completedAtSet = false,
    String? targetEndDate,
    bool targetEndDateSet = false,
    int? adaptiveLastAppliedAt,
    bool adaptiveLastAppliedAtSet = false,
    double? masteryScore,
    bool? reviewEnabled,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      totalSessions: totalSessions ?? this.totalSessions,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      activityType: activityType ?? this.activityType,
      zoneId: zoneId ?? this.zoneId,
      isArchived: isArchived ?? this.isArchived,
      energyRule: energyRule ?? this.energyRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseType: courseType ?? this.courseType,
      unitLabel: unitLabel ?? this.unitLabel,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      provider: provider ?? this.provider,
      weeklyTargetSessions: weeklyTargetSessions ?? this.weeklyTargetSessions,
      isAdaptive: isAdaptive ?? this.isAdaptive,
      preferredDays: preferredDays ?? this.preferredDays,
      preferredTime: preferredTimeSet ? preferredTime : (preferredTime ?? this.preferredTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      linkedGoalId: linkedGoalIdSet ? linkedGoalId : (linkedGoalId ?? this.linkedGoalId),
      status: status ?? this.status,
      completedAt: completedAtSet ? completedAt : (completedAt ?? this.completedAt),
      targetEndDate: targetEndDateSet ? targetEndDate : (targetEndDate ?? this.targetEndDate),
      adaptiveLastAppliedAt: adaptiveLastAppliedAtSet ? adaptiveLastAppliedAt : (adaptiveLastAppliedAt ?? this.adaptiveLastAppliedAt),
      masteryScore: masteryScore ?? this.masteryScore,
      reviewEnabled: reviewEnabled ?? this.reviewEnabled,
    );
  }

  String get statusLabel {
    switch (status) {
      case CourseStatus.completed:
        return 'تکمیل‌شده';
      case CourseStatus.paused:
        return 'متوقف‌شده';
      case CourseStatus.active:
      default:
        return 'در حال یادگیری';
    }
  }

  String get unitLabelResolved {
    if (courseType == CourseType.custom && unitLabel != null && unitLabel!.trim().isNotEmpty) {
      return unitLabel!.trim();
    }
    return courseType.defaultUnitLabel;
  }

  String get emojiResolved {
    if (emoji != null && emoji!.trim().isNotEmpty) {
      return emoji!;
    }
    return courseType.defaultEmoji;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalSessions': totalSessions,
      'sessionDurationMinutes': sessionDurationMinutes,
      'activityType': activityType,
      'zoneId': zoneId,
      'isArchived': isArchived ? 1 : 0,
      'energyRule': energyRule,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'courseType': courseType.name,
      'unitLabel': unitLabel,
      'emoji': emoji,
      'colorHex': colorHex,
      'provider': provider,
      'weeklyTargetSessions': weeklyTargetSessions,
      'isAdaptive': isAdaptive ? 1 : 0,
      'preferredDays': preferredDays.join(','),
      'preferredTime': preferredTime,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'linkedGoalId': linkedGoalId,
      'status': status,
      'completedAt': completedAt,
      'targetEndDate': targetEndDate,
      'adaptiveLastAppliedAt': adaptiveLastAppliedAt,
      'masteryScore': masteryScore,
      'reviewEnabled': reviewEnabled ? 1 : 0,
    };
  }
}

extension SafeCourseColor on Course {
  Color resolvedColor(Color fallback) {
    if (colorHex == null || colorHex!.trim().isEmpty) return fallback;
    try {
      var hex = colorHex!.trim().replaceAll('#', '');
      if (hex.startsWith('0x') || hex.startsWith('0X')) {
        hex = hex.substring(2);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    } catch (_) {}
    return fallback;
  }
}

class CourseSession {
  CourseSession({
    required this.id,
    required this.courseId,
    required this.sessionNumber,
    this.plannedDate,
    this.completionStatus = SessionStatus.pending,
    this.actualDurationMinutes,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.sessionTitle,
    this.completedAt,
    this.isUserScheduled = false,
    this.plannedStartTime,
    this.estimatedDurationMinutes,
    this.sectionTitle,
    this.learningObjective,
    this.difficulty,
    this.activityKind = CourseActivityKind.learn,
    this.understandingScore,
    this.needsReview = false,
    this.keyTakeaway,
    this.openQuestion,
    this.sourceSessionId,
    this.skipReason,
    this.displayOrder = 0,
  });

  factory CourseSession.fromMap(Map<String, dynamic> map) {
    return CourseSession(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      sessionNumber: map['sessionNumber'] as int,
      plannedDate: map['plannedDate'] as String?,
      completionStatus: SessionStatusExtension.fromString(map['completionStatus'] as String?),
      actualDurationMinutes: map['actualDurationMinutes'] as int?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      sessionTitle: map['sessionTitle'] as String?,
      completedAt: map['completedAt'] as int?,
      isUserScheduled: (map['isUserScheduled'] as int? ?? 0) == 1,
      plannedStartTime: map['plannedStartTime'] as String?,
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int?,
      sectionTitle: map['sectionTitle'] as String?,
      learningObjective: map['learningObjective'] as String?,
      difficulty: map['difficulty'] as int?,
      activityKind: CourseActivityKindExtension.fromString(map['activityKind'] as String?),
      understandingScore: map['understandingScore'] as int?,
      needsReview: (map['needsReview'] as int? ?? 0) == 1,
      keyTakeaway: map['keyTakeaway'] as String?,
      openQuestion: map['openQuestion'] as String?,
      sourceSessionId: map['sourceSessionId'] as String?,
      skipReason: map['skipReason'] as String?,
      displayOrder: map['displayOrder'] as int? ?? 0,
    );
  }

  final String id;
  final String courseId;
  final int sessionNumber;
  final String? plannedDate; // 'YYYY-MM-DD'
  final SessionStatus completionStatus;
  final int? actualDurationMinutes;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final String? sessionTitle;
  final int? completedAt;
  final bool isUserScheduled;
  final String? plannedStartTime;
  final int? estimatedDurationMinutes;
  final String? sectionTitle;
  final String? learningObjective;
  final int? difficulty;
  final CourseActivityKind activityKind;
  final int? understandingScore;
  final bool needsReview;
  final String? keyTakeaway;
  final String? openQuestion;
  final String? sourceSessionId;
  final String? skipReason;
  final int displayOrder;

  bool get isCompleted => completionStatus == SessionStatus.completed;
  bool get isSkipped => completionStatus == SessionStatus.skipped;

  bool isScheduledToday(String todayStr) => plannedDate == todayStr;

  bool isOverdue(String todayStr) {
    if (isCompleted || isSkipped || plannedDate == null) return false;
    return plannedDate!.compareTo(todayStr) < 0;
  }

  CourseSession copyWith({
    String? id,
    String? courseId,
    int? sessionNumber,
    String? plannedDate,
    bool plannedDateSet = false,
    SessionStatus? completionStatus,
    int? actualDurationMinutes,
    bool actualDurationMinutesSet = false,
    String? note,
    bool noteSet = false,
    int? createdAt,
    int? updatedAt,
    String? sessionTitle,
    bool sessionTitleSet = false,
    int? completedAt,
    bool completedAtSet = false,
    bool? isUserScheduled,
    String? plannedStartTime,
    bool plannedStartTimeSet = false,
    int? estimatedDurationMinutes,
    bool estimatedDurationMinutesSet = false,
    String? sectionTitle,
    bool sectionTitleSet = false,
    String? learningObjective,
    bool learningObjectiveSet = false,
    int? difficulty,
    bool difficultySet = false,
    CourseActivityKind? activityKind,
    int? understandingScore,
    bool understandingScoreSet = false,
    bool? needsReview,
    String? keyTakeaway,
    bool keyTakeawaySet = false,
    String? openQuestion,
    bool openQuestionSet = false,
    String? sourceSessionId,
    bool sourceSessionIdSet = false,
    String? skipReason,
    bool skipReasonSet = false,
    int? displayOrder,
  }) {
    return CourseSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      plannedDate: plannedDateSet ? plannedDate : (plannedDate ?? this.plannedDate),
      completionStatus: completionStatus ?? this.completionStatus,
      actualDurationMinutes: actualDurationMinutesSet ? actualDurationMinutes : (actualDurationMinutes ?? this.actualDurationMinutes),
      note: noteSet ? note : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionTitle: sessionTitleSet ? sessionTitle : (sessionTitle ?? this.sessionTitle),
      completedAt: completedAtSet ? completedAt : (completedAt ?? this.completedAt),
      isUserScheduled: isUserScheduled ?? this.isUserScheduled,
      plannedStartTime: plannedStartTimeSet ? plannedStartTime : (plannedStartTime ?? this.plannedStartTime),
      estimatedDurationMinutes: estimatedDurationMinutesSet ? estimatedDurationMinutes : (estimatedDurationMinutes ?? this.estimatedDurationMinutes),
      sectionTitle: sectionTitleSet ? sectionTitle : (sectionTitle ?? this.sectionTitle),
      learningObjective: learningObjectiveSet ? learningObjective : (learningObjective ?? this.learningObjective),
      difficulty: difficultySet ? difficulty : (difficulty ?? this.difficulty),
      activityKind: activityKind ?? this.activityKind,
      understandingScore: understandingScoreSet ? understandingScore : (understandingScore ?? this.understandingScore),
      needsReview: needsReview ?? this.needsReview,
      keyTakeaway: keyTakeawaySet ? keyTakeaway : (keyTakeaway ?? this.keyTakeaway),
      openQuestion: openQuestionSet ? openQuestion : (openQuestion ?? this.openQuestion),
      sourceSessionId: sourceSessionIdSet ? sourceSessionId : (sourceSessionId ?? this.sourceSessionId),
      skipReason: skipReasonSet ? skipReason : (skipReason ?? this.skipReason),
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  CourseSession clearCompletedAt() => copyWith(completedAtSet: true, completedAt: null, completionStatus: SessionStatus.pending);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'sessionNumber': sessionNumber,
      'plannedDate': plannedDate,
      'completionStatus': completionStatus.dbValue,
      'actualDurationMinutes': actualDurationMinutes,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sessionTitle': sessionTitle,
      'completedAt': completedAt,
      'isUserScheduled': isUserScheduled ? 1 : 0,
      'plannedStartTime': plannedStartTime,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'sectionTitle': sectionTitle,
      'learningObjective': learningObjective,
      'difficulty': difficulty,
      'activityKind': activityKind.dbValue,
      'understandingScore': understandingScore,
      'needsReview': needsReview ? 1 : 0,
      'keyTakeaway': keyTakeaway,
      'openQuestion': openQuestion,
      'sourceSessionId': sourceSessionId,
      'skipReason': skipReason,
      'displayOrder': displayOrder,
    };
  }
}
