import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/util/safe_map.dart';

class LifeBalanceEngineInput {
  LifeBalanceEngineInput({
    required this.now,
    required this.routines,
    required this.routineCompletions,
  });
  final DateTime now;
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> routineCompletions;
}

class LifeBalanceEngineOutput {
  LifeBalanceEngineOutput({
    required this.score,
    required this.distribution,
    required this.trend,
    this.skippedRows = 0,
  });
  final int? score;
  final Map<String, double> distribution;
  final Map<int, int?> trend;
  final int skippedRows;
}

class LifeBalanceEngine implements CachedEngine<LifeBalanceEngineInput, LifeBalanceEngineOutput> {
  static const int minCompletionsForBalance = 10;

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
      now: input.now,
      routines: input.routines,
      routineCompletions: input.routineCompletions,
    );
    return LifeBalanceEngineOutput(
      score: score,
      distribution: distribution,
      trend: trend,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(LifeBalanceEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  /// Maps a routine category database string to the analytical domains.
  static String mapCategoryToDomain(String dbCategory) {
    final clean = dbCategory.toLowerCase().trim();
    if (clean == 'religious') return 'RELIGION';
    if (clean == 'medical' || clean == 'fitness') return 'HEALTH';
    if (clean == 'learning' || clean == 'konkur') return 'LEARNING';
    if (clean == 'work') return 'WORK';
    if (clean == 'personal') return 'PERSONAL';
    if (clean == 'free') return 'FREE';
    return 'CUSTOM'; // T-3.8: Custom domain instead of mapping to FREE
  }

  /// Calculates the Life Balance Score (0 - 100) using normalized variance.
  /// Returns null if data is insufficient.
  static int? calculateLifeBalanceScore({
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    // 1. Identify active domains
    final activeRoutines = routines.where((r) => (r.readInt('isArchived') ?? 0) == 0).toList();
    if (activeRoutines.isEmpty) return null; // T-1.3: Data missing

    final activeDomains = activeRoutines
        .map((r) => mapCategoryToDomain(r.readString('category') ?? 'CUSTOM'))
        .toSet();
    final n = activeDomains.length;

    if (n <= 1) return null; // T-1.3: Single domain balance is meaningless

    // 2. Count completions per active domain
    final domainCounts = <String, int>{for (final d in activeDomains) d: 0};
    var totalCompletions = 0;

    final routineToDomain = <String, String>{};
    for (final r in activeRoutines) {
      final id = r.readString('id');
      if (id != null) {
        routineToDomain[id] = mapCategoryToDomain(r.readString('category') ?? 'CUSTOM');
      }
    }

    for (final comp in routineCompletions) {
      final rId = comp.readString('routineId');
      if (rId == null) continue;
      final domain = routineToDomain[rId];
      if (domain != null && activeDomains.contains(domain)) {
        final type = comp.readString('resultType') ?? 'FULL';
        if (type != 'CANNOT_NOW' && type != 'SNOOZED') {
          domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
          totalCompletions++;
        }
      }
    }

    if (totalCompletions < minCompletionsForBalance) return null; // T-1.3

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

  /// Calculates the distribution percentages for each of the domains.
  static Map<String, double> calculateCategoryDistribution({
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    final activeRoutines = routines.where((r) => (r.readInt('isArchived') ?? 0) == 0).toList();
    final routineToDomain = <String, String>{};
    for (final r in activeRoutines) {
      final id = r.readString('id');
      if (id != null) {
        routineToDomain[id] = mapCategoryToDomain(r.readString('category') ?? 'CUSTOM');
      }
    }

    final domainCounts = <String, int>{
      'RELIGION': 0,
      'HEALTH': 0,
      'LEARNING': 0,
      'WORK': 0,
      'PERSONAL': 0,
      'FREE': 0,
      'CUSTOM': 0,
    };
    var total = 0;

    for (final comp in routineCompletions) {
      final rId = comp.readString('routineId');
      if (rId == null) continue;
      final domain = routineToDomain[rId];
      if (domain != null) {
        final type = comp.readString('resultType') ?? 'FULL';
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

  /// Calculates the balance trend scores historically (T-3.9: numeric keys, injected time).
  static Map<int, int?> calculateBalanceTrend({
    required DateTime now,
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    final trends = <int, int?>{};

    for (var w = 0; w < 4; w++) {
      final start = now.subtract(Duration(days: (w + 1) * 7));
      final end = now.subtract(Duration(days: w * 7));

      final wCompletions = routineCompletions.where((comp) {
        final millis = comp.readInt('completionTime');
        if (millis == null) return false;
        final time = DateTime.fromMillisecondsSinceEpoch(millis);
        return time.isAfter(start) && time.isBefore(end);
      }).toList();

      final score = calculateLifeBalanceScore(
        routines: routines,
        routineCompletions: wCompletions,
      );

      trends[w + 1] = score; // T-3.9: Integer key 1..4 without Persian strings
    }

    return trends;
  }
}
