enum InsightType {
  learningGrowth,
  healthDecline,
  morningLead,
  fatigueWarning,
  productiveWeekday,
  gatheringData
}

class InsightResult {

  InsightResult({
    required this.type,
    required this.params,
    required this.sourceMetric,
    required this.calculationWindow,
  });
  final InsightType type;
  final Map<String, dynamic> params;
  final String sourceMetric;
  final String calculationWindow;
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
