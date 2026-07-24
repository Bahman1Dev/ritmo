// lib/core/analytics/movement_load_calculator.dart

import 'package:ritmo/features/sports/movement/domain/movement_kind.dart';
import 'package:sqflite/sqflite.dart';

/// Single source of truth for all MET, MET-minute, and Calorie calculations across Ritmo.
class MovementLoadCalculator {
  /// Default user weight when not recorded in vital_signs_logs (70.0 kg)
  static const double defaultUserWeightKg = 70.0;

  /// Returns MET value for a given [MovementKind] (or raw MET values) and [MovementIntensity].
  static double metFor({
    required double baseMet,
    required double metLow,
    required double metHigh,
    required MovementIntensity intensity,
  }) {
    switch (intensity) {
      case MovementIntensity.low:
        return metLow;
      case MovementIntensity.high:
        return metHigh;
      case MovementIntensity.medium:
        return baseMet;
    }
  }

  /// Calculates MET-minutes = MET * durationMinutes.
  static double metMinutes({
    required double met,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0) return 0.0;
    return met * durationMinutes;
  }

  /// Calculates calories burned (kcal) = (MET * 3.5 * weightKg / 200) * durationMinutes.
  static double calories({
    required double met,
    required double weightKg,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0) return 0.0;
    final weight = weightKg > 0 ? weightKg : defaultUserWeightKg;
    return (met * 3.5 * weight / 200.0) * durationMinutes;
  }

  /// MET of a supplementary sports session based on exercise category MET map:
  /// cardio >= 4 -> 8.0, core -> 4.0, stretching/yoga -> 2.5, fallback strength -> 5.0.
  static Future<double> metForSsSession(DatabaseExecutor db, String sessionId) async {
    try {
      final rows = await db.rawQuery('''
        SELECT el.category, COUNT(*) as cnt
        FROM ss_workout_session_log log
        JOIN ss_session_set_log setlog ON setlog.sessionId = log.id
        JOIN exercises_library el ON el.id = setlog.exerciseId
        WHERE log.id = ?
        GROUP BY el.category
      ''', [sessionId]);

      if (rows.isEmpty) return 5.0; // fallback strength MET

      double totalWeightedMet = 0.0;
      int totalSets = 0;

      for (final r in rows) {
        final cat = (r['category'] as String? ?? '').toLowerCase();
        final count = (r['cnt'] as num? ?? 1).toInt();
        double catMet = 5.0;
        if (cat.contains('cardio')) {
          catMet = 8.0;
        } else if (cat.contains('core') || cat.contains('abs')) {
          catMet = 4.0;
        } else if (cat.contains('stretch') || cat.contains('flexibility') || cat.contains('yoga')) {
          catMet = 2.5;
        }
        totalWeightedMet += catMet * count;
        totalSets += count;
      }

      return totalSets > 0 ? totalWeightedMet / totalSets : 5.0;
    } catch (_) {
      return 5.0;
    }
  }

  /// Helper to fetch user's last recorded weight from vital_signs_logs (or 70.0 kg fallback).
  static Future<double> getUserWeightKg(DatabaseExecutor db) async {
    try {
      final rows = await db.query(
        'vital_signs_logs',
        columns: ['value'],
        where: "vitalType = 'WEIGHT'",
        orderBy: 'loggedAt DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as num?;
        if (val != null && val > 0) return val.toDouble();
      }
    } catch (_) {}
    return defaultUserWeightKg;
  }
}
