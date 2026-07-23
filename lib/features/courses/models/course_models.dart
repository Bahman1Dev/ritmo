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

  // New fields from Migration v13
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
    bool? reminderEnabled,
    String? linkedGoalId,
    String? status,
    int? completedAt,
    String? targetEndDate,
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
      preferredTime: preferredTime ?? this.preferredTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      targetEndDate: targetEndDate ?? this.targetEndDate,
    );
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
    };
  }
}

class CourseSession { // new in v13

  CourseSession({
    required this.id,
    required this.courseId,
    required this.sessionNumber,
    this.plannedDate,
    this.completionStatus = 'PENDING',
    this.actualDurationMinutes,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.sessionTitle,
  });

  factory CourseSession.fromMap(Map<String, dynamic> map) {
    return CourseSession(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      sessionNumber: map['sessionNumber'] as int,
      plannedDate: map['plannedDate'] as String?,
      completionStatus: map['completionStatus'] as String? ?? 'PENDING',
      actualDurationMinutes: map['actualDurationMinutes'] as int?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      sessionTitle: map['sessionTitle'] as String?,
    );
  }
  final String id;
  final String courseId;
  final int sessionNumber;
  final String? plannedDate; // 'YYYY-MM-DD'
  final String completionStatus; // PENDING, COMPLETED
  final int? actualDurationMinutes;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final String? sessionTitle;

  bool get isCompleted => completionStatus == 'COMPLETED';

  bool isScheduledToday(String todayStr) => plannedDate == todayStr;

  bool isOverdue(String todayStr) {
    if (isCompleted || plannedDate == null) return false;
    return plannedDate!.compareTo(todayStr) < 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'sessionNumber': sessionNumber,
      'plannedDate': plannedDate,
      'completionStatus': completionStatus,
      'actualDurationMinutes': actualDurationMinutes,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sessionTitle': sessionTitle,
    };
  }
}
