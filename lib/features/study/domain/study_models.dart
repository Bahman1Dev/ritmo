enum StudyMastery { notStarted, learning, review, mastered }
enum StudyMode { learn, practice, review }
enum StudyOrigin { user, konkurPreset }

class StudySubject {
  const StudySubject({
    required this.id,
    required this.name,
    this.emoji,
    this.colorHex,
    this.weeklyTargetMinutes = 0,
    this.origin = StudyOrigin.user,
    this.isArchived = false,
    this.orderIndex = 0,
    this.importanceFactor = 1.0,
    this.examQuestionCount = 0,
    this.subjectGroup = 'GENERAL',
  });

  final String id;
  final String name;
  final String? emoji;
  final String? colorHex;
  final int weeklyTargetMinutes;
  final StudyOrigin origin;
  final bool isArchived;
  final int orderIndex;

  final double importanceFactor;
  final int examQuestionCount;
  final String subjectGroup;

  factory StudySubject.fromMap(Map<String, dynamic> map) {
    final origStr = map['origin'] as String? ?? 'USER';
    return StudySubject(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String?,
      colorHex: map['colorHex'] as String?,
      weeklyTargetMinutes: map['weeklyTargetMinutes'] as int? ?? 0,
      origin: origStr == 'KONKUR_PRESET' ? StudyOrigin.konkurPreset : StudyOrigin.user,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      orderIndex: map['orderIndex'] as int? ?? 0,
      importanceFactor: (map['importanceFactor'] as num?)?.toDouble() ?? 1.0,
      examQuestionCount: map['examQuestionCount'] as int? ?? 0,
      subjectGroup: map['subjectGroup'] as String? ?? 'GENERAL',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorHex': colorHex,
      'weeklyTargetMinutes': weeklyTargetMinutes,
      'origin': origin == StudyOrigin.konkurPreset ? 'KONKUR_PRESET' : 'USER',
      'isArchived': isArchived ? 1 : 0,
      'orderIndex': orderIndex,
      'importanceFactor': importanceFactor,
      'examQuestionCount': examQuestionCount,
      'subjectGroup': subjectGroup,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.subjectId,
    this.parentTopicId,
    required this.name,
    this.mastery = StudyMastery.notStarted,
    this.studyCompletedMinutes = 0,
    this.lastStudiedAtMs,
    this.nextReviewDateIso,
    this.plannedDateIso,
    this.orderIndex = 0,
    this.origin = StudyOrigin.user,
    this.chapter,
  });

  final String id;
  final String subjectId;
  final String? parentTopicId;
  final String name;
  final StudyMastery mastery;
  final int studyCompletedMinutes;
  final int? lastStudiedAtMs;
  final String? nextReviewDateIso;
  final String? plannedDateIso;
  final int orderIndex;
  final StudyOrigin origin;
  final String? chapter;

