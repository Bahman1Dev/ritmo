
import 'dart:convert';

enum KonkurField {
  riyazi,
  tajrobi,
  ensani,
  honar,
  zaban;

  String get code {
    switch (this) {
      case KonkurField.riyazi:
        return 'RIYAZI';
      case KonkurField.tajrobi:
        return 'TAJROBI';
      case KonkurField.ensani:
        return 'ENSANI';
      case KonkurField.honar:
        return 'HONAR';
      case KonkurField.zaban:
        return 'ZABAN';
    }
  }

  String get label {
    switch (this) {
      case KonkurField.riyazi:
        return 'ریاضی و فیزیک';
      case KonkurField.tajrobi:
        return 'علوم تجربی';
      case KonkurField.ensani:
        return 'علوم انسانی';
      case KonkurField.honar:
        return 'هنر';
      case KonkurField.zaban:
        return 'زبان‌های خارجی';
    }
  }

  static KonkurField fromString(String val) {
    switch (val.toUpperCase()) {
      case 'RIYAZI':
      case 'MATHEMATICS':
        return KonkurField.riyazi;
      case 'TAJROBI':
      case 'EXPERIMENTAL':
        return KonkurField.tajrobi;
      case 'ENSANI':
      case 'HUMANITIES':
        return KonkurField.ensani;
      case 'HONAR':
      case 'ART':
        return KonkurField.honar;
      case 'ZABAN':
      case 'LANGUAGE':
        return KonkurField.zaban;
      default:
        return KonkurField.riyazi;
    }
  }
}

enum MasteryLevel {
  notStarted,
  learning,
  needsReview,
  mastered;

  String get code {
    switch (this) {
      case MasteryLevel.notStarted:
        return 'NOT_STARTED';
      case MasteryLevel.learning:
        return 'LEARNING';
      case MasteryLevel.needsReview:
        return 'NEEDS_REVIEW';
      case MasteryLevel.mastered:
        return 'MASTERED';
    }
  }

  String get label {
    switch (this) {
      case MasteryLevel.notStarted:
        return 'نخوانده';
      case MasteryLevel.learning:
        return 'در حال یادگیری';
      case MasteryLevel.needsReview:
        return 'نیاز به مرور';
      case MasteryLevel.mastered:
        return 'مسلط';
    }
  }

  String get emoji {
    switch (this) {
      case MasteryLevel.notStarted:
        return '⚪';
      case MasteryLevel.learning:
        return '🔵';
      case MasteryLevel.needsReview:
        return '🟡';
      case MasteryLevel.mastered:
        return '🟢';
    }
  }

  double get score {
    switch (this) {
      case MasteryLevel.notStarted:
        return 0;
      case MasteryLevel.learning:
        return 0.5;
      case MasteryLevel.needsReview:
        return 0.7;
      case MasteryLevel.mastered:
        return 1;
    }
  }

  static MasteryLevel fromString(String val) {
    switch (val.toUpperCase()) {
      case 'NOT_STARTED':
        return MasteryLevel.notStarted;
      case 'LEARNING':
        return MasteryLevel.learning;
      case 'NEEDS_REVIEW':
        return MasteryLevel.needsReview;
      case 'MASTERED':
        return MasteryLevel.mastered;
      default:
        return MasteryLevel.notStarted;
    }
  }
}

class KonkurSubject {

  KonkurSubject({
    required this.id,
    required this.name,
    this.importanceFactor = 1.0,
    this.progressPercentage = 0.0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.subjectGroup = 'SPECIALIZED',
    this.examQuestionCount = 0,
    this.orderIndex = 0,
    this.colorHex,
    this.isPreset = false,
  });

  factory KonkurSubject.fromMap(Map<String, dynamic> map) {
    return KonkurSubject(
      id: map['id'] as String,
      name: map['name'] as String,
      importanceFactor: (map['importanceFactor'] as num?)?.toDouble() ?? 1.0,
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      isArchived: (map['isArchived'] as int?) == 1,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      subjectGroup: map['subjectGroup'] as String? ?? 'SPECIALIZED',
      examQuestionCount: map['examQuestionCount'] as int? ?? 0,
      orderIndex: map['orderIndex'] as int? ?? 0,
      colorHex: map['colorHex'] as String?,
      isPreset: (map['isPreset'] as int?) == 1,
    );
  }
  final String id;
  final String name;
  final double importanceFactor;
  final double progressPercentage;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
  final String subjectGroup; // GENERAL or SPECIALIZED
  final int examQuestionCount;
  final int orderIndex;
  final String? colorHex;
  final bool isPreset;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'importanceFactor': importanceFactor,
      'progressPercentage': progressPercentage,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'subjectGroup': subjectGroup,
      'examQuestionCount': examQuestionCount,
      'orderIndex': orderIndex,
      'colorHex': colorHex,
      'isPreset': isPreset ? 1 : 0,
    };
  }
}

class KonkurTopic {

