// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sports_local_datasource.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyVolumeReportData _$WeeklyVolumeReportDataFromJson(
  Map<String, dynamic> json,
) => _WeeklyVolumeReportData(
  volumePerMuscle: (json['volumePerMuscle'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  setsPerMuscle: Map<String, int>.from(json['setsPerMuscle'] as Map),
  sessionsPerMuscle: Map<String, int>.from(json['sessionsPerMuscle'] as Map),
  totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
  totalSets: (json['totalSets'] as num).toInt(),
  totalSessions: (json['totalSessions'] as num).toInt(),
  weekStartDate: (json['weekStartDate'] as num).toInt(),
);

Map<String, dynamic> _$WeeklyVolumeReportDataToJson(
  _WeeklyVolumeReportData instance,
) => <String, dynamic>{
  'volumePerMuscle': instance.volumePerMuscle,
  'setsPerMuscle': instance.setsPerMuscle,
  'sessionsPerMuscle': instance.sessionsPerMuscle,
  'totalVolumeKg': instance.totalVolumeKg,
  'totalSets': instance.totalSets,
  'totalSessions': instance.totalSessions,
  'weekStartDate': instance.weekStartDate,
};
