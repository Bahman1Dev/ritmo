import 'dart:convert';

class SsExerciseModel {

  SsExerciseModel({
    required this.id,
    required this.name,
    this.nameEn,
    required this.category,
    this.equipment,
    this.instructions,
    this.videoUrl,
    this.isCustom = false,
    this.changeSides = false,
    this.noisy = 0,
    this.impact = 0,
    this.repsDouble = false,
    this.repDurationLow = 0.0,
    this.repDurationMedium = 0.0,
    this.repDurationHigh = 0.0,
    this.sexynessMale = 0.0,
    this.sexynessFemale = 0.0,
    this.isolatedVsCompound = 0.0,
    this.durationSeconds = 0,
    this.defaultReps = 0,
    this.repsHint,
    this.toolsRequired = const [],
    this.constraintNegative,
    this.weightSupported = false,
    this.weightPerHand = false,
    this.muscleIntensity = const {},
    this.skillRequired = 0,
    this.strengthVsCardio = 0.0,
    this.machineVsFreeweight = 0.0,
    this.looksCool = 0,
    this.stance,
  });

  factory SsExerciseModel.fromMap(Map<String, dynamic> map) {
    var parsedTools = <String>[];
    try {
      final rawTools = map['toolsRequired'];
      if (rawTools != null && rawTools.toString().isNotEmpty) {
        final decoded = jsonDecode(rawTools.toString());
        if (decoded is List) {
          parsedTools = decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    var parsedMuscleIntensity = <String, dynamic>{};
    try {
      final rawIntensity = map['muscleIntensity'];
      if (rawIntensity != null && rawIntensity.toString().isNotEmpty) {
        final decoded = jsonDecode(rawIntensity.toString());
        if (decoded is Map<String, dynamic>) {
          parsedMuscleIntensity = decoded;
        }
      }
    } catch (_) {}

    return SsExerciseModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      nameEn: map['nameEn']?.toString(),
      category: map['category']?.toString() ?? '',
      equipment: map['equipment']?.toString(),
      instructions: map['instructions']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
      changeSides: (map['changeSides'] as int? ?? 0) == 1,
      noisy: map['noisy'] as int? ?? 0,
      impact: map['impact'] as int? ?? 0,
      repsDouble: (map['repsDouble'] as int? ?? 0) == 1,
      repDurationLow: (map['repDurationLow'] as num?)?.toDouble() ?? 0.0,
      repDurationMedium: (map['repDurationMedium'] as num?)?.toDouble() ?? 0.0,
      repDurationHigh: (map['repDurationHigh'] as num?)?.toDouble() ?? 0.0,
      sexynessMale: (map['sexynessMale'] as num?)?.toDouble() ?? 0.0,
      sexynessFemale: (map['sexynessFemale'] as num?)?.toDouble() ?? 0.0,
      isolatedVsCompound: (map['isolatedVsCompound'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      defaultReps: map['defaultReps'] as int? ?? 0,
      repsHint: map['repsHint']?.toString(),
      toolsRequired: parsedTools,
      constraintNegative: map['constraintNegative']?.toString(),
      weightSupported: (map['weightSupported'] as int? ?? 0) == 1,
      weightPerHand: (map['weightPerHand'] as int? ?? 0) == 1,
      muscleIntensity: parsedMuscleIntensity,
      skillRequired: map['skillRequired'] as int? ?? 0,
      strengthVsCardio: (map['strengthVsCardio'] as num?)?.toDouble() ?? 0.0,
      machineVsFreeweight: (map['machineVsFreeweight'] as num?)?.toDouble() ?? 0.0,
      looksCool: map['looksCool'] as int? ?? 0,
      stance: map['stance']?.toString(),
    );
  }
  final String id;
  final String name;
  final String? nameEn;
  final String category;
  final String? equipment;
  final String? instructions;
  final String? videoUrl;
  final bool isCustom;
  final bool changeSides;
  final int noisy;
  final int impact;
  final bool repsDouble;
  final double repDurationLow;
  final double repDurationMedium;
  final double repDurationHigh;
  final double sexynessMale;
  final double sexynessFemale;
  final double isolatedVsCompound;
  final int durationSeconds;
  final int defaultReps;
  final String? repsHint;
  final List<String> toolsRequired;
  final String? constraintNegative;
  final bool weightSupported;
  final bool weightPerHand;
  final Map<String, dynamic> muscleIntensity;
  final int skillRequired;
  final double strengthVsCardio;
  final double machineVsFreeweight;
  final int looksCool;
  final String? stance;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'category': category,
      'equipment': equipment,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'isCustom': isCustom ? 1 : 0,
      'changeSides': changeSides ? 1 : 0,
      'noisy': noisy,
      'impact': impact,
      'repsDouble': repsDouble ? 1 : 0,
      'repDurationLow': repDurationLow,
      'repDurationMedium': repDurationMedium,
      'repDurationHigh': repDurationHigh,
      'sexynessMale': sexynessMale,
      'sexynessFemale': sexynessFemale,
      'isolatedVsCompound': isolatedVsCompound,
      'durationSeconds': durationSeconds,
      'defaultReps': defaultReps,
      'repsHint': repsHint,
      'toolsRequired': jsonEncode(toolsRequired),
      'constraintNegative': constraintNegative,
      'weightSupported': weightSupported ? 1 : 0,
      'weightPerHand': weightPerHand ? 1 : 0,
      'muscleIntensity': jsonEncode(muscleIntensity),
      'skillRequired': skillRequired,
      'strengthVsCardio': strengthVsCardio,
      'machineVsFreeweight': machineVsFreeweight,
      'looksCool': looksCool,
      'stance': stance,
    };
  }
}
