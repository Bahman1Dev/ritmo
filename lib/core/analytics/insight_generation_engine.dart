import 'dart:math';

import 'package:ritmo/core/analytics/data_maturity_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/util/ritmo_date.dart';

class InsightGenerationEngineInput {

  InsightGenerationEngineInput({
    required this.routineCompletions,
    required this.routines,
    required this.peakPerformanceWindow,
    required this.mostProductiveWeekday,
    required this.mostFatiguedWindow,
    required this.daysOfData,
    this.dailyRhythm = const [],
    this.sleepEnergyCorrelation,
    this.sleepMoodCorrelation,
    this.isMenstruating = false,
  });
  final List<Map<String, dynamic>> routineCompletions;
  final List<Map<String, dynamic>> routines;
  final String? peakPerformanceWindow;
  final String? mostProductiveWeekday;
  final String? mostFatiguedWindow;
  final int daysOfData;
  final List<Map<String, dynamic>> dailyRhythm;
  final double? sleepEnergyCorrelation;
  final double? sleepMoodCorrelation;
  final bool isMenstruating;
}

class InsightGenerationEngine implements CachedEngine<InsightGenerationEngineInput, List<InsightResult>> {
  @override
  Future<List<InsightResult>> calculate(InsightGenerationEngineInput input) async {
    return generate(
      routineCompletions: input.routineCompletions,
      routines: input.routines,
      peakPerformanceWindow: input.peakPerformanceWindow,
      mostProductiveWeekday: input.mostProductiveWeekday,
      mostFatiguedWindow: input.mostFatiguedWindow,
      daysOfData: input.daysOfData,
      dailyRhythm: input.dailyRhythm,
      sleepEnergyCorrelation: input.sleepEnergyCorrelation,
      sleepMoodCorrelation: input.sleepMoodCorrelation,
      isMenstruating: input.isMenstruating,
    );
  }

  @override
  Duration get ttl => const Duration(minutes: 30);

