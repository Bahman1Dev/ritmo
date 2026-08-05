import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';

void main() {
  test('life balance with no routines is unknown', () {
    final res = LifeBalanceEngine.calculateLifeBalanceScore(
      routines: [],
      routineCompletions: [],
    );
    expect(res, isNull);
  });

  test('life balance needs ten completions', () {
    final routines = [
      {'id': 'r1', 'category': 'HEALTH', 'isArchived': 0},
      {'id': 'r2', 'category': 'WORK', 'isArchived': 0},
    ];
    final completions = List.generate(
      9,
      (i) => {'routineId': 'r1', 'resultType': 'FULL'},
    );

    final score9 = LifeBalanceEngine.calculateLifeBalanceScore(
      routines: routines,
      routineCompletions: completions,
    );
    expect(score9, isNull);

    final completions10 = List.generate(
      10,
      (i) => {'routineId': 'r1', 'resultType': 'FULL'},
    );
    final score10 = LifeBalanceEngine.calculateLifeBalanceScore(
      routines: routines,
      routineCompletions: completions10,
    );
    expect(score10, isNotNull);
  });

  test('balance trend keys are numeric', () {
    final trends = LifeBalanceEngine.calculateBalanceTrend(
      now: DateTime(2026, 1, 15),
      routines: [],
      routineCompletions: [],
    );
    expect(trends.keys, containsAll([1, 2, 3, 4]));
  });
}
