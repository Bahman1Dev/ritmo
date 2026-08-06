import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/domain/engines/cache/cache_entry.dart';
import 'package:ritmo/core/domain/engines/cache/engine_key.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';

void main() {
  test('1. different inputs produce different cache entries', () async {
    final key1 = EngineKey(GoalsEngine, 'key-1');
    final key2 = EngineKey(GoalsEngine, 'key-2');
    expect(key1, isNot(equals(key2)));
  });

  test('2. toggling a goal step changes the GoalsEngine fingerprint', () async {
    final engine = GoalsEngine();
    final step = GoalStep(
      id: 'step-1',
      goalId: 'goal-1',
      title: 'Step 1',
      isCompleted: false,
      displayOrder: 1,
      createdAt: 1000,
    );
    final inputBefore = GoalsEngineInput(
      goals: [
        Goal(
          id: 'goal-1',
          title: 'Goal 1',
          goalType: GoalLevel.daily,
          createdAt: 1000,
          updatedAt: 1000,
        ),
      ],
      stepsByGoal: {
        'goal-1': [step]
      },
      courses: [],
      courseSessions: [],
      konkurSubjects: [],
      konkurTopics: [],
      konkurPlanItems: [],
      routineCompletions: [],
      today: DateTime(2026, 3, 20),
    );

    final toggledStep = GoalStep(
      id: 'step-1',
      goalId: 'goal-1',
      title: 'Step 1',
      isCompleted: true,
      displayOrder: 1,
      createdAt: 1000,
      completedAt: 2000,
    );
    final inputAfter = GoalsEngineInput(
      goals: [
        Goal(
          id: 'goal-1',
          title: 'Goal 1',
          goalType: GoalLevel.daily,
          createdAt: 1000,
          updatedAt: 1000,
        ),
      ],
      stepsByGoal: {
        'goal-1': [toggledStep]
      },
      courses: [],
      courseSessions: [],
      konkurSubjects: [],
      konkurTopics: [],
      konkurPlanItems: [],
      routineCompletions: [],
      today: DateTime(2026, 3, 20),
    );

    final before = engine.fingerprint(inputBefore);
    final after = engine.fingerprint(inputAfter);
    expect(after, isNot(equals(before)));
  });

  test('4. cache expires when dayStamp changes', () async {
    final entry = CacheEntry<int>(
      data: 42,
      fingerprint: 'fp1',
      computedAt: DateTime.now(),
      dayStamp: '2026-03-20',
      ttl: const Duration(minutes: 5),
    );
    expect(entry.isFresh('2026-03-20', DateTime.now()), isTrue);
    expect(entry.isFresh('2026-03-21', DateTime.now()), isFalse);
  });
}
