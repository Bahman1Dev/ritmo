// lib/features/sports/movement/domain/movement_event.dart

import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

class MovementEvent {
  const MovementEvent({
    required this.id,
    required this.kindCode,
    required this.durationMinutes,
    this.intensity = MovementIntensity.medium,
    this.note,
    required this.loggedAt,
    this.endedAt,
    this.tier,
    this.muscleGroups,
    this.feeling,
    this.location,
    this.distanceMeters,
    this.elevationMeters,
    this.laps,
    this.steps,
    this.avgHeartRate,
    this.metMinutes = 0.0,
    this.caloriesKcal = 0.0,
    this.venue,
    this.companions,
    this.sourceModule = 'MOVEMENT',
    this.metricsJson,
  });

  final String id;
  final String kindCode;
  final int durationMinutes;
  final MovementIntensity intensity;
  final String? note;
  final int loggedAt;
  final int? endedAt;
  final String? tier;
  final String? muscleGroups;
  final String? feeling;
  final String? location;
  final double? distanceMeters;
  final double? elevationMeters;
  final int? laps;
  final int? steps;
  final int? avgHeartRate;
  final double metMinutes;
  final double caloriesKcal;
  final String? venue;
  final String? companions;
  final String sourceModule;
  final String? metricsJson;

  factory MovementEvent.fromMap(Map<String, dynamic> map) {
    return MovementEvent(
      id: map['id'] as String,
      kindCode: map['kind'] as String? ?? map['type'] as String? ?? 'OTHER',
      durationMinutes: (map['durationMinutes'] as num? ?? 0).toInt(),
      intensity: MovementIntensity.fromCode(map['intensity'] as String? ?? 'MEDIUM'),
      note: map['note'] as String?,
      loggedAt: (map['loggedAt'] as num? ?? DateTime.now().millisecondsSinceEpoch).toInt(),
      endedAt: map['endedAt'] != null ? (map['endedAt'] as num).toInt() : null,
      tier: map['tier'] as String?,
      muscleGroups: map['muscleGroups'] as String?,
      feeling: map['feeling'] as String?,
      location: map['location'] as String?,
      distanceMeters: map['distanceMeters'] != null ? (map['distanceMeters'] as num).toDouble() : null,
      elevationMeters: map['elevationMeters'] != null ? (map['elevationMeters'] as num).toDouble() : null,
      laps: map['laps'] != null ? (map['laps'] as num).toInt() : null,
      steps: map['steps'] != null ? (map['steps'] as num).toInt() : null,
      avgHeartRate: map['avgHeartRate'] != null ? (map['avgHeartRate'] as num).toInt() : null,
      metMinutes: (map['metMinutes'] as num? ?? 0.0).toDouble(),
      caloriesKcal: (map['caloriesKcal'] as num? ?? 0.0).toDouble(),
      venue: map['venue'] as String?,
      companions: map['companions'] as String?,
      sourceModule: map['sourceModule'] as String? ?? 'MOVEMENT',
      metricsJson: map['metricsJson'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kindCode,
      'type': kindCode, // Backward compatibility column
      'durationMinutes': durationMinutes,
      'intensity': intensity.code,
      'note': note,
      'loggedAt': loggedAt,
      'endedAt': endedAt,
      'tier': tier,
      'muscleGroups': muscleGroups,
      'feeling': feeling,
      'location': location,
      'distanceMeters': distanceMeters,
      'elevationMeters': elevationMeters,
      'laps': laps,
      'steps': steps,
      'avgHeartRate': avgHeartRate,
      'metMinutes': metMinutes,
      'caloriesKcal': caloriesKcal,
      'venue': venue,
      'companions': companions,
      'sourceModule': sourceModule,
      'metricsJson': metricsJson,
    };
  }

  MovementEvent copyWith({
    String? id,
    String? kindCode,
    int? durationMinutes,
    MovementIntensity? intensity,
    String? note,
    int? loggedAt,
    int? endedAt,
    String? tier,
    String? muscleGroups,
    String? feeling,
    String? location,
    double? distanceMeters,
    double? elevationMeters,
    int? laps,
    int? steps,
    int? avgHeartRate,
    double? metMinutes,
    double? caloriesKcal,
    String? venue,
    String? companions,
    String? sourceModule,
    String? metricsJson,
  }) {
    return MovementEvent(
      id: id ?? this.id,
      kindCode: kindCode ?? this.kindCode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      loggedAt: loggedAt ?? this.loggedAt,
      endedAt: endedAt ?? this.endedAt,
      tier: tier ?? this.tier,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      feeling: feeling ?? this.feeling,
      location: location ?? this.location,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      laps: laps ?? this.laps,
      steps: steps ?? this.steps,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      metMinutes: metMinutes ?? this.metMinutes,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      venue: venue ?? this.venue,
      companions: companions ?? this.companions,
      sourceModule: sourceModule ?? this.sourceModule,
      metricsJson: metricsJson ?? this.metricsJson,
    );
  }
}
