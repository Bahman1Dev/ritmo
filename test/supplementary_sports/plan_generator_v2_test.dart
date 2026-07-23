import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';

import '../migration_test.dart'; // Import MockDatabase subclass

class PlanTestDatabase extends MockDatabase {

  PlanTestDatabase({required this.exercises, required this.suitability});
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> suitability;
  final List<Map<String, dynamic>> insertedPlans = [];
  final List<Map<String, dynamic>> insertedCrossRefs = [];

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('ss_exercise_set_suitability')) {
      final setCode = arguments![0]! as String;
      final joined = <Map<String, Object?>>[];
      for (final ex in exercises) {
        final suit = suitability.firstWhere(
          (s) => s['exercise_id'] == ex['id'] && s['set_code'] == setCode,
          orElse: () => <String, Object>{},
        );
        if (suit.isNotEmpty && (suit['suitability'] as int? ?? 0) > 0) {
          joined.add({
            ...ex,
            'suitability': suit['suitability'],
            'suitability_lowerbody': suit['suitability_lowerbody'] ?? -1,
            'suitability_abscore': suit['suitability_abscore'] ?? -1,
            'suitability_back': suit['suitability_back'] ?? -1,
            'suitability_upperbody': suit['suitability_upperbody'] ?? -1,
            'set_difficulty': suit['difficulty'] ?? 2,
            'set_sort_order': suit['order'] ?? 0,
            'set_skill_required': suit['skill_required'] ?? -1,
            'set_skill_max': suit['skill_max'] ?? -1,
          });
        }
      }
      return joined;
    }
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == 'ss_workout_plan') {
      insertedPlans.add(values);
    } else if (table == 'ss_workout_exercise_crossref') {
      insertedCrossRefs.add(values);
    }
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (table == 'ss_workout_plan') {
      insertedPlans.clear();
    } else if (table == 'ss_workout_exercise_crossref') {
      insertedCrossRefs.clear();
    }
    return 1;
  }
}

