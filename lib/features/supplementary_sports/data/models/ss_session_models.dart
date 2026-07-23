import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';

class WorkoutSessionLog {

  WorkoutSessionLog({
    required this.id,
    this.planId,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds = 0,
    this.completedExercisesCount = 0,
    this.totalExercisesCount = 0,
    this.overallFeeling,
    this.note,
  });

  factory WorkoutSessionLog.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionLog(
      id: map['id']?.toString() ?? '',
      planId: map['planId']?.toString(),
      startedAt: map['startedAt'] as int? ?? 0,
      finishedAt: map['finishedAt'] as int?,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      completedExercisesCount: map['completedExercisesCount'] as int? ?? 0,
      totalExercisesCount: map['totalExercisesCount'] as int? ?? 0,
      overallFeeling: _stringToFeeling(map['overallFeeling']?.toString()),
      note: map['note']?.toString(),
    );
  }
  final String id;
  final String? planId;
  final int startedAt;
  final int? finishedAt;
  final int durationSeconds;
  final int completedExercisesCount;
  final int totalExercisesCount;
  final Feeling? overallFeeling;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'startedAt': startedAt,
      'finishedAt': finishedAt,
      'durationSeconds': durationSeconds,
      'completedExercisesCount': completedExercisesCount,
      'totalExercisesCount': totalExercisesCount,
      'overallFeeling': overallFeeling != null ? _feelingToString(overallFeeling!) : null,
      'note': note,
    };
  }
}

class ExerciseFeelingLog {

  ExerciseFeelingLog({
    required this.id,
    required this.sessionLogId,
    required this.exerciseId,
    required this.feeling,
    required this.loggedAt,
  });

  factory ExerciseFeelingLog.fromMap(Map<String, dynamic> map) {
    return ExerciseFeelingLog(
      id: map['id']?.toString() ?? '',
      sessionLogId: map['sessionLogId']?.toString() ?? '',
      exerciseId: map['exerciseId']?.toString() ?? '',
      feeling: _stringToFeeling(map['feeling']?.toString()) ?? Feeling.good,
      loggedAt: map['loggedAt'] as int? ?? 0,
    );
  }
  final String id;
  final String sessionLogId;
  final String exerciseId;
  final Feeling feeling;
  final int loggedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionLogId': sessionLogId,
      'exerciseId': exerciseId,
      'feeling': _feelingToString(feeling),
      'loggedAt': loggedAt,
    };
  }
}

class ExerciseReadyForIncrease {

  ExerciseReadyForIncrease({
    required this.exerciseId,
    required this.exerciseName,
    required this.consecutiveEasyWeeks,
  });
  final String exerciseId;
  final String exerciseName;
  final int consecutiveEasyWeeks;
}

class DecisionLog {

  DecisionLog({
    required this.id,
    this.userId = 'default',
    this.sessionId,
    this.exerciseId,
    required this.decisionType,
    this.rejectionReason,
    required this.createdAt,
  });

  factory DecisionLog.fromMap(Map<String, dynamic> map) {
    return DecisionLog(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'default',
      sessionId: map['sessionId']?.toString(),
      exerciseId: map['exerciseId']?.toString(),
      decisionType: map['decisionType']?.toString() ?? '',
      rejectionReason: map['rejectionReason']?.toString(),
      createdAt: map['createdAt'] as int? ?? 0,
    );
  }
  final String id;
  final String userId;
  final String? sessionId;
  final String? exerciseId;
  final String decisionType; // «AI پیشنهاد داد» | «کاربر رد کرد» | «برنامه بازسازی شد»
  final String? rejectionReason;
  final int createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'decisionType': decisionType,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }
}

// --- Enum mapping helpers ---

String _feelingToString(Feeling feeling) {
  switch (feeling) {
    case Feeling.easy: return 'EASY';
    case Feeling.good: return 'GOOD';
    case Feeling.hard: return 'HARD';
  }
}

Feeling? _stringToFeeling(String? val) {
  if (val == null) return null;
  switch (val.toUpperCase()) {
    case 'EASY': return Feeling.easy;
    case 'GOOD': return Feeling.good;
    case 'HARD': return Feeling.hard;
    default: return null;
  }
}
