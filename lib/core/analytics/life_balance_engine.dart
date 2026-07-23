import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

class LifeBalanceEngineInput {
  LifeBalanceEngineInput({required this.routines, required this.routineCompletions});
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> routineCompletions;
}

class LifeBalanceEngineOutput {
  LifeBalanceEngineOutput({required this.score, required this.distribution, required this.trend});
  final int score;
  final Map<String, double> distribution;
  final Map<String, int> trend;
}

class LifeBalanceEngine implements CachedEngine<LifeBalanceEngineInput, LifeBalanceEngineOutput> {
  @override
  Future<LifeBalanceEngineOutput> calculate(LifeBalanceEngineInput input) async {
    final score = calculateLifeBalanceScore(
      routines: input.routines,
      routineCompletions: input.routineCompletions,
    );
    final distribution = calculateCategoryDistribution(
      routines: input.routines,
      routineCompletions: input.routineCompletions,
    );
    final trend = calculateBalanceTrend(
      routines: input.routines,
      routineCompletions: input.routineCompletions,
    );
    return LifeBalanceEngineOutput(score: score, distribution: distribution, trend: trend);
  }

  @override
  void invalidate() {}

  @override
  bool canRun(LifeBalanceEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  /// Maps a routine category database string to the 6 core analytical domains.
  static String mapCategoryToDomain(String dbCategory) {
    final clean = dbCategory.toLowerCase().trim();
    if (clean == 'religious') return 'RELIGION';
    if (clean == 'medical' || clean == 'fitness') return 'HEALTH';
    if (clean == 'learning' || clean == 'konkur') return 'LEARNING';
    if (clean == 'work') return 'WORK';
    if (clean == 'personal') return 'PERSONAL';
    if (clean == 'free') return 'FREE';
    return 'FREE'; // Fallback
  }

  /// Calculates the Life Balance Score (0 - 100) using normalized variance.
  /// 
  /// - Only active domains (domains having at least one active, non-archived routine)
  ///   are considered in the score calculation to prevent penalizing users for inactive modules.
  static int calculateLifeBalanceScore({
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    // 1. Identify active domains
    final activeRoutines = routines.where((r) => (r['isArchived'] as int? ?? 0) == 0).toList();
    if (activeRoutines.isEmpty) return 100;

    final activeDomains = activeRoutines.map((r) => mapCategoryToDomain(r['category'] as String)).toSet();
    final n = activeDomains.length;

    if (n <= 1) return 100;

    // 2. Count completions per active domain
    final domainCounts = <String, int>{for (final d in activeDomains) d: 0};
    var totalCompletions = 0;

    // Load routineId to domain mapping
    final routineToDomain = {
      for (final r in activeRoutines) r['id'] as String: mapCategoryToDomain(r['category'] as String)
    };

    for (final comp in routineCompletions) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != null && activeDomains.contains(domain)) {
        final type = comp['resultType'] as String? ?? 'FULL';
        if (type != 'CANNOT_NOW' && type != 'SNOOZED') {
          domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
          totalCompletions++;
        }
      }
    }

    if (totalCompletions == 0) return 100;

    // 3. Compute normalized variance
    final mu = 1.0 / n;
    var sumSquaredDiffs = 0.0;

    for (final domain in activeDomains) {
      final p = (domainCounts[domain] ?? 0) / totalCompletions;
      sumSquaredDiffs += (p - mu) * (p - mu);
    }

    final variance = sumSquaredDiffs / n;
    final maxVariance = (n - 1) / (n * n);

    final normalizedVariance = maxVariance > 0 ? (variance / maxVariance) : 0.0;
    final score = 100 * (1.0 - normalizedVariance);

    return score.round().clamp(0, 100);
  }

  /// Calculates the distribution percentages for each of the 6 domains.
  static Map<String, double> calculateCategoryDistribution({
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    final activeRoutines = routines.where((r) => (r['isArchived'] as int? ?? 0) == 0).toList();
    final routineToDomain = {
      for (final r in activeRoutines) r['id'] as String: mapCategoryToDomain(r['category'] as String)
    };

    final domainCounts = <String, int>{
      'RELIGION': 0,
      'HEALTH': 0,
      'LEARNING': 0,
      'WORK': 0,
      'PERSONAL': 0,
      'FREE': 0,
    };
    var total = 0;

    for (final comp in routineCompletions) {
      final rId = comp['routineId'] as String;
      final domain = routineToDomain[rId];
      if (domain != null) {
        final type = comp['resultType'] as String? ?? 'FULL';
        if (type != 'CANNOT_NOW' && type != 'SNOOZED') {
          domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
          total++;
        }
      }
    }

    final distribution = <String, double>{};
    domainCounts.forEach((domain, count) {
      distribution[domain] = total > 0 ? (count / total) * 100.0 : 0.0;
    });

    return distribution;
  }

  /// Calculates the balance trend scores historically (e.g. weekly).
  static Map<String, int> calculateBalanceTrend({
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    // We group completions into 4 weekly windows: 0-7 days ago, 8-14, 15-21, 22-28
    final now = DateTime.now();
    final trends = <String, int>{};

    for (var w = 0; w < 4; w++) {
      final start = now.subtract(Duration(days: (w + 1) * 7));
      final end = now.subtract(Duration(days: w * 7));

      final wCompletions = routineCompletions.where((comp) {
        final time = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
        return time.isAfter(start) && time.isBefore(end);
      }).toList();

      final score = calculateLifeBalanceScore(
        routines: routines,
        routineCompletions: wCompletions,
      );

      trends['هفته ${w + 1}'] = score;
    }

    return trends;
  }
}