void main() {
  group('PlanGenerator V2 Set-Based Engine Tests', () {
    final mockExercises = [
      {
        'id': 'bo009_squats',
        'name': 'Squats',
        'category': 'lower_body',
        'equipment': 'bodyweightOnly',
        'toolsRequired': '[]',
        'noisy': 0,
        'impact': 1,
        'skillRequired': 1,
        'skill_max': 5,
        'sexyness_m': 3,
        'sexyness_f': 5,
        'looksCool': 4,
        'weightSupported': 0,
      },
      {
        'id': 'bo002_mountain_climbers',
        'name': 'Mountain Climbers',
        'category': 'core',
        'equipment': 'bodyweightOnly',
        'toolsRequired': '[]',
        'noisy': 1,
        'impact': 2, // Noisy high impact
        'skillRequired': 2,
        'skill_max': 6,
        'sexyness_m': 4,
        'sexyness_f': 4,
        'looksCool': 3,
        'weightSupported': 0,
      },
      {
        'id': 'bo111_plank_pose',
        'name': 'Plank',
        'category': 'core',
        'equipment': 'bodyweightOnly',
        'toolsRequired': '[]',
        'noisy': 0,
        'impact': 0,
        'skillRequired': 1,
        'skill_max': 8,
        'sexyness_m': 5,
        'sexyness_f': 5,
        'looksCool': 2,
        'weightSupported': 0,
      },
      {
        'id': 'bo001_warmup',
        'name': 'Warmup stretching',
        'category': 'warmup',
        'equipment': 'bodyweightOnly',
        'toolsRequired': '[]',
        'noisy': 0,
        'impact': 0,
        'skillRequired': 1,
        'skill_max': 10,
        'sexyness_m': 1,
        'sexyness_f': 1,
        'looksCool': 1,
        'weightSupported': 0,
      },
      {
        'id': 'bo002_cooldown',
        'name': 'Cooldown stretching',
        'category': 'stretching',
        'equipment': 'bodyweightOnly',
        'toolsRequired': '[]',
        'noisy': 0,
        'impact': 0,
        'skillRequired': 1,
        'skill_max': 10,
        'sexyness_m': 1,
        'sexyness_f': 1,
        'looksCool': 1,
        'weightSupported': 0,
      }
    ];

    final mockSuitability = [
      {'exercise_id': 'bo009_squats', 'set_code': 'full_body', 'suitability': 9, 'difficulty': 2, 'order': 2},
      {'exercise_id': 'bo002_mountain_climbers', 'set_code': 'full_body', 'suitability': 8, 'difficulty': 3, 'order': 3},
      {'exercise_id': 'bo111_plank_pose', 'set_code': 'full_body', 'suitability': 7, 'difficulty': 1, 'order': 1},
      {'exercise_id': 'bo001_warmup', 'set_code': 'full_body', 'suitability': 10, 'difficulty': 1, 'order': 0},
      {'exercise_id': 'bo002_cooldown', 'set_code': 'full_body', 'suitability': 10, 'difficulty': 1, 'order': 0},

      {'exercise_id': 'bo009_squats', 'set_code': 'fem_tabata', 'suitability': 9, 'difficulty': 2, 'order': 1},
      {'exercise_id': 'bo111_plank_pose', 'set_code': 'fem_tabata', 'suitability': 8, 'difficulty': 1, 'order': 2},
      {'exercise_id': 'bo001_warmup', 'set_code': 'fem_tabata', 'suitability': 10, 'difficulty': 1, 'order': 0},
      {'exercise_id': 'bo002_cooldown', 'set_code': 'fem_tabata', 'suitability': 10, 'difficulty': 1, 'order': 0},

      {'exercise_id': 'bo009_squats', 'set_code': 'balance', 'suitability': 5, 'difficulty': 2, 'order': 1},
      {'exercise_id': 'bo111_plank_pose', 'set_code': 'balance', 'suitability': 8, 'difficulty': 1, 'order': 2},
      {'exercise_id': 'bo001_warmup', 'set_code': 'balance', 'suitability': 10, 'difficulty': 1, 'order': 0},
      {'exercise_id': 'bo002_cooldown', 'set_code': 'balance', 'suitability': 10, 'difficulty': 1, 'order': 0},
    ];

    test('Male advanced full body plan generation follows ordering rules', () async {
      final db = PlanTestDatabase(exercises: mockExercises, suitability: mockSuitability);
      final profile = SsUserProfile(
        goal: FitnessGoal.strength,
        experienceLevel: ExperienceLevel.advanced,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweightOnly],
        focusAreas: [BodyArea.fullBody],
        physicalLimitations: [Limitation.none],
        sessionDuration: SessionDuration.medium45,
        gender: 'MALE',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await SSPlanGenerator.generateSingleDayPlan(db, profile, week: 1, dayOfWeek: 1);

      expect(db.insertedPlans.length, equals(1));
      expect(db.insertedCrossRefs.isNotEmpty, isTrue);

      // Verify warmup first and cooldown last
      final first = db.insertedCrossRefs.first;
      final last = db.insertedCrossRefs.last;
      expect(first['exerciseId'], equals('bo001_warmup'));
      expect(last['exerciseId'], equals('bo002_cooldown'));
    });

    test('Apartment silent mode filters high impact exercises', () async {
      final db = PlanTestDatabase(exercises: mockExercises, suitability: mockSuitability);
      final profile = SsUserProfile(
        goal: FitnessGoal.bodyRecomposition,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweightOnly],
        focusAreas: [BodyArea.core],
        physicalLimitations: [Limitation.none],
        sessionDuration: SessionDuration.medium45,
        gender: 'MALE',
        neighborFriendly: true, // Silent mode active
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await SSPlanGenerator.generateSingleDayPlan(db, profile, week: 1, dayOfWeek: 1);

      // Mountain Climbers has impact = 2, so it should be filtered out
      for (final ref in db.insertedCrossRefs) {
        expect(ref['exerciseId'], isNot(equals('bo002_mountain_climbers')));
      }
    });

    test('Female profile selects female oriented sets', () async {
      final db = PlanTestDatabase(exercises: mockExercises, suitability: mockSuitability);
      final profile = SsUserProfile(
        goal: FitnessGoal.fatLoss,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweightOnly],
        focusAreas: [BodyArea.fullBody],
        physicalLimitations: [Limitation.none],
        sessionDuration: SessionDuration.medium45,
        gender: 'FEMALE',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Should choose fem_tabata set
      await SSPlanGenerator.generateSingleDayPlan(db, profile, week: 1, dayOfWeek: 1);
      expect(db.insertedCrossRefs.isNotEmpty, isTrue);
    });
  });
}
