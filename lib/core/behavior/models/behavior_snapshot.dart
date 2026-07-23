// ignore_for_file: constant_identifier_names

enum TrendDirection { UP, DOWN, STABLE, VOLATILE }

enum HabitStage { NEW, BUILDING, STABLE, STRONG, AUTOMATIC }

enum EvidenceLevel { UNKNOWN, LOW, MEDIUM, HIGH }

enum SuggestionStyle { DIRECT, GENTLE, ANALYTICAL, MOTIVATIONAL }

enum SuggestionFrequency { LOW, NORMAL, HIGH }

enum SuggestionComplexity { SHORT, MEDIUM, LONG }

enum DecisionStyle { QUICK, BALANCED, ANALYTICAL }

enum PlanningStyle { SPONTANEOUS, HYBRID, STRUCTURED }

enum MotivationStyle { EXTERNAL, INTERNAL, MIXED }

enum RoutineStyle { FLEXIBLE, STABLE, RIGID }

class HistoricalBehaviorSummary {

  HistoricalBehaviorSummary({
    required this.routineCompletion30d,
    required this.routineCompletion90d,
    required this.averageEnergy,
    required this.averageSleep,
    required this.rhythmAverage,
    required this.studyAverage,
    required this.consistencyScore,
    required this.strongestHabits,
    required this.weakestHabits,
  });
  final double routineCompletion30d;
  final double routineCompletion90d;
  final double averageEnergy;
  final double averageSleep;
  final double rhythmAverage;
  final double studyAverage;
  final double consistencyScore;
  final List<String> strongestHabits;
  final List<String> weakestHabits;

  Map<String, dynamic> toJson() => {
    'routineCompletion30d': routineCompletion30d,
    'routineCompletion90d': routineCompletion90d,
    'averageEnergy': averageEnergy,
    'averageSleep': averageSleep,
    'rhythmAverage': rhythmAverage,
    'studyAverage': studyAverage,
    'consistencyScore': consistencyScore,
    'strongestHabits': strongestHabits,
    'weakestHabits': weakestHabits,
  };
}

class PersonalBaseline {

  PersonalBaseline({
    required this.avgSleep,
    required this.avgEnergy,
    required this.avgRhythm,
    required this.avgStudy,
    required this.avgReflection,
    required this.avgPrayer,
    required this.avgWorkout,
  });
  final double avgSleep;
  final double avgEnergy;
  final double avgRhythm;
  final double avgStudy;
  final double avgReflection;
  final double avgPrayer;
  final double avgWorkout;

  Map<String, dynamic> toJson() => {
    'avgSleep': avgSleep,
    'avgEnergy': avgEnergy,
    'avgRhythm': avgRhythm,
    'avgStudy': avgStudy,
    'avgReflection': avgReflection,
    'avgPrayer': avgPrayer,
    'avgWorkout': avgWorkout,
  };
}

class TrendSummary {

  TrendSummary({
    required this.energy,
    required this.sleep,
    required this.rhythm,
    required this.study,
    required this.goals,
  });
  final TrendDirection energy;
  final TrendDirection sleep;
  final TrendDirection rhythm;
  final TrendDirection study;
  final TrendDirection goals;

  Map<String, dynamic> toJson() => {
    'energy': energy.name,
    'sleep': sleep.name,
    'rhythm': rhythm.name,
    'study': study.name,
    'goals': goals.name,
  };
}

class HabitStrength {

  HabitStrength({
    required this.routineId,
    required this.routineTitle,
    required this.strengthScore,
    required this.stage,
    required this.completionRate,
    required this.streakScore,
    required this.consistencyScore,
    required this.reminderDependency,
    required this.resilienceScore,
  });
  final String routineId;
  final String routineTitle;
  final double strengthScore;
  final HabitStage stage;
  final double completionRate;
  final double streakScore;
  final double consistencyScore;
  final double reminderDependency;
  final double resilienceScore;

  Map<String, dynamic> toJson() => {
    'routineId': routineId,
    'routineTitle': routineTitle,
    'strengthScore': strengthScore,
    'stage': stage.name,
    'completionRate': completionRate,
    'streakScore': streakScore,
    'consistencyScore': consistencyScore,
    'reminderDependency': reminderDependency,
    'resilienceScore': resilienceScore,
  };
}

class HabitStrengthSummary {

  HabitStrengthSummary({required this.items});
  final List<HabitStrength> items;

