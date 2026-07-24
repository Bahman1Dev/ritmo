import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Service responsible for estimating realistic daily study capacity
/// based on behavioral history (EWMA), energy profile, and fatigue management.
class KonkurCapacityEstimator {
  const KonkurCapacityEstimator();

  List<KonkurDailyCapacity> estimate({
    required DateTime start,
    required int days,
    required List<KonkurStudySession> sessions,
    required String currentEnergyLevel,
  }) {
    final cleanStart = DateTime(start.year, start.month, start.day);

    // Group study minutes by date for the last 14 days
    final dailyMinutesMap = <String, int>{};
    for (final s in sessions) {
      if (s.durationMinutes > 0 && s.durationMinutes <= 720) {
        dailyMinutesMap[s.dateIso] = (dailyMinutesMap[s.dateIso] ?? 0) + s.durationMinutes;
      }
    }

    // Compute recent 7-day and 14-day averages
    var last7Sum = 0;
    var last7Count = 0;
    var last14Sum = 0;
    var last14Count = 0;

    for (var i = 1; i <= 14; i++) {
      final d = cleanStart.subtract(Duration(days: i));
      final dStr = _formatDateIso(d);
      final mins = dailyMinutesMap[dStr];
      if (mins != null) {
        last14Sum += mins;
        last14Count++;
        if (i <= 7) {
          last7Sum += mins;
          last7Count++;
        }
      }
    }

    int baseCapacity = 180; // Fallback default
    if (last14Count > 0) {
      final recent7Avg = last7Count > 0 ? (last7Sum / last7Count) : (last14Sum / last14Count);
      final recent14Avg = last14Sum / last14Count;
      baseCapacity = ((recent7Avg * 0.65) + (recent14Avg * 0.35)).round();
    }

    baseCapacity = baseCapacity.clamp(90, 480);

    final result = <KonkurDailyCapacity>[];
    int consecutiveHeavyDays = 0;

    for (var dayOffset = 0; dayOffset < days; dayOffset++) {
      final currentDay = cleanStart.add(Duration(days: dayOffset));
      final dateIso = _formatDateIso(currentDay);

      // Energy factor adjustment
      String dayEnergy = currentEnergyLevel.toUpperCase();

      // Fatigue prevention rule: after 2 consecutive heavy/HIGH days, enforce a lighter day
      if (consecutiveHeavyDays >= 2) {
        dayEnergy = 'LOW';
        consecutiveHeavyDays = 0;
      }

      double energyFactor = 1.0;
      if (dayEnergy == 'HIGH') {
        energyFactor = 1.10;
        consecutiveHeavyDays++;
      } else if (dayEnergy == 'LOW') {
        energyFactor = 0.75;
        consecutiveHeavyDays = 0;
      } else {
        energyFactor = 1.0;
        consecutiveHeavyDays = 0;
      }

      final dayTotalMinutes = (baseCapacity * energyFactor).round().clamp(90, 480);

      // Deep work vs Light work minutes
      final deepRatio = (dayEnergy == 'LOW') ? 0.40 : 0.60;
      final deepWorkMinutes = (dayTotalMinutes * deepRatio).round();
      final lightWorkMinutes = dayTotalMinutes - deepWorkMinutes;

      final maxBlocks = switch (dayEnergy) {
        'HIGH' => 6,
        'LOW' => 3,
        _ => 5,
      };

      result.add(KonkurDailyCapacity(
        dateIso: dateIso,
        totalMinutes: dayTotalMinutes,
        deepWorkMinutes: deepWorkMinutes,
        lightWorkMinutes: lightWorkMinutes,
        maxBlocks: maxBlocks,
        energyLevel: dayEnergy,
      ));
    }

    return result;
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
