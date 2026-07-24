import 'dart:convert';

enum FitnessGoal { muscleGain, fatLoss, bodyRecomposition, strength }
enum ExperienceLevel { beginner, intermediate, advanced }
enum TrainingLocation { home, gym, outdoor }
enum Equipment { barbell, dumbbell, machine, resistanceBand, pullupBar, bodyweightOnly, kettlebell, cables }
enum BodyArea { chest, back, legs, shoulders, arms, core, glutes, fullBody }
enum Limitation { kneeProblems, backProblems, shoulderProblems, wristProblems, noPullUps, noJumping, none }
enum SessionDuration { short30, medium45, long60, flexible }
enum Feeling { easy, good, hard }
enum ExerciseStatus { done, current, upcoming }

class SsUserProfile {

  SsUserProfile({
    this.id = 'default',
    required this.goal,
    required this.experienceLevel,
    required this.trainingLocation,
    required this.availableEquipment,
    this.daysPerWeek = 3,
    required this.focusAreas,
    required this.physicalLimitations,
    this.limitationNote,
    required this.sessionDuration,
    this.gender,
    this.onboardingCompleted = false,
    this.neighborFriendly = false,
    this.programStartDate,
    this.deloadEveryNWeeks = 4,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SsUserProfile.fromMap(Map<String, dynamic> map) {
    // Parse Equipment list
    final equipmentRaw = map['availableEquipment'] != null 
        ? jsonDecode(map['availableEquipment'] as String) as List<dynamic>
        : [];
    final equipmentList = equipmentRaw
        .map((e) => _stringToEquipment(e.toString()))
        .whereType<Equipment>()
        .toList();

    // Parse BodyArea list
    final focusAreasRaw = map['focusAreas'] != null
        ? jsonDecode(map['focusAreas'] as String) as List<dynamic>
        : [];
    final focusAreasList = focusAreasRaw
        .map((e) => _stringToBodyArea(e.toString()))
        .whereType<BodyArea>()
        .toList();

    // Parse Limitation list
    final limitationsRaw = map['physicalLimitations'] != null
        ? jsonDecode(map['physicalLimitations'] as String) as List<dynamic>
        : [];
    final limitationsList = limitationsRaw
        .map((e) => _stringToLimitation(e.toString()))
        .whereType<Limitation>()
        .toList();

    return SsUserProfile(
      id: map['id']?.toString() ?? 'default',
      goal: _stringToGoal(map['goal']?.toString()) ?? FitnessGoal.bodyRecomposition,
      experienceLevel: _stringToExperienceLevel(map['experienceLevel']?.toString()) ?? ExperienceLevel.beginner,
      trainingLocation: _stringToLocation(map['trainingLocation']?.toString()) ?? TrainingLocation.home,
      availableEquipment: equipmentList,
      daysPerWeek: map['daysPerWeek'] as int? ?? 3,
      focusAreas: focusAreasList,
      physicalLimitations: limitationsList,
      limitationNote: map['limitationNote']?.toString(),
      sessionDuration: _stringToSessionDuration(map['sessionDuration']?.toString()) ?? SessionDuration.flexible,
      gender: map['gender']?.toString(),
      onboardingCompleted: (map['onboardingCompleted'] as int? ?? 0) == 1,
      neighborFriendly: (map['neighborFriendly'] as int? ?? 0) == 1,
      programStartDate: map['programStartDate']?.toString(),
      deloadEveryNWeeks: map['deloadEveryNWeeks'] as int? ?? 4,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
  final String id;
  final FitnessGoal goal;
  final ExperienceLevel experienceLevel;
  final TrainingLocation trainingLocation;
  final List<Equipment> availableEquipment;
  final int daysPerWeek;
  final List<BodyArea> focusAreas;
  final List<Limitation> physicalLimitations;
  final String? limitationNote;
  final SessionDuration sessionDuration;
  final String? gender;
  final bool onboardingCompleted;
  final bool neighborFriendly;
  final String? programStartDate;
  final int deloadEveryNWeeks;
  final int createdAt;
  final int updatedAt;

  SsUserProfile copyWith({
    String? id,
    FitnessGoal? goal,
    ExperienceLevel? experienceLevel,
    TrainingLocation? trainingLocation,
    List<Equipment>? availableEquipment,
    int? daysPerWeek,
    List<BodyArea>? focusAreas,
    List<Limitation>? physicalLimitations,
    String? limitationNote,
    SessionDuration? sessionDuration,
    String? gender,
    bool? onboardingCompleted,
    bool? neighborFriendly,
    String? programStartDate,
    int? deloadEveryNWeeks,
    int? createdAt,
    int? updatedAt,
  }) {
    return SsUserProfile(
      id: id ?? this.id,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      focusAreas: focusAreas ?? this.focusAreas,
      physicalLimitations: physicalLimitations ?? this.physicalLimitations,
      limitationNote: limitationNote ?? this.limitationNote,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      gender: gender ?? this.gender,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      neighborFriendly: neighborFriendly ?? this.neighborFriendly,
      programStartDate: programStartDate ?? this.programStartDate,
      deloadEveryNWeeks: deloadEveryNWeeks ?? this.deloadEveryNWeeks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal': _goalToString(goal),
      'experienceLevel': _experienceLevelToString(experienceLevel),
      'trainingLocation': _locationToString(trainingLocation),
      'availableEquipment': jsonEncode(availableEquipment.map(_equipmentToString).toList()),
      'daysPerWeek': daysPerWeek,
      'focusAreas': jsonEncode(focusAreas.map(_bodyAreaToString).toList()),
      'physicalLimitations': jsonEncode(physicalLimitations.map(_limitationToString).toList()),
      'limitationNote': limitationNote,
      'sessionDuration': _sessionDurationToString(sessionDuration),
      'gender': gender?.toUpperCase(),
      'onboardingCompleted': onboardingCompleted ? 1 : 0,
      'neighborFriendly': neighborFriendly ? 1 : 0,
      'programStartDate': programStartDate,
      'deloadEveryNWeeks': deloadEveryNWeeks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // --- Helper mapping methods ---

  static String _goalToString(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.muscleGain: return 'MUSCLE_GAIN';
      case FitnessGoal.fatLoss: return 'FAT_LOSS';
      case FitnessGoal.bodyRecomposition: return 'BODY_RECOMPOSITION';
      case FitnessGoal.strength: return 'STRENGTH';
    }
  }

  static FitnessGoal? _stringToGoal(String? val) {
    if (val == null) return null;
    switch (val.toUpperCase()) {
      case 'MUSCLE_GAIN': return FitnessGoal.muscleGain;
      case 'FAT_LOSS': return FitnessGoal.fatLoss;
      case 'BODY_RECOMPOSITION': return FitnessGoal.bodyRecomposition;
      case 'STRENGTH': return FitnessGoal.strength;
      default: return null;
    }
  }

  static String _experienceLevelToString(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner: return 'BEGINNER';
      case ExperienceLevel.intermediate: return 'INTERMEDIATE';
      case ExperienceLevel.advanced: return 'ADVANCED';
    }
  }

  static ExperienceLevel? _stringToExperienceLevel(String? val) {
    if (val == null) return null;
    switch (val.toUpperCase()) {
      case 'BEGINNER': return ExperienceLevel.beginner;
      case 'INTERMEDIATE': return ExperienceLevel.intermediate;
      case 'ADVANCED': return ExperienceLevel.advanced;
      default: return null;
    }
  }

  static String _locationToString(TrainingLocation loc) {
    switch (loc) {
      case TrainingLocation.home: return 'HOME';
      case TrainingLocation.gym: return 'GYM';
      case TrainingLocation.outdoor: return 'OUTDOOR';
    }
  }

  static TrainingLocation? _stringToLocation(String? val) {
    if (val == null) return null;
    switch (val.toUpperCase()) {
      case 'HOME': return TrainingLocation.home;
      case 'GYM': return TrainingLocation.gym;
      case 'OUTDOOR': return TrainingLocation.outdoor;
      default: return null;
    }
  }

  static String _sessionDurationToString(SessionDuration duration) {
    switch (duration) {
      case SessionDuration.short30: return 'SHORT_30MIN';
      case SessionDuration.medium45: return 'MEDIUM_45MIN';
      case SessionDuration.long60: return 'LONG_60MIN';
      case SessionDuration.flexible: return 'FLEXIBLE';
    }
  }

  static SessionDuration? _stringToSessionDuration(String? val) {
    if (val == null) return null;
    switch (val.toUpperCase()) {
      case 'SHORT_30MIN': return SessionDuration.short30;
      case 'MEDIUM_45MIN': return SessionDuration.medium45;
      case 'LONG_60MIN': return SessionDuration.long60;
      case 'FLEXIBLE': return SessionDuration.flexible;
      default: return null;
    }
  }

  static String _equipmentToString(Equipment eq) {
    switch (eq) {
      case Equipment.barbell: return 'BARBELL';
      case Equipment.dumbbell: return 'DUMBBELL';
      case Equipment.machine: return 'MACHINE';
      case Equipment.resistanceBand: return 'RESISTANCE_BAND';
      case Equipment.pullupBar: return 'PULLUP_BAR';
      case Equipment.bodyweightOnly: return 'BODYWEIGHT_ONLY';
      case Equipment.kettlebell: return 'KETTLEBELL';
      case Equipment.cables: return 'CABLES';
    }
  }

  static Equipment? _stringToEquipment(String val) {
    switch (val.toUpperCase()) {
      case 'BARBELL': return Equipment.barbell;
      case 'DUMBBELL': return Equipment.dumbbell;
      case 'MACHINE': return Equipment.machine;
      case 'RESISTANCE_BAND': return Equipment.resistanceBand;
      case 'PULLUP_BAR': return Equipment.pullupBar;
      case 'BODYWEIGHT_ONLY': return Equipment.bodyweightOnly;
      case 'KETTLEBELL': return Equipment.kettlebell;
      case 'CABLES': return Equipment.cables;
      default: return null;
    }
  }

  static String _bodyAreaToString(BodyArea area) {
    switch (area) {
      case BodyArea.chest: return 'CHEST';
      case BodyArea.back: return 'BACK';
      case BodyArea.legs: return 'LEGS';
      case BodyArea.shoulders: return 'SHOULDERS';
      case BodyArea.arms: return 'ARMS';
      case BodyArea.core: return 'CORE';
      case BodyArea.glutes: return 'GLUTES';
      case BodyArea.fullBody: return 'FULL_BODY';
    }
  }

  static BodyArea? _stringToBodyArea(String val) {
    switch (val.toUpperCase()) {
      case 'CHEST': return BodyArea.chest;
      case 'BACK': return BodyArea.back;
      case 'LEGS': return BodyArea.legs;
      case 'SHOULDERS': return BodyArea.shoulders;
      case 'ARMS': return BodyArea.arms;
      case 'CORE': return BodyArea.core;
      case 'GLUTES': return BodyArea.glutes;
      case 'FULL_BODY': return BodyArea.fullBody;
      default: return null;
    }
  }

  static String _limitationToString(Limitation lim) {
    switch (lim) {
      case Limitation.kneeProblems: return 'KNEE_PROBLEMS';
      case Limitation.backProblems: return 'BACK_PROBLEMS';
      case Limitation.shoulderProblems: return 'SHOULDER_PROBLEMS';
      case Limitation.wristProblems: return 'WRIST_PROBLEMS';
      case Limitation.noPullUps: return 'NO_PULLUPS';
      case Limitation.noJumping: return 'NO_JUMPING';
      case Limitation.none: return 'NONE';
    }
  }

  static Limitation? _stringToLimitation(String val) {
    switch (val.toUpperCase()) {
      case 'KNEE_PROBLEMS': return Limitation.kneeProblems;
      case 'BACK_PROBLEMS': return Limitation.backProblems;
      case 'SHOULDER_PROBLEMS': return Limitation.shoulderProblems;
      case 'WRIST_PROBLEMS': return Limitation.wristProblems;
      case 'NO_PULLUPS': return Limitation.noPullUps;
      case 'NO_JUMPING': return Limitation.noJumping;
      case 'NONE': return Limitation.none;
      default: return null;
    }
  }
}