  List<Map<String, dynamic>> toJson() => items.map((h) => h.toJson()).toList();
}

class PreferredWindow {

  PreferredWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.confidence,
  });
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double confidence;

  Map<String, dynamic> toJson() => {
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'confidence': confidence,
  };
}

class TimePreferenceSummary {

  TimePreferenceSummary({required this.windows});
  final Map<String, PreferredWindow> windows;

  Map<String, dynamic> toJson() => windows.map((k, v) => MapEntry(k, v.toJson()));
}

class BehaviorChain {

  BehaviorChain({
    required this.events,
    required this.confidence,
    required this.observations,
  });
  final List<String> events;
  final double confidence;
  final int observations;

  Map<String, dynamic> toJson() => {
    'events': events,
    'confidence': confidence,
    'observations': observations,
  };
}

class BehavioralSequenceSummary {

  BehavioralSequenceSummary({required this.chains});
  final List<BehaviorChain> chains;

  Map<String, dynamic> toJson() => {
    'chains': chains.map((c) => c.toJson()).toList(),
  };
}

class EvidenceConfidenceSummary {

  EvidenceConfidenceSummary({
    required this.level,
    required this.score,
    required this.observations,
    required this.completeness,
    required this.freshness,
    required this.consistency,
    required this.limitations,
  });
  final EvidenceLevel level;
  final double score;
  final int observations;
  final double completeness;
  final double freshness;
  final double consistency;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'score': score,
    'observations': observations,
    'completeness': completeness,
    'freshness': freshness,
    'consistency': consistency,
    'limitations': limitations,
  };
}

class MissingData {

  MissingData({
    required this.domain,
    required this.reason,
    required this.requiredSamples,
    required this.currentSamples,
  });
  final String domain;
  final String reason;
  final int requiredSamples;
  final int currentSamples;

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'reason': reason,
    'requiredSamples': requiredSamples,
    'currentSamples': currentSamples,
  };
}

class SparseDataSummary {

  SparseDataSummary({
    required this.enoughSleep,
    required this.enoughEnergy,
    required this.enoughRoutine,
    required this.enoughGoals,
    required this.enoughStudy,
    required this.enoughReflection,
    required this.enoughPrayer,
    required this.missing,
  });
  final bool enoughSleep;
  final bool enoughEnergy;
  final bool enoughRoutine;
  final bool enoughGoals;
  final bool enoughStudy;
  final bool enoughReflection;
  final bool enoughPrayer;
  final List<MissingData> missing;

  Map<String, dynamic> toJson() => {
    'enoughSleep': enoughSleep,
    'enoughEnergy': enoughEnergy,
    'enoughRoutine': enoughRoutine,
    'enoughGoals': enoughGoals,
    'enoughStudy': enoughStudy,
    'enoughReflection': enoughReflection,
    'enoughPrayer': enoughPrayer,
    'missing': missing.map((m) => m.toJson()).toList(),
  };
}

class AdaptiveSuggestionProfile {

  AdaptiveSuggestionProfile({
    required this.style,
    required this.frequency,
    required this.complexity,
  });
  final SuggestionStyle style;
  final SuggestionFrequency frequency;
  final SuggestionComplexity complexity;

  Map<String, dynamic> toJson() => {
    'style': style.name,
    'frequency': frequency.name,
    'complexity': complexity.name,
  };
}

class PersonalBehaviorProfile {

  PersonalBehaviorProfile({
    required this.version,
    required this.decisionStyle,
    required this.planningStyle,
    required this.motivationStyle,
    required this.routineStyle,
  });
  final String version;
  final DecisionStyle decisionStyle;
  final PlanningStyle planningStyle;
  final MotivationStyle motivationStyle;
  final RoutineStyle routineStyle;

  Map<String, dynamic> toJson() => {
    'version': version,
    'decisionStyle': decisionStyle.name,
    'planningStyle': planningStyle.name,
    'motivationStyle': motivationStyle.name,
    'routineStyle': routineStyle.name,
  };
}

class RecurringTopic {

  RecurringTopic({
    required this.topic,
    required this.count,
    required this.lastMention,
  });
  final String topic;
  final int count;
  final DateTime lastMention;

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'count': count,
    'lastMention': lastMention.toIso8601String(),
  };
}

class PersonalVictory {

