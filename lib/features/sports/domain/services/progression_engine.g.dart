// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_engine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgressionRecommendation _$ProgressionRecommendationFromJson(
  Map<String, dynamic> json,
) => _ProgressionRecommendation(
  nextWeightKg: (json['nextWeightKg'] as num).toDouble(),
  nextRepsMin: (json['nextRepsMin'] as num).toInt(),
  nextRepsMax: (json['nextRepsMax'] as num).toInt(),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$ProgressionRecommendationToJson(
  _ProgressionRecommendation instance,
) => <String, dynamic>{
  'nextWeightKg': instance.nextWeightKg,
  'nextRepsMin': instance.nextRepsMin,
  'nextRepsMax': instance.nextRepsMax,
  'reason': instance.reason,
};

_DeloadRecommendation _$DeloadRecommendationFromJson(
  Map<String, dynamic> json,
) => _DeloadRecommendation(
  weightMultiplier: (json['weightMultiplier'] as num).toDouble(),
  setsMultiplier: (json['setsMultiplier'] as num).toDouble(),
  repsMin: (json['repsMin'] as num).toInt(),
  repsMax: (json['repsMax'] as num).toInt(),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$DeloadRecommendationToJson(
  _DeloadRecommendation instance,
) => <String, dynamic>{
  'weightMultiplier': instance.weightMultiplier,
  'setsMultiplier': instance.setsMultiplier,
  'repsMin': instance.repsMin,
  'repsMax': instance.repsMax,
  'reason': instance.reason,
};