  @override
  String fingerprint(InsightGenerationEngineInput input) {
    return '${input.daysOfData}|${input.routineCompletions.length}|${input.routines.length}|${input.isMenstruating}';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(InsightGenerationEngineInput input) => true;

  @override
  List<Type> dependencies() => [EnergyAnalyticsEngine];

  /// Pearson correlation helper for safe statistical calculation
  static double pearsonCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.length < 5) return 0.0;
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    double numSum = 0.0;
    double denX = 0.0;
    double denY = 0.0;
    for (int i = 0; i < x.length; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numSum += dx * dy;
      denX += dx * dx;
      denY += dy * dy;
    }
    if (denX == 0 || denY == 0) return 0.0;
    return numSum / sqrt(denX * denY);
  }

  /// Generates objective, reproducible insights without hallucinated claims.
  static List<InsightResult> generate({
    required List<Map<String, dynamic>> routineCompletions,
    required List<Map<String, dynamic>> routines,
    required String? peakPerformanceWindow,
    required String? mostProductiveWeekday,
    required String? mostFatiguedWindow,
    required int daysOfData,
    List<Map<String, dynamic>> dailyRhythm = const [],
    double? sleepEnergyCorrelation,
    double? sleepMoodCorrelation,
    bool isMenstruating = false,
  }) {
    final list = <InsightResult>[];

    // Helper to get local time from completions
    DateTime localTime(Map<String, dynamic> comp) {
      return EnergyAnalyticsEngine.toIranLocal(comp['completionTime'] as int);
    }

    final activeRoutines = routines.where((r) => (r['isArchived'] as int? ?? 0) == 0).toList();
    final routineToDomain = {
      for (final r in activeRoutines) r['id'] as String: LifeBalanceEngine.mapCategoryToDomain(r['category'] as String)
    };

    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    if (!DataMaturityEngine.hasEnoughDataForWeeklyTrend(daysOfData)) {
      list.add(InsightResult(
        type: InsightType.gatheringData,
        params: {},
        sourceMetric: 'data_maturity',
        calculationWindow: 'none',
        strength: 0.1,
        severity: 'INFO',
      ));
      return list;
    }

    const int minSampleGate = 5; // Minimum sample size rule (ط۲)

    // 1. Learning Growth Highlight
    final learningCompletionsLast7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      if (routineToDomain[rId] != 'LEARNING') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final learningCompletionsPrev7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      if (routineToDomain[rId] != 'LEARNING') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(fourteenDaysAgo) && time.isBefore(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (learningCompletionsLast7 >= minSampleGate && learningCompletionsPrev7 >= minSampleGate) {
      if (learningCompletionsLast7 > learningCompletionsPrev7) {
        final percentGrowth = (((learningCompletionsLast7 - learningCompletionsPrev7) / learningCompletionsPrev7) * 100).round();
        final strength = (percentGrowth / 100).clamp(0.2, 1.0);
        list.add(InsightResult(
          type: InsightType.learningGrowth,
          params: {'percent': percentGrowth},
          sourceMetric: 'routine_completions_learning_rate',
          calculationWindow: 'LAST_7_VS_PREV_7',
          strength: strength,
          severity: 'POSITIVE',
          actionType: 'open_module',
          linkModule: 'routines',
        ));
      }
    }

    // 2. Health Decline Warning
    final healthCompletionsLast7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      if (routineToDomain[rId] != 'HEALTH') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final healthCompletionsPrev7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      if (routineToDomain[rId] != 'HEALTH') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(fourteenDaysAgo) && time.isBefore(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (healthCompletionsLast7 >= minSampleGate && healthCompletionsPrev7 >= minSampleGate) {
      if (healthCompletionsPrev7 > healthCompletionsLast7) {
        final percentDrop = (((healthCompletionsPrev7 - healthCompletionsLast7) / healthCompletionsPrev7) * 100).round();
        if (percentDrop >= 10) {
          // Cycle sensitivity framing (I5): Soften severity if user is menstruating
          final severity = isMenstruating ? 'INFO' : 'WATCH';
          list.add(InsightResult(
            type: InsightType.healthDecline,
            params: {'percent': percentDrop},
            sourceMetric: 'routine_completions_health_rate',
            calculationWindow: 'LAST_7_VS_PREV_7',
            strength: (percentDrop / 100).clamp(0.2, 1.0),
            severity: severity,
            actionType: 'assistant_suggest',
            linkModule: 'routines',
          ));
        }
      }
    }

    // 3. Morning vs Evening completion rates
    final morningCompletions = routineCompletions.where((comp) {
      final local = localTime(comp);
      final type = comp['resultType'] as String? ?? 'FULL';
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      return time.isAfter(fourteenDaysAgo) && local.hour >= 6 && local.hour < 12 && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final eveningCompletions = routineCompletions.where((comp) {
      final local = localTime(comp);
      final type = comp['resultType'] as String? ?? 'FULL';
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      return time.isAfter(fourteenDaysAgo) && local.hour >= 18 && local.hour < 24 && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (morningCompletions >= minSampleGate && eveningCompletions >= minSampleGate) {
      if (morningCompletions > eveningCompletions) {
        list.add(InsightResult(
          type: InsightType.morningLead,
          params: {},
          sourceMetric: 'morning_vs_evening_completion_rate',
          calculationWindow: 'LAST_14_DAYS',
          strength: 0.6,
          severity: 'POSITIVE',
          actionType: 'assistant_suggest',
          linkModule: 'routines',
        ));
      }
    }

    // 4. Fatigue Window Warning
    if (mostFatiguedWindow != null) {
      list.add(InsightResult(
        type: InsightType.fatigueWarning,
        params: {'window': mostFatiguedWindow},
        sourceMetric: 'most_fatigued_window',
        calculationWindow: 'LAST_30_DAYS',
        strength: 0.7,
        severity: 'WATCH',
        actionType: 'open_module',
        linkModule: 'energy',
      ));
    }

    // 5. Most Productive Weekday
    if (mostProductiveWeekday != null) {
      list.add(InsightResult(
        type: InsightType.productiveWeekday,
        params: {'weekday': mostProductiveWeekday},
        sourceMetric: 'most_productive_weekday',
        calculationWindow: 'LAST_30_DAYS',
        strength: 0.65,
        severity: 'POSITIVE',
      ));
    }

    // 6. Sleep Energy & Sleep Mood Correlation Insights (I3)
    if (sleepEnergyCorrelation != null && sleepEnergyCorrelation.abs() >= 0.3) {
      final r = sleepEnergyCorrelation;
      list.add(InsightResult(
        type: InsightType.sleepEnergyCorrelation,
        params: {'coef': (r * 100).round()},
        sourceMetric: 'sleep_energy_correlation',
        calculationWindow: 'LAST_30_DAYS',
        strength: r.abs(),
        severity: r > 0 ? 'POSITIVE' : 'WATCH',
        actionType: 'open_module',
        linkModule: 'wellbeing',
      ));
    }

    if (sleepMoodCorrelation != null && sleepMoodCorrelation.abs() >= 0.3) {
      final r = sleepMoodCorrelation;
      list.add(InsightResult(
        type: InsightType.sleepMoodCorrelation,
        params: {'coef': (r * 100).round()},
        sourceMetric: 'sleep_mood_correlation',
        calculationWindow: 'LAST_30_DAYS',
        strength: r.abs(),
        severity: r > 0 ? 'POSITIVE' : 'WATCH',
        actionType: 'open_module',
        linkModule: 'wellbeing',
      ));
    }

    // 7. Energy - Completion Link (Pearson) (I3)
    if (dailyRhythm.length >= 7) {
      final energies = <num>[];
      final ratios = <num>[];
      for (final r in dailyRhythm) {
        final ratio = (r['completion_ratio'] as num?)?.toDouble() ?? 0.0;
        final energy = (r['rhythmScore'] as num?)?.toDouble() ?? (r['energyRecharged'] as num?)?.toDouble();
        if (energy != null) {
          energies.add(energy);
          ratios.add(ratio);
        }
      }
      final corr = pearsonCorrelation(energies, ratios);
      if (corr.abs() >= 0.3) {
        list.add(InsightResult(
          type: InsightType.energyCompletionLink,
          params: {'coef': (corr * 100).round()},
          sourceMetric: 'energy_completion_link',
          calculationWindow: 'LAST_14_DAYS',
          strength: corr.abs(),
          severity: corr > 0 ? 'POSITIVE' : 'INFO',
          actionType: 'open_module',
          linkModule: 'energy',
        ));
      }
    }

    // 8. Dynamic Consistency Score (I3)
    if (dailyRhythm.length >= 7) {
      final ratios = dailyRhythm.map((r) => (r['completion_ratio'] as num?)?.toDouble() ?? 0.0).toList();
      final mean = ratios.reduce((a, b) => a + b) / ratios.length;
      final variance = ratios.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / ratios.length;
      final stdDev = sqrt(variance);
      final consistency = ((1.0 - stdDev.clamp(0.0, 1.0)) * 100).round();
      if (consistency >= 60) {
        list.add(InsightResult(
          type: InsightType.consistencyScore,
          params: {'score': consistency},
          sourceMetric: 'completion_ratio_stddev',
          calculationWindow: 'LAST_14_DAYS',
          strength: (consistency / 100).clamp(0.4, 1.0),
          severity: 'POSITIVE',
        ));
      }
    }

    // Rank insights by weighted score (strength * severityWeight) & cap top 6 (I7)
    final severityWeights = {'POSITIVE': 1.2, 'WATCH': 1.1, 'INFO': 1.0};
    list.sort((a, b) {
      final wA = a.strength * (severityWeights[a.severity] ?? 1.0);
      final wB = b.strength * (severityWeights[b.severity] ?? 1.0);
      return wB.compareTo(wA);
    });

    return list.take(6).toList();
  }

  static Future<String> calculateWorshipCorrelation() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = RitmoDate.dayKey(DateTime.fromMillisecondsSinceEpoch(1700000000000));

      // Query past active/inactive seasons defensively (I8)
      final pastSeasons = await db.query(
        'worship_seasons',
        where: 'end_date < ? OR (endDate < ? AND end_date IS NULL)',
        whereArgs: [todayStr, todayStr],
      );

      if (pastSeasons.isEmpty) {
        return 'داده کافی نیست';
      }

      final religiousRoutines = await db.query(
        'routines',
        where: 'category = ? AND isArchived = 0',
        whereArgs: ['RELIGIOUS'],
      );

      final religiousIds = religiousRoutines.map((r) => r['id']! as String).toList();
      if (religiousIds.isEmpty) {
        return 'داده کافی نیست';
      }

      final completions = await db.query(
        'routine_completions',
        where: "routineId IN (${religiousIds.map((_) => '?').join(',')})",
        whereArgs: religiousIds,
      );

      final occurrences = await db.query(
        'routine_occurrences',
        where: "routine_id IN (${religiousIds.map((_) => '?').join(',')})",
        whereArgs: religiousIds,
      );

      if (occurrences.isEmpty) {
        return 'داده کافی نیست';
      }

      bool isInsideSeason(String dateStr) {
        for (final s in pastSeasons) {
          final start = (s['start_date'] ?? s['startDate']) as String?;
          final end = (s['end_date'] ?? s['endDate']) as String?;
          if (start != null && end != null) {
            if (dateStr.compareTo(start) >= 0 && dateStr.compareTo(end) <= 0) {
              return true;
            }
          }
        }
        return false;
      }

      var insideOccurrences = 0;
      var outsideOccurrences = 0;
      for (final occ in occurrences) {
        final date = occ['date'] as String? ?? '';
        if (isInsideSeason(date)) {
          insideOccurrences++;
        } else {
          outsideOccurrences++;
        }
      }

      var insideCompletions = 0;
      var outsideCompletions = 0;
      for (final comp in completions) {
        final date = comp['completionDate'] as String? ?? '';
        final type = comp['resultType'] as String? ?? '';
        if (type == 'SKIPPED') continue;
        if (isInsideSeason(date)) {
          insideCompletions++;
        } else {
          outsideCompletions++;
        }
      }

      if (insideOccurrences < 5 || outsideOccurrences < 5) {
        return 'داده کافی نیست';
      }

      final rateInside = (insideCompletions / insideOccurrences).clamp(0.0, 1.0);
      final rateOutside = (outsideCompletions / outsideOccurrences).clamp(0.0, 1.0);
      final diff = ((rateInside - rateOutside) * 100).round();

      final sign = diff >= 0 ? '+' : '';
      return '$sign$diff%';
    } catch (e) {
      return 'داده کافی نیست';
    }
  }
}