  PersonalVictory({required this.title, required this.date});
  final String title;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
  };
}

class RecurringProblem {

  RecurringProblem({required this.problem, required this.count});
  final String problem;
  final int count;

  Map<String, dynamic> toJson() => {
    'problem': problem,
    'count': count,
  };
}

class Commitment {

  Commitment({required this.domain, required this.promise});
  final String domain;
  final String promise;

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'promise': promise,
  };
}

class ReflectionMemorySummary {

  ReflectionMemorySummary({
    required this.recurringTopics,
    required this.victories,
    required this.recurringProblems,
    required this.commitments,
  });
  final List<RecurringTopic> recurringTopics;
  final List<PersonalVictory> victories;
  final List<RecurringProblem> recurringProblems;
  final List<Commitment> commitments;

  Map<String, dynamic> toJson() => {
    'recurringTopics': recurringTopics.map((t) => t.toJson()).toList(),
    'victories': victories.map((v) => v.toJson()).toList(),
    'recurringProblems': recurringProblems.map((p) => p.toJson()).toList(),
    'commitments': commitments.map((c) => c.toJson()).toList(),
  };
}

class BehavioralFingerprint {

  BehavioralFingerprint({
    required this.fingerprintVersion,
    required this.stabilityScore,
    required this.consistencyScore,
    required this.adaptabilityScore,
    required this.routineStrength,
    required this.planningStrength,
    required this.resilienceScore,
    required this.selfAwarenessScore,
    required this.strongestPatterns,
    required this.emergingPatterns,
    required this.unstablePatterns,
  });
  final String fingerprintVersion;
  final double stabilityScore;
  final double consistencyScore;
  final double adaptabilityScore;
  final double routineStrength;
  final double planningStrength;
  final double resilienceScore;
  final double selfAwarenessScore;
  final List<String> strongestPatterns;
  final List<String> emergingPatterns;
  final List<String> unstablePatterns;

  Map<String, dynamic> toJson() => {
    'fingerprintVersion': fingerprintVersion,
    'stabilityScore': stabilityScore,
    'consistencyScore': consistencyScore,
    'adaptabilityScore': adaptabilityScore,
    'routineStrength': routineStrength,
    'planningStrength': planningStrength,
    'resilienceScore': resilienceScore,
    'selfAwarenessScore': selfAwarenessScore,
    'strongestPatterns': strongestPatterns,
    'emergingPatterns': emergingPatterns,
    'unstablePatterns': unstablePatterns,
  };
}

class BehavioralSnapshot {

  BehavioralSnapshot({
    required this.historical,
    required this.baseline,
    required this.trends,
    required this.habits,
    required this.timePreferences,
    required this.sequences,
    required this.evidence,
    required this.sparseData,
    required this.adaptiveSuggestions,
    required this.profile,
    required this.reflections,
    required this.fingerprint,
    required this.generatedAt,
    required this.engineVersion,
    required this.snapshotVersion,
    required this.behaviorHash,
  });
  final HistoricalBehaviorSummary historical;
  final PersonalBaseline baseline;
  final TrendSummary trends;
  final HabitStrengthSummary habits;
  final TimePreferenceSummary timePreferences;
  final BehavioralSequenceSummary sequences;
  final EvidenceConfidenceSummary evidence;
  final SparseDataSummary sparseData;
  final AdaptiveSuggestionProfile adaptiveSuggestions;
  final PersonalBehaviorProfile profile;
  final ReflectionMemorySummary reflections;
  final BehavioralFingerprint fingerprint;
  final DateTime generatedAt;
  final int engineVersion;
  final String snapshotVersion;
  final int behaviorHash;

  Map<String, dynamic> toJson() => {
    'snapshotVersion': snapshotVersion,
    'engineVersion': engineVersion,
    'generatedAt': generatedAt.toIso8601String(),
    'behaviorHash': behaviorHash,
    'historical': historical.toJson(),
    'baseline': baseline.toJson(),
    'trends': trends.toJson(),
    'habits': habits.toJson(),
    'timePreferences': timePreferences.toJson(),
    'sequences': sequences.toJson(),
    'evidence': evidence.toJson(),
    'sparseData': sparseData.toJson(),
    'adaptiveSuggestions': adaptiveSuggestions.toJson(),
    'profile': profile.toJson(),
    'reflections': reflections.toJson(),
    'fingerprint': fingerprint.toJson(),
  };
}
