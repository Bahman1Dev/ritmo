class SymptomStat {

  SymptomStat({
    required this.key,
    required this.count,
    required this.typicalCycleDay,
  });
  final String key;
  final int count;
  final int typicalCycleDay;
}

class CycleTrendPoint {

  CycleTrendPoint({
    required this.index,
    required this.lengthDays,
    required this.periodDays,
  });
  final int index;
  final int lengthDays;
  final int periodDays;
}

class CycleCorrelation {

  CycleCorrelation({
    required this.metric,
    this.coefficient,
    required this.insight,
  });
  final String metric;
  final double? coefficient;
  final String insight;
}

class FastingDebt {

  FastingDebt({
    required this.id,
    required this.dateIso,
    required this.daysOwed,
    this.reason,
    required this.isResolved,
  });

  factory FastingDebt.fromMap(Map<String, dynamic> map) {
    return FastingDebt(
      id: map['id'] as String,
      dateIso: map['dateIso'] as String,
      daysOwed: map['daysOwed'] as int? ?? 1,
      reason: map['reason'] as String?,
      isResolved: (map['isResolved'] as int? ?? 0) == 1,
    );
  }
  final String id;
  final String dateIso;
  final int daysOwed;
  final String? reason;
  final bool isResolved;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateIso': dateIso,
      'daysOwed': daysOwed,
      'reason': reason,
      'isResolved': isResolved ? 1 : 0,
    };
  }
}

class BodyRhythmInfluence {

  BodyRhythmInfluence({
    required this.energyDelta,
    required this.indirectMessage,
  });
  final double energyDelta;
  final String indirectMessage;
}
