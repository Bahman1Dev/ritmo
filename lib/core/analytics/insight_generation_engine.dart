import 'package:ritmo/core/analytics/data_maturity_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

class InsightGenerationEngineInput {

  InsightGenerationEngineInput({
    required this.routineCompletions,
    required this.routines,
    required this.peakPerformanceWindow,
    required this.mostProductiveWeekday,
    required this.mostFatiguedWindow,
    required this.daysOfData,
  });
  final List<Map<String, dynamic>> routineCompletions;
  final List<Map<String, dynamic>> routines;
  final String? peakPerformanceWindow;
  final String? mostProductiveWeekday;
  final String? mostFatiguedWindow;
  final int daysOfData;
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
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(InsightGenerationEngineInput input) => true;

  @override
  List<Type> dependencies() => [EnergyAnalyticsEngine];
  /// Generates objective, reproducible insights without hallucinated claims.
  static List<InsightResult> generate({
    required List<Map<String, dynamic>> routineCompletions,
    required List<Map<String, dynamic>> routines,
    required String? peakPerformanceWindow,
    required String? mostProductiveWeekday,
    required String? mostFatiguedWindow,
    required int daysOfData,
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

    // Calculate dates
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    if (!DataMaturityEngine.hasEnoughDataForWeeklyTrend(daysOfData)) {
      list.add(InsightResult(
        type: InsightType.gatheringData,
        params: {},
        sourceMetric: 'data_maturity',
        calculationWindow: 'none',
      ));
      return list;
    }

    // 1. Learning Growth Highlight
    final learningCompletionsLast7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != 'LEARNING') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final learningCompletionsPrev7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != 'LEARNING') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(fourteenDaysAgo) && time.isBefore(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (learningCompletionsLast7 > learningCompletionsPrev7 && learningCompletionsPrev7 > 0) {
      final percentGrowth = (((learningCompletionsLast7 - learningCompletionsPrev7) / learningCompletionsPrev7) * 100).round();
      list.add(InsightResult(
        type: InsightType.learningGrowth,
        params: {'percent': percentGrowth},
        sourceMetric: 'routine_completions_learning_count',
        calculationWindow: '7_days_vs_previous_7_days',
      ));
    }

    // 2. Health Decline Warning
    final healthCompletionsLast7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != 'HEALTH') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final healthCompletionsPrev7 = routineCompletions.where((comp) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != 'HEALTH') return false;
      final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final type = comp['resultType'] as String? ?? 'FULL';
      return time.isAfter(fourteenDaysAgo) && time.isBefore(sevenDaysAgo) && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (healthCompletionsPrev7 > 0) {
      final percentDrop = (((healthCompletionsPrev7 - healthCompletionsLast7) / healthCompletionsPrev7) * 100).round();
      if (percentDrop >= 10) {
        list.add(InsightResult(
          type: InsightType.healthDecline,
          params: {'percent': percentDrop},
          sourceMetric: 'routine_completions_health_count',
          calculationWindow: '7_days_vs_previous_7_days',
        ));
      }
    }

    // 3. Morning vs Evening completion rates
    final morningCompletions = routineCompletions.where((comp) {
      final local = localTime(comp);
      final type = comp['resultType'] as String? ?? 'FULL';
      return local.hour >= 6 && local.hour < 12 && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    final eveningCompletions = routineCompletions.where((comp) {
      final local = localTime(comp);
      final type = comp['resultType'] as String? ?? 'FULL';
      return local.hour >= 18 && local.hour < 24 && type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    if (morningCompletions > eveningCompletions && eveningCompletions > 0) {
      list.add(InsightResult(
        type: InsightType.morningLead,
        params: {},
        sourceMetric: 'morning_vs_evening_completion_rate',
        calculationWindow: 'all_time',
      ));
    }

    // 4. Fatigue Window Warning
    if (mostFatiguedWindow != null) {
      list.add(InsightResult(
        type: InsightType.fatigueWarning,
        params: {'window': mostFatiguedWindow},
        sourceMetric: 'most_fatigued_window',
        calculationWindow: 'all_time',
      ));
    }

    // 5. Most Productive Weekday
    if (mostProductiveWeekday != null) {
      list.add(InsightResult(
        type: InsightType.productiveWeekday,
        params: {'weekday': mostProductiveWeekday},
        sourceMetric: 'most_productive_weekday',
        calculationWindow: 'all_time',
      ));
    }

    return list;
  }

  static Future<String> calculateWorshipCorrelation() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      
      // Query past active/inactive seasons
      final pastSeasons = await db.query(
        'worship_seasons',
        where: 'end_date < ? OR (endDate < ? AND end_date IS NULL)',
        whereArgs: [todayStr, todayStr],
      );
      
      if (pastSeasons.isEmpty) {
        return 'داده کافی نیست';
      }

      // Query religious routines
      final religiousRoutines = await db.query(
        'routines',
        where: 'category = ? AND isArchived = 0',
        whereArgs: ['RELIGIOUS'],
      );
      
      final religiousIds = religiousRoutines.map((r) => r['id']! as String).toList();
      if (religiousIds.isEmpty) {
        return 'داده کافی نیست';
      }

      // Query completions for these routines
      final completions = await db.query(
        'routine_completions',
        where: "routineId IN (${religiousIds.map((_) => '?').join(',')})",
        whereArgs: religiousIds,
      );

      // Query occurrences for these routines
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

      if (insideOccurrences < 3 || outsideOccurrences < 3) {
        return 'داده کافی نیست';
      }

      final rateInside = insideCompletions / insideOccurrences;
      final rateOutside = outsideCompletions / outsideOccurrences;
      final diff = ((rateInside - rateOutside) * 100).round();

      final sign = diff >= 0 ? '+' : '';
      return '$sign$diff%';
    } catch (e) {
      return 'داده کافی نیست';
    }
  }
}
