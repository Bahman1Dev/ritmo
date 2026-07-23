import 'dart:convert';

enum DayStatus { completed, today, upcoming, rest }

class WorkoutPlan {

  WorkoutPlan({
    required this.id,
    required this.dayOfWeek,
    required this.muscleGroups,
    this.estimatedMinutes = 45,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    final muscleGroupsRaw = map['muscleGroups'] != null
        ? jsonDecode(map['muscleGroups'] as String) as List<dynamic>
        : [];
    return WorkoutPlan(
      id: map['id']?.toString() ?? '',
      dayOfWeek: map['dayOfWeek'] as int? ?? 1,
      muscleGroups: muscleGroupsRaw.map((e) => e.toString()).toList(),
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 45,
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
    );
  }
  final String id;
  final int dayOfWeek; // 1 = Saturday, 7 = Friday
  final List<String> muscleGroups;
  final int estimatedMinutes;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'muscleGroups': jsonEncode(muscleGroups),
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WorkoutExerciseCrossRef {

  WorkoutExerciseCrossRef({
    required this.id,
    required this.planId,
    required this.exerciseId,
    required this.orderIndex,
    this.difficultyOffset = 0.0,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight,
  });

  factory WorkoutExerciseCrossRef.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseCrossRef(
      id: map['id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? '',
      exerciseId: map['exerciseId']?.toString() ?? '',
      orderIndex: map['orderIndex'] as int? ?? 0,
      difficultyOffset: (map['difficultyOffset'] as num?)?.toDouble() ?? 0.0,
      targetSets: map['targetSets'] as int? ?? 3,
      targetReps: map['targetReps'] as int? ?? 10,
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
    );
  }
  final String id;
  final String planId;
  final String exerciseId;
  final int orderIndex;
  final double difficultyOffset;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'difficultyOffset': difficultyOffset,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
    };
  }
}

class PlanDaySummary {

  PlanDaySummary({
    required this.id,
    required this.dayName,
    required this.muscleGroups,
    required this.status,
  });
  final String id;
  final String dayName; // شنبه، یکشنبه، ...
  final String muscleGroups; // پا، سینه، ...
  final DayStatus status;
}

class PlanVersionHistory {

  PlanVersionHistory({
    required this.id,
    required this.serializedPlan,
    this.changeReason,
    required this.createdAt,
  });

  factory PlanVersionHistory.fromMap(Map<String, dynamic> map) {
    return PlanVersionHistory(
      id: map['id']?.toString() ?? '',
      serializedPlan: map['serializedPlan']?.toString() ?? '',
      changeReason: map['changeReason']?.toString(),
      createdAt: map['createdAt'] as int? ?? 0,
    );
  }
  final String id;
  final String serializedPlan; // JSON dump of the entire plan state at that time
  final String? changeReason; // «تغییر دستی» | «پیشنهاد AI پذیرفته شد»
  final int createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serializedPlan': serializedPlan,
      'changeReason': changeReason,
      'createdAt': createdAt,
    };
  }
}