  KonkurTopic({
    required this.id,
    required this.subjectId,
    this.parentTopicId,
    required this.name,
    this.progressPercentage = 0.0,
    this.studyTargetMinutes = 0,
    this.studyCompletedMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.examQuestionCount = 0,
    this.masteryLevel = MasteryLevel.notStarted,
    this.lastStudiedAt,
    this.nextReviewDate,
    this.plannedDate,
    this.orderIndex = 0,
    this.prerequisiteTopicIds = const [],
    this.conceptCompletedMinutes = 0,
    this.conceptTargetMinutes = 0,
    this.practiceCompletedMinutes = 0,
    this.practiceTargetMinutes = 0,
    this.reviewCompletedMinutes = 0,
    this.reviewTargetMinutes = 0,
  });

  factory KonkurTopic.fromMap(Map<String, dynamic> map) {
    var prereqs = <String>[];
    final rawPrereq = map['prerequisiteTopicIds'];
    if (rawPrereq != null && rawPrereq is String && rawPrereq.isNotEmpty) {
      try {
        final List parsed = jsonDecode(rawPrereq);
        prereqs = parsed.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return KonkurTopic(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      parentTopicId: map['parentTopicId'] as String?,
      name: map['name'] as String,
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      studyTargetMinutes: map['studyTargetMinutes'] as int? ?? 0,
      studyCompletedMinutes: map['studyCompletedMinutes'] as int? ?? 0,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      examQuestionCount: map['examQuestionCount'] as int? ?? 0,
      masteryLevel: MasteryLevel.fromString(map['masteryLevel'] as String? ?? 'NOT_STARTED'),
      lastStudiedAt: map['lastStudiedAt'] as int?,
      nextReviewDate: map['nextReviewDate'] as String?,
      plannedDate: map['plannedDate'] as String?,
      orderIndex: map['orderIndex'] as int? ?? 0,
      prerequisiteTopicIds: prereqs,
      conceptCompletedMinutes: map['conceptCompletedMinutes'] as int? ?? 0,
      conceptTargetMinutes: map['conceptTargetMinutes'] as int? ?? 0,
      practiceCompletedMinutes: map['practiceCompletedMinutes'] as int? ?? 0,
      practiceTargetMinutes: map['practiceTargetMinutes'] as int? ?? 0,
      reviewCompletedMinutes: map['reviewCompletedMinutes'] as int? ?? 0,
      reviewTargetMinutes: map['reviewTargetMinutes'] as int? ?? 0,
    );
  }
  final String id;
  final String subjectId;
  final String? parentTopicId;
  final String name;
  final double progressPercentage;
  final int studyTargetMinutes;
  final int studyCompletedMinutes;
  final int createdAt;
  final int updatedAt;
  final int examQuestionCount;
  final MasteryLevel masteryLevel;
  final int? lastStudiedAt;
  final String? nextReviewDate; // 'YYYY-MM-DD'
  final String? plannedDate;    // 'YYYY-MM-DD'
  final int orderIndex;
  final List<String> prerequisiteTopicIds;
  final int conceptCompletedMinutes;
  final int conceptTargetMinutes;
  final int practiceCompletedMinutes;
  final int practiceTargetMinutes;
  final int reviewCompletedMinutes;
  final int reviewTargetMinutes;

  bool isDue(DateTime today) {
    if (nextReviewDate == null || nextReviewDate!.isEmpty) return false;
    final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return nextReviewDate!.compareTo(todayStr) <= 0;
  }

  int get weight => examQuestionCount;

  bool get isConceptFinished =>
      conceptTargetMinutes > 0 && conceptCompletedMinutes >= conceptTargetMinutes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'parentTopicId': parentTopicId,
      'name': name,
      'progressPercentage': progressPercentage,
      'studyTargetMinutes': studyTargetMinutes,
      'studyCompletedMinutes': studyCompletedMinutes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'examQuestionCount': examQuestionCount,
      'masteryLevel': masteryLevel.code,
      'lastStudiedAt': lastStudiedAt,
      'nextReviewDate': nextReviewDate,
      'plannedDate': plannedDate,
      'orderIndex': orderIndex,
      'prerequisiteTopicIds': jsonEncode(prerequisiteTopicIds),
      'conceptCompletedMinutes': conceptCompletedMinutes,
      'conceptTargetMinutes': conceptTargetMinutes,
      'practiceCompletedMinutes': practiceCompletedMinutes,
      'practiceTargetMinutes': practiceTargetMinutes,
      'reviewCompletedMinutes': reviewCompletedMinutes,
      'reviewTargetMinutes': reviewTargetMinutes,
    };
  }
}

class KonkurStudySession {

  KonkurStudySession({
    required this.id,
    this.topicId,
    this.subjectId,
    required this.dateIso,
    this.durationMinutes = 0,
    this.mode = 'STUDY',
    this.testsTotal = 0,
    this.testsCorrect = 0,
    this.testsWrong = 0,
    this.testsBlank = 0,
    this.note,
    required this.createdAt,
    this.sessionOutcome,
    this.sessionQuality,
  });

