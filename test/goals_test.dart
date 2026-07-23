import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/logic/goal_progress_calculator.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

void main() {
  group('Goals & Progress Calculator Tests', () {
    test('Childless goal with no steps returns 1.0 if COMPLETED, else 0.0', () {
      final goals = [
        Goal(id: 'g1', title: 'Completed Goal', goalType: GoalLevel.daily, status: 'COMPLETED', createdAt: 0, updatedAt: 0),
        Goal(id: 'g2', title: 'Active Goal', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      ];

      final stepsByGoal = <String, List<GoalStep>>{};

      expect(goalProgress('g1', goals, stepsByGoal), 1.0);
      expect(goalProgress('g2', goals, stepsByGoal), 0.0);
    });

    test('Childless goal with steps returns completed steps ratio', () {
      final goals = [
        Goal(id: 'g1', title: 'Goal 1', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      ];

      final stepsByGoal = {
        'g1': [
          GoalStep(id: 's1', goalId: 'g1', title: 'Step 1', isCompleted: true, displayOrder: 1, createdAt: 0),
          GoalStep(id: 's2', goalId: 'g1', title: 'Step 2', isCompleted: false, displayOrder: 2, createdAt: 0),
          GoalStep(id: 's3', goalId: 'g1', title: 'Step 3', isCompleted: true, displayOrder: 3, createdAt: 0),
        ]
      };

      expect(goalProgress('g1', goals, stepsByGoal), closeTo(2 / 3, 0.0001));
    });

    test('Parent goal returns average of children progress recursively', () {
      final goals = [
        Goal(id: 'parent', title: 'Parent', goalType: GoalLevel.weekly, createdAt: 0, updatedAt: 0),
        Goal(id: 'child1', parentGoalId: 'parent', title: 'Child 1', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
        Goal(id: 'child2', parentGoalId: 'parent', title: 'Child 2', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
        Goal(id: 'grandchild', parentGoalId: 'child2', title: 'Grandchild', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      ];

      final stepsByGoal = {
        'child1': [
          GoalStep(id: 's1', goalId: 'child1', title: 'Step 1', isCompleted: true, displayOrder: 1, createdAt: 0),
          GoalStep(id: 's2', goalId: 'child1', title: 'Step 2', isCompleted: false, displayOrder: 2, createdAt: 0),
        ],
        'grandchild': [
          GoalStep(id: 's3', goalId: 'grandchild', title: 'Step 3', isCompleted: true, displayOrder: 1, createdAt: 0),
        ]
      };

      // child1 progress = 1/2 = 0.5
      // child2 has child (grandchild). grandchild progress = 1/1 = 1.0. So child2 progress = 1.0.
      // parent progress = (child1 + child2) / 2 = (0.5 + 1.0) / 2 = 0.75.
      expect(goalProgress('parent', goals, stepsByGoal), 0.75);
    });

    test('Loop detection prevents infinite recursion and returns 0.0', () {
      final goals = [
        Goal(id: 'g1', parentGoalId: 'g2', title: 'Goal 1', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
        Goal(id: 'g2', parentGoalId: 'g1', title: 'Goal 2', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      ];

      final stepsByGoal = <String, List<GoalStep>>{};

      expect(goalProgress('g1', goals, stepsByGoal), 0.0);
    });
  });

  group('GoalsEngine Tests', () {
    test('calculate aggregates all three sources into upcoming timeline sorted by date', () async {
      final today = DateTime(2026, 6, 24); // 2026-06-24
      const todayStr = '2026-06-24';
      const tomorrowStr = '2026-06-25';

      final goals = <Goal>[
        Goal(id: 'g1', title: 'Goal 1', goalType: GoalLevel.weekly, createdAt: 0, updatedAt: 0),
      ];

      final steps = <String, List<GoalStep>>{
        'g1': [
          GoalStep(id: 'step1', goalId: 'g1', title: 'Goal Step 1', isCompleted: false, displayOrder: 1, createdAt: 0, scheduledDate: todayStr),
        ]
      };

      final courses = <Course>[
        Course(
          id: 'c1',
          title: 'Course 1',
          totalSessions: 5,
          sessionDurationMinutes: 45,
          createdAt: 0,
          updatedAt: 0,
          courseType: CourseType.video,
          preferredDays: [],
        ),
      ];

      final sessions = <CourseSession>[
        CourseSession(
          id: 's1',
          courseId: 'c1',
          sessionNumber: 1,
          plannedDate: tomorrowStr,
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final subjects = <KonkurSubject>[
        KonkurSubject(id: 'sub1', name: 'Subject 1', createdAt: 0, updatedAt: 0),
      ];
      final topics = <KonkurTopic>[
        KonkurTopic(id: 'top1', subjectId: 'sub1', name: 'Topic 1', createdAt: 0, updatedAt: 0),
      ];
      final planItems = <KonkurPlanItem>[
        KonkurPlanItem(id: 'pi1', dateIso: todayStr, subjectId: 'sub1', topicId: 'top1', plannedMinutes: 60, createdAt: 0),
      ];

      final input = GoalsEngineInput(
        goals: goals,
        stepsByGoal: steps,
        courses: courses,
        courseSessions: sessions,
        konkurSubjects: subjects,
        konkurTopics: topics,
        konkurPlanItems: planItems,
        routineCompletions: [],
        today: today,
      );

      final engine = GoalsEngine();
      final output = await engine.calculate(input);

      expect(output.activeGoalsCount, 1);
      expect(output.completedGoalsCount, 0);
      expect(output.todaySteps.length, 1);
      expect(output.todaySteps.first.id, 'step1');

      // Timeline should contain GoalStep (today), KonkurPlanItem (today), and CourseSession (tomorrow)
      expect(output.upcomingTimeline.length, 3);
      
      // Sorted by date: today items first, tomorrow items last
      expect(output.upcomingTimeline[0].dateIso, todayStr);
      expect(output.upcomingTimeline[1].dateIso, todayStr);
      expect(output.upcomingTimeline[2].dateIso, tomorrowStr);

      // Verify sources
      final sources = output.upcomingTimeline.map((item) => item.source).toList();
      expect(sources, contains(TimelineSource.goalStep));
      expect(sources, contains(TimelineSource.konkurPlan));
      expect(sources, contains(TimelineSource.courseSession));
    });

    test('linkedRoutineStatus calculates streaks and counts correctly', () async {
      final today = DateTime(2026, 6, 24);
      const todayStr = '2026-06-24';
      const yesterdayStr = '2026-06-23';
      const dayBeforeStr = '2026-06-22';

      final goals = <Goal>[
        Goal(id: 'g1', title: 'Goal 1', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      ];

      final steps = <String, List<GoalStep>>{
        'g1': [
          GoalStep(
            id: 'step1',
            goalId: 'g1',
            title: 'Step with Routine',
            isCompleted: false,
            displayOrder: 1,
            createdAt: 0,
            linkedRoutineId: 'r1',
          ),
        ]
      };

      // completions for r1: today, yesterday, dayBefore (streak = 3)
      final completions = <Map<String, dynamic>>[
        {'routineId': 'r1', 'completionDate': todayStr, 'resultType': 'COMPLETED'},
        {'routineId': 'r1', 'completionDate': yesterdayStr, 'resultType': 'COMPLETED'},
        {'routineId': 'r1', 'completionDate': dayBeforeStr, 'resultType': 'COMPLETED'},
        {'routineId': 'r1', 'completionDate': '2026-06-20', 'resultType': 'SNOOZED'}, // Should be excluded
      ];

      final input = GoalsEngineInput(
        goals: goals,
        stepsByGoal: steps,
        courses: [],
        courseSessions: [],
        konkurSubjects: [],
        konkurTopics: [],
        konkurPlanItems: [],
        routineCompletions: completions,
        today: today,
      );

      final engine = GoalsEngine();
      final output = await engine.calculate(input);

      expect(output.linkedRoutineStatus.containsKey('step1'), true);
      final status = output.linkedRoutineStatus['step1']!;
      expect(status.doneCount, 3); // excluding SNOOZED
      expect(status.streak, 3);
    });
  });
}
