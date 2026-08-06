enum InsightType {
  learningGrowth,
  healthDecline,
  morningLead,
  fatigueWarning,
  productiveWeekday,
  gatheringData,
  sleepEnergyCorrelation,
  sleepMoodCorrelation,
  energyCompletionLink,
  consistencyScore,
  bestDomainOfWeek,
  streakHighlight,
  goalProgress,
  worshipConsistency,
  noisyDataSuppressed,
}

class InsightResult {

  InsightResult({
    required this.type,
    required this.params,
    required this.sourceMetric,
    required this.calculationWindow,
    this.strength = 0.0,
    this.severity = 'INFO',
    this.actionType,
    this.linkModule,
    this.actionParams,
  });
  final InsightType type;
  final Map<String, dynamic> params;
  final String sourceMetric;
  final String calculationWindow;
  final double strength;
  final String severity;
  final String? actionType;
  final String? linkModule;
  final Map<String, dynamic>? actionParams;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'params': params,
    'sourceMetric': sourceMetric,
    'calculationWindow': calculationWindow,
    'strength': strength,
    'severity': severity,
    if (actionType != null) 'actionType': actionType,
    if (linkModule != null) 'linkModule': linkModule,
    if (actionParams != null) 'actionParams': actionParams,
  };

  factory InsightResult.fromMap(Map<String, dynamic> map) {
    return InsightResult(
      type: InsightType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InsightType.gatheringData,
      ),
      params: Map<String, dynamic>.from(map['params'] as Map? ?? {}),
      sourceMetric: map['sourceMetric']?.toString() ?? '',
      calculationWindow: map['calculationWindow']?.toString() ?? '',
      strength: (map['strength'] as num?)?.toDouble() ?? 0.0,
      severity: map['severity']?.toString() ?? 'INFO',
      actionType: map['actionType']?.toString(),
      linkModule: map['linkModule']?.toString(),
      actionParams: map['actionParams'] != null ? Map<String, dynamic>.from(map['actionParams'] as Map) : null,
    );
  }
}

enum ContextExplanationType {
  rest,
  essential,
  sick,
  exam,
  busy,
  worship,
  zone,
  lowEnergy,
  dynamic,
  reflectionAware,
}

class ContextExplanation {

  ContextExplanation({
    required this.type,
    this.params = const {},
  });
  final ContextExplanationType type;
  final Map<String, dynamic> params;
}

enum HormonalPhase {
  menstrual,
  preCycle,
  postCycle,
  normal,
  noData,
  disabled,
}