  factory KonkurStudySession.fromMap(Map<String, dynamic> map) {
    return KonkurStudySession(
      id: map['id'] as String,
      topicId: map['topicId'] as String?,
      subjectId: map['subjectId'] as String?,
      dateIso: map['dateIso'] as String,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      mode: map['mode'] as String? ?? 'STUDY',
      testsTotal: map['testsTotal'] as int? ?? 0,
      testsCorrect: map['testsCorrect'] as int? ?? 0,
      testsWrong: map['testsWrong'] as int? ?? 0,
      testsBlank: map['testsBlank'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as int,
      sessionOutcome: map['sessionOutcome'] as String?,
      sessionQuality: map['sessionQuality'] as String?,
    );
  }
  final String id;
  final String? topicId;
  final String? subjectId;
  final String dateIso; // 'YYYY-MM-DD'
  final int durationMinutes;
  final String mode; // STUDY, TEST, REVIEW
  final int testsTotal;
  final int testsCorrect;
  final int testsWrong;
  final int testsBlank;
  final String? note;
  final int createdAt;
  final String? sessionOutcome;
  final String? sessionQuality;

  double get netPercent {
    if (mode != 'TEST') return 0;
    return KonkurMockResult.computeNetPercent(testsCorrect, testsWrong, testsTotal);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topicId': topicId,
      'subjectId': subjectId,
      'dateIso': dateIso,
      'durationMinutes': durationMinutes,
      'mode': mode,
      'testsTotal': testsTotal,
      'testsCorrect': testsCorrect,
      'testsWrong': testsWrong,
      'testsBlank': testsBlank,
      'note': note,
      'createdAt': createdAt,
      'sessionOutcome': sessionOutcome,
      'sessionQuality': sessionQuality,
    };
  }
}

class KonkurMockExam {

  KonkurMockExam({
    required this.id,
    required this.title,
    required this.examDate,
    required this.createdAt,
    this.provider,
    this.note,
  });

  factory KonkurMockExam.fromMap(Map<String, dynamic> map) {
    return KonkurMockExam(
      id: map['id'] as String,
      title: map['title'] as String,
      examDate: map['examDate'] as String,
      createdAt: map['createdAt'] as int,
      provider: map['provider'] as String?,
      note: map['note'] as String?,
    );
  }
  final String id;
  final String title;
  final String examDate; // 'YYYY-MM-DD'
  final int createdAt;
  final String? provider;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'examDate': examDate,
      'createdAt': createdAt,
      'provider': provider,
      'note': note,
    };
  }
}

class KonkurMockResult {

  KonkurMockResult({
    required this.id,
    required this.mockExamId,
    required this.subjectId,
    required this.percentage,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.emptyAnswers = 0,
    required this.createdAt,
    this.totalQuestions = 0,
  });

  factory KonkurMockResult.fromMap(Map<String, dynamic> map) {
    return KonkurMockResult(
      id: map['id'] as String,
      mockExamId: map['mockExamId'] as String,
      subjectId: map['subjectId'] as String,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      correctAnswers: map['correctAnswers'] as int? ?? 0,
      wrongAnswers: map['wrongAnswers'] as int? ?? 0,
      emptyAnswers: map['emptyAnswers'] as int? ?? 0,
      createdAt: map['createdAt'] as int,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
    );
  }
  final String id;
  final String mockExamId;
  final String subjectId;
  final double percentage;
  final int correctAnswers;
  final int wrongAnswers;
  final int emptyAnswers;
  final int createdAt;
  final int totalQuestions;

  static double computeNetPercent(int correct, int wrong, int total) {
    if (total == 0) return 0;
    final score = ((3 * correct) - wrong) / (3 * total) * 100;
    return score > 100.0 ? 100.0 : score;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mockExamId': mockExamId,
      'subjectId': subjectId,
      'percentage': percentage,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'emptyAnswers': emptyAnswers,
      'createdAt': createdAt,
      'totalQuestions': totalQuestions,
    };
  }
}

class KonkurPlanItem {

  KonkurPlanItem({
    required this.id,
    required this.dateIso,
    this.subjectId,
    this.topicId,
    this.plannedMinutes = 0,
    this.status = 'PENDING',
    required this.createdAt,
  });

  factory KonkurPlanItem.fromMap(Map<String, dynamic> map) {
    return KonkurPlanItem(
      id: map['id'] as String,
      dateIso: map['dateIso'] as String,
      subjectId: map['subjectId'] as String?,
      topicId: map['topicId'] as String?,
      plannedMinutes: map['plannedMinutes'] as int? ?? 0,
      status: map['status'] as String? ?? 'PENDING',
      createdAt: map['createdAt'] as int,
    );
  }
  final String id;
  final String dateIso; // 'YYYY-MM-DD'
  final String? subjectId;
  final String? topicId;
  final int plannedMinutes;
  final String status; // PENDING, DONE, SKIPPED
  final int createdAt;

  bool isToday(DateTime today) {
    final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dateIso == todayStr;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateIso': dateIso,
      'subjectId': subjectId,
      'topicId': topicId,
      'plannedMinutes': plannedMinutes,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
