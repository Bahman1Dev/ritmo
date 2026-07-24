// lib/features/sports/movement/domain/movement_kind.dart

enum MovementFamily {
  endurance('ENDURANCE', 'هوازی و استقامتی', '🏃'),
  sport('SPORT', 'ورزش و بازی‌های توپی', '⚽'),
  mindBody('MIND_BODY', 'ذهن و بدن', '🧘'),
  outdoor('OUTDOOR', 'طبیعت و فضای باز', '🏔'),
  martialSkill('MARTIAL_SKILL', 'رزمی و مهارت بدنی', '🥋'),
  daily('DAILY', 'فعالیت‌های روزمره', '🚶'),
  strength('STRENGTH', 'قدرتی و بدنسازی', '🏋️');

  const MovementFamily(this.code, this.titleFa, this.emoji);
  final String code;
  final String titleFa;
  final String emoji;

  static MovementFamily fromCode(String code) {
    return MovementFamily.values.firstWhere(
      (f) => f.code.toUpperCase() == code.toUpperCase(),
      orElse: () => MovementFamily.endurance,
    );
  }
}

enum MovementMetric {
  duration('DURATION', 'دقیقه'),
  distance('DISTANCE', 'کیلومتر'),
  laps('LAPS', 'دور/طول'),
  elevation('ELEVATION', 'متر ارتفاع'),
  steps('STEPS', 'گام'),
  sets('SETS', 'ست'),
  none('NONE', '');

  const MovementMetric(this.code, this.unitFa);
  final String code;
  final String unitFa;

  static MovementMetric fromCode(String code) {
    return MovementMetric.values.firstWhere(
      (m) => m.code.toUpperCase() == code.toUpperCase(),
      orElse: () => MovementMetric.duration,
    );
  }
}

enum MovementIntensity {
  low('LOW', 'سبک', 0.8),
  medium('MEDIUM', 'متوسط', 1.0),
  high('HIGH', 'شدید', 1.25);

  const MovementIntensity(this.code, this.titleFa, this.metMultiplier);
  final String code;
  final String titleFa;
  final double metMultiplier;

  static MovementIntensity fromCode(String code) {
    return MovementIntensity.values.firstWhere(
      (i) => i.code.toUpperCase() == code.toUpperCase(),
      orElse: () => MovementIntensity.medium,
    );
  }
}

class MovementKind {
  const MovementKind({
    required this.code,
    required this.titleFa,
    required this.emoji,
    required this.family,
    required this.baseMet,
    required this.metLow,
    required this.metHigh,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.isOutdoor,
    required this.isSocial,
    required this.needsVenue,
    this.seasonMask,
    required this.jointImpact,
    this.aliasesFa,
    required this.isCustom,
    required this.isEnabled,
    required this.usageCount,
    this.lastUsedAt,
    required this.sortOrder,
  });

  final String code;
  final String titleFa;
  final String emoji;
  final MovementFamily family;
  final double baseMet;
  final double metLow;
  final double metHigh;
  final MovementMetric primaryMetric;
  final MovementMetric secondaryMetric;
  final bool isOutdoor;
  final bool isSocial;
  final bool needsVenue;
  final String? seasonMask;
  final int jointImpact;
  final String? aliasesFa;
  final bool isCustom;
  final bool isEnabled;
  final int usageCount;
  final int? lastUsedAt;
  final int sortOrder;

  factory MovementKind.fromMap(Map<String, dynamic> map) {
    return MovementKind(
      code: map['code'] as String,
      titleFa: map['titleFa'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🏃',
      family: MovementFamily.fromCode(map['family'] as String? ?? 'ENDURANCE'),
      baseMet: (map['baseMet'] as num? ?? 4.0).toDouble(),
      metLow: (map['metLow'] as num? ?? 3.0).toDouble(),
      metHigh: (map['metHigh'] as num? ?? 6.0).toDouble(),
      primaryMetric: MovementMetric.fromCode(map['primaryMetric'] as String? ?? 'DURATION'),
      secondaryMetric: MovementMetric.fromCode(map['secondaryMetric'] as String? ?? 'NONE'),
      isOutdoor: (map['isOutdoor'] as int? ?? 0) == 1,
      isSocial: (map['isSocial'] as int? ?? 0) == 1,
      needsVenue: (map['needsVenue'] as int? ?? 0) == 1,
      seasonMask: map['seasonMask'] as String?,
      jointImpact: (map['jointImpact'] as int? ?? 1),
      aliasesFa: map['aliasesFa'] as String?,
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
      isEnabled: (map['isEnabled'] as int? ?? 1) == 1,
      usageCount: (map['usageCount'] as int? ?? 0),
      lastUsedAt: map['lastUsedAt'] as int?,
      sortOrder: (map['sortOrder'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'titleFa': titleFa,
      'emoji': emoji,
      'family': family.code,
      'baseMet': baseMet,
      'metLow': metLow,
      'metHigh': metHigh,
      'primaryMetric': primaryMetric.code,
      'secondaryMetric': secondaryMetric.code,
      'isOutdoor': isOutdoor ? 1 : 0,
      'isSocial': isSocial ? 1 : 0,
      'needsVenue': needsVenue ? 1 : 0,
      'seasonMask': seasonMask,
      'jointImpact': jointImpact,
      'aliasesFa': aliasesFa,
      'isCustom': isCustom ? 1 : 0,
      'isEnabled': isEnabled ? 1 : 0,
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt,
      'sortOrder': sortOrder,
    };
  }
}