  factory StudyTopic.fromMap(Map<String, dynamic> map) {
    final origStr = map['origin'] as String? ?? 'USER';
    final mStr = map['masteryLevel'] as String? ?? 'NOT_STARTED';
    StudyMastery m = StudyMastery.notStarted;
    if (mStr == 'LEARNING') m = StudyMastery.learning;
    if (mStr == 'NEEDS_REVIEW' || mStr == 'REVIEW') m = StudyMastery.review;
    if (mStr == 'MASTERED') m = StudyMastery.mastered;

    return StudyTopic(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      parentTopicId: map['parentTopicId'] as String?,
      name: map['name'] as String,
      mastery: m,
      studyCompletedMinutes: map['studyCompletedMinutes'] as int? ?? 0,
      lastStudiedAtMs: map['lastStudiedAt'] as int?,
      nextReviewDateIso: map['nextReviewDate'] as String?,
      plannedDateIso: map['plannedDate'] as String?,
      orderIndex: map['orderIndex'] as int? ?? 0,
      origin: origStr == 'KONKUR_PRESET' ? StudyOrigin.konkurPreset : StudyOrigin.user,
      chapter: map['chapter'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    String mStr = 'NOT_STARTED';
    if (mastery == StudyMastery.learning) mStr = 'LEARNING';
    if (mastery == StudyMastery.review) mStr = 'NEEDS_REVIEW';
    if (mastery == StudyMastery.mastered) mStr = 'MASTERED';

    return {
      'id': id,
      'subjectId': subjectId,
      'parentTopicId': parentTopicId,
      'name': name,
      'masteryLevel': mStr,
      'studyCompletedMinutes': studyCompletedMinutes,
      'lastStudiedAt': lastStudiedAtMs,
      'nextReviewDate': nextReviewDateIso,
      'plannedDate': plannedDateIso,
      'orderIndex': orderIndex,
      'origin': origin == StudyOrigin.konkurPreset ? 'KONKUR_PRESET' : 'USER',
      'chapter': chapter,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class StudySession {
  const StudySession({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.durationMinutes,
    required this.dateIso,
    this.mode = StudyMode.learn,
    this.source = 'MANUAL',
    this.startedAtMs,
    this.endedAtMs,
    this.quality,
    this.note,
    required this.createdAtMs,
  });

  final String id;
  final String subjectId;
  final String? topicId;
  final int durationMinutes;
  final String dateIso;
  final StudyMode mode;
  final String source;
  final int? startedAtMs;
  final int? endedAtMs;
  final int? quality;
  final String? note;
  final int createdAtMs;

  factory StudySession.fromMap(Map<String, dynamic> map) {
    final modeStr = map['mode'] as String? ?? 'LEARN';
    StudyMode m = StudyMode.learn;
    if (modeStr == 'PRACTICE' || modeStr == 'TEST') m = StudyMode.practice;
    if (modeStr == 'REVIEW') m = StudyMode.review;

    return StudySession(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String? ?? '',
      topicId: map['topicId'] as String?,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      dateIso: map['dateIso'] as String? ?? '',
      mode: m,
      source: map['source'] as String? ?? 'MANUAL',
      startedAtMs: map['startedAtMs'] as int?,
      endedAtMs: map['endedAtMs'] as int?,
      quality: map['quality'] as int?,
      note: map['note'] as String?,
      createdAtMs: map['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    String mStr = 'LEARN';
    if (mode == StudyMode.practice) mStr = 'PRACTICE';
    if (mode == StudyMode.review) mStr = 'REVIEW';

    return {
      'id': id,
      'subjectId': subjectId,
      'topicId': topicId,
      'durationMinutes': durationMinutes,
      'dateIso': dateIso,
      'mode': mStr,
      'source': source,
      'startedAtMs': startedAtMs,
      'endedAtMs': endedAtMs,
      'quality': quality,
      'note': note,
      'createdAt': createdAtMs,
    };
  }
}

class ActiveStudySessionState {
  const ActiveStudySessionState({
    required this.id,
    this.subjectId,
    this.topicId,
    this.mode = StudyMode.learn,
    required this.startedAtMs,
    this.accumulatedSeconds = 0,
    this.isPaused = false,
    this.plannedMinutes,
    required this.createdAtMs,
  });

  final String id;
  final String? subjectId;
  final String? topicId;
  final StudyMode mode;
  final int startedAtMs;
  final int accumulatedSeconds;
  final bool isPaused;
  final int? plannedMinutes;
  final int createdAtMs;

  int elapsedSeconds(int nowMs) {
    if (isPaused) {
      return accumulatedSeconds;
    }
    final runSec = ((nowMs - startedAtMs) / 1000).floor();
    return accumulatedSeconds + (runSec > 0 ? runSec : 0);
  }

  factory ActiveStudySessionState.fromMap(Map<String, dynamic> map) {
    final modeStr = map['mode'] as String? ?? 'LEARN';
    StudyMode m = StudyMode.learn;
    if (modeStr == 'PRACTICE') m = StudyMode.practice;
    if (modeStr == 'REVIEW') m = StudyMode.review;

    return ActiveStudySessionState(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String?,
      topicId: map['topicId'] as String?,
      mode: m,
      startedAtMs: map['startedAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      accumulatedSeconds: map['accumulatedSeconds'] as int? ?? 0,
      isPaused: (map['isPaused'] as int? ?? 0) == 1,
      plannedMinutes: map['plannedMinutes'] as int?,
      createdAtMs: map['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    String mStr = 'LEARN';
    if (mode == StudyMode.practice) mStr = 'PRACTICE';
    if (mode == StudyMode.review) mStr = 'REVIEW';

    return {
      'id': 'singleton',
      'subjectId': subjectId,
      'topicId': topicId,
      'mode': mStr,
      'startedAtMs': startedAtMs,
      'accumulatedSeconds': accumulatedSeconds,
      'isPaused': isPaused ? 1 : 0,
      'plannedMinutes': plannedMinutes,
      'createdAt': createdAtMs,
    };
  }
}
