import 'dart:convert';

enum SlotType {
  strength,
  cardio,
  mobility,
  activeRest,
  rest;

  String get code => switch (this) {
    SlotType.strength => 'STRENGTH',
    SlotType.cardio => 'CARDIO',
    SlotType.mobility => 'MOBILITY',
    SlotType.activeRest => 'ACTIVE_REST',
    SlotType.rest => 'REST',
  };

  static SlotType fromCode(String code) => switch (code.toUpperCase()) {
    'STRENGTH' => SlotType.strength,
    'CARDIO' => SlotType.cardio,
    'MOBILITY' => SlotType.mobility,
    'ACTIVE_REST' => SlotType.activeRest,
    _ => SlotType.rest,
  };

  String get labelFa => switch (this) {
    SlotType.strength => 'تمرین قدرتی',
    SlotType.cardio => 'تمرین هوازی',
    SlotType.mobility => 'تحرک و کشش',
    SlotType.activeRest => 'ریکاوری فعال',
    SlotType.rest => 'استراحت',
  };
}

enum IntensityTier {
  light,
  moderate,
  hard;

  String get code => switch (this) {
    IntensityTier.light => 'LIGHT',
    IntensityTier.moderate => 'MODERATE',
    IntensityTier.hard => 'HARD',
  };

  static IntensityTier fromCode(String code) => switch (code.toUpperCase()) {
    'LIGHT' => IntensityTier.light,
    'HARD' => IntensityTier.hard,
    _ => IntensityTier.moderate,
  };

  String get labelFa => switch (this) {
    IntensityTier.light => 'سبک',
    IntensityTier.moderate => 'متوسط',
    IntensityTier.hard => 'سنگین',
  };

  int get targetRpe => switch (this) {
    IntensityTier.light => 4,
    IntensityTier.moderate => 6,
    IntensityTier.hard => 8,
  };

  double get metValue => switch (this) {
    IntensityTier.light => 3.0,
    IntensityTier.moderate => 5.0,
    IntensityTier.hard => 6.5,
  };
}

enum PrescriptionStatus {
  planned,
  done,
  partial,
  skipped,
  moved;

  String get code => switch (this) {
    PrescriptionStatus.planned => 'PLANNED',
    PrescriptionStatus.done => 'DONE',
    PrescriptionStatus.partial => 'PARTIAL',
    PrescriptionStatus.skipped => 'SKIPPED',
    PrescriptionStatus.moved => 'MOVED',
  };

  static PrescriptionStatus fromCode(String code) => switch (code.toUpperCase()) {
    'DONE' => PrescriptionStatus.done,
    'PARTIAL' => PrescriptionStatus.partial,
    'SKIPPED' => PrescriptionStatus.skipped,
    'MOVED' => PrescriptionStatus.moved,
    _ => PrescriptionStatus.planned,
  };

  String get labelFa => switch (this) {
    PrescriptionStatus.planned => 'برنامه‌ریزی شده',
    PrescriptionStatus.done => 'انجام شده',
    PrescriptionStatus.partial => 'انجام بخشی',
    PrescriptionStatus.skipped => 'رد شده',
    PrescriptionStatus.moved => 'جابه‌جا شده',
  };
}

class SessionPrescription {
  const SessionPrescription({
    required this.id,
    required this.dateIso,
    required this.cycleWeek,
    required this.slotType,
    required this.focusCodes,
    required this.targetMinutes,
    required this.intensityTier,
    this.targetRpe,
    required this.headlineFa,
    this.coachNoteFa,
    required this.source,
    this.isLocked = false,
    this.status = PrescriptionStatus.planned,
    this.movedToDateIso,
    this.legacyPlanId,
    this.workoutLogId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String dateIso;
  final int cycleWeek;
  final SlotType slotType;
  final List<String> focusCodes;
  final int targetMinutes;
  final IntensityTier intensityTier;
  final int? targetRpe;
  final String headlineFa;
  final String? coachNoteFa;
  final String source;
  final bool isLocked;
  final PrescriptionStatus status;
  final String? movedToDateIso;
  final String? legacyPlanId;
  final String? workoutLogId;
  final int createdAt;
  final int updatedAt;

  SessionPrescription copyWith({
    String? id,
    String? dateIso,
    int? cycleWeek,
    SlotType? slotType,
    List<String>? focusCodes,
    int? targetMinutes,
    IntensityTier? intensityTier,
    int? targetRpe,
    String? headlineFa,
    String? coachNoteFa,
    String? source,
    bool? isLocked,
    PrescriptionStatus? status,
    String? movedToDateIso,
    String? legacyPlanId,
    String? workoutLogId,
    int? createdAt,
    int? updatedAt,
  }) {
    return SessionPrescription(
      id: id ?? this.id,
      dateIso: dateIso ?? this.dateIso,
      cycleWeek: cycleWeek ?? this.cycleWeek,
      slotType: slotType ?? this.slotType,
      focusCodes: focusCodes ?? this.focusCodes,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      intensityTier: intensityTier ?? this.intensityTier,
      targetRpe: targetRpe ?? this.targetRpe,
      headlineFa: headlineFa ?? this.headlineFa,
      coachNoteFa: coachNoteFa ?? this.coachNoteFa,
      source: source ?? this.source,
      isLocked: isLocked ?? this.isLocked,
      status: status ?? this.status,
      movedToDateIso: movedToDateIso ?? this.movedToDateIso,
      legacyPlanId: legacyPlanId ?? this.legacyPlanId,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateIso': dateIso,
      'cycleWeek': cycleWeek,
      'slotType': slotType.code,
      'focusCodes': jsonEncode(focusCodes),
      'targetMinutes': targetMinutes,
      'intensityTier': intensityTier.code,
      'targetRpe': targetRpe,
      'headlineFa': headlineFa,
      'coachNoteFa': coachNoteFa,
      'source': source,
      'isLocked': isLocked ? 1 : 0,
      'status': status.code,
      'movedToDateIso': movedToDateIso,
      'legacyPlanId': legacyPlanId,
      'workoutLogId': workoutLogId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SessionPrescription.fromMap(Map<String, dynamic> map) {
    List<String> foci = [];
    final fociRaw = map['focusCodes'];
    if (fociRaw is String && fociRaw.isNotEmpty) {
      try {
        foci = List<String>.from(jsonDecode(fociRaw) as List);
      } catch (_) {}
    }
    return SessionPrescription(
      id: map['id'] as String,
      dateIso: map['dateIso'] as String,
      cycleWeek: map['cycleWeek'] as int,
      slotType: SlotType.fromCode(map['slotType'] as String? ?? 'REST'),
      focusCodes: foci,
      targetMinutes: map['targetMinutes'] as int? ?? 0,
      intensityTier: IntensityTier.fromCode(map['intensityTier'] as String? ?? 'MODERATE'),
      targetRpe: map['targetRpe'] as int?,
      headlineFa: map['headlineFa'] as String? ?? '',
      coachNoteFa: map['coachNoteFa'] as String?,
      source: map['source'] as String? ?? 'GENERATED',
      isLocked: (map['isLocked'] as int? ?? 0) == 1,
      status: PrescriptionStatus.fromCode(map['status'] as String? ?? 'PLANNED'),
      movedToDateIso: map['movedToDateIso'] as String?,
      legacyPlanId: map['legacyPlanId'] as String?,
      workoutLogId: map['workoutLogId'] as String?,
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
    );
  }
}
