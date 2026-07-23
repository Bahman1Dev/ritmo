import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_notifier.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../migration_test.dart'; // Import MockDatabase subclass

class SessionTestDatabase extends MockDatabase {

  SessionTestDatabase({required this.exercises, required this.crossrefs});
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> crossrefs;

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('ss_workout_exercise_crossref')) {
      final joined = <Map<String, Object?>>[];
      for (final ref in crossrefs) {
        final ex = exercises.firstWhere((e) => e['id'] == ref['exerciseId'], orElse: () => {});
        joined.add({
          ...ref,
          'name': ex['name'] ?? 'Exercise Name',
          'category': ex['category'] ?? 'core',
          'equipment': ex['equipment'] ?? 'bodyweightOnly',
          'instructions': ex['instructions'] ?? '',
          'changeSides': ex['changeSides'] ?? 0,
          'repsDouble': ex['repsDouble'] ?? 0,
          'repsHint': ex['repsHint'] ?? '',
          'impact': ex['impact'] ?? 0,
          'noisy': ex['noisy'] ?? 0,
          'durationSeconds': ex['durationSeconds'] ?? 0,
        });
      }
      return joined;
    }
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('WorkoutSession State Machine MVI Tests', () {
    late SessionTestDatabase testDb;

    setUp(() {
      testDb = SessionTestDatabase(
        exercises: [
          {
            'id': 'ex_plank',
            'name': 'Plank',
            'category': 'core',
            'changeSides': 0,
            'durationSeconds': 30,
          },
          {
            'id': 'ex_lunges',
            'name': 'Lunges',
            'category': 'legs',
            'changeSides': 1, // Assymmetric side change
            'durationSeconds': 20,
          }
        ],
        crossrefs: [
          {
            'planId': 'plan_w1_1',
            'exerciseId': 'ex_plank',
            'orderIndex': 0,
            'targetSets': 2,
            'targetReps': 10,
            'targetWeight': 0.0,
          },
          {
            'planId': 'plan_w1_1',
            'exerciseId': 'ex_lunges',
            'orderIndex': 1,
            'targetSets': 1,
            'targetReps': 10,
            'targetWeight': 0.0,
          }
        ],
      );

      SharedPreferences.setMockInitialValues({});
      // Inject test database instance
      DatabaseHelper.databaseInstance = testDb;
    });

    const key = SSWorkoutPlanKey(planId: 'plan_w1_1', dayName: 'شنبه');

    test('Initializes session in preparing state and transitions correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(ssWorkoutProvider(key).notifier);

      await notifier.init();

      final state = container.read(ssWorkoutProvider(key));
      expect(state.isLoading, isFalse);
      expect(state.exercises.length, equals(2));
      expect(state.status, equals(SSWorkoutSessionStatus.preparing));
      expect(state.timerRemainingSeconds, equals(5));
      expect(state.currentExerciseIndex, equals(0));

      // Skip preparing -> transitions to countdown
      notifier.dispatch(const SkipRestTimer());
      final countdownState = container.read(ssWorkoutProvider(key));
      expect(countdownState.status, equals(SSWorkoutSessionStatus.countdown));
      expect(countdownState.timerRemainingSeconds, equals(3));
    });

    test('Pausing and resuming rest timer updates state and timestamps', () async {
      final container = ProviderContainer();
      final notifier = container.read(ssWorkoutProvider(key).notifier);

      await notifier.init();
      
      // Skip to countdown, then skip to exercise
      notifier.dispatch(const SkipRestTimer()); // to countdown
      notifier.dispatch(const SkipRestTimer()); // to exercising

      // In exercising (plank is timed: 30s)
      final activeState = container.read(ssWorkoutProvider(key));
      expect(activeState.status, equals(SSWorkoutSessionStatus.exercising));
      expect(activeState.timerTotalSeconds, equals(30));
      expect(activeState.isTimerPaused, isFalse);

      // Toggle pause
      notifier.dispatch(const PauseResumeTimer());
      expect(container.read(ssWorkoutProvider(key)).isTimerPaused, isTrue);

      // Resume
      notifier.dispatch(const PauseResumeTimer());
      expect(container.read(ssWorkoutProvider(key)).isTimerPaused, isFalse);
    });

    test('Side change triggers correctly for asymmetric exercises', () async {
      final container = ProviderContainer();
      final notifier = container.read(ssWorkoutProvider(key).notifier);

      await notifier.init();
      
      // Skip to next exercise (Lunges, which has changeSides = 1)
      notifier.dispatch(const SkipRestTimer()); // ex_plank prep
      notifier.dispatch(const SkipRestTimer()); // ex_plank countdown
      notifier.dispatch(const SkipRestTimer()); // complete set 1
      notifier.dispatch(const SkipRestTimer()); // rest timer -> prep set 2
      notifier.dispatch(const SkipRestTimer()); // countdown
      notifier.dispatch(const CompleteCurrentSet()); // complete set 2 -> feeling sheet
      
      notifier.dispatch(const DismissFeelingSheet()); // dismiss feeling sheet -> rest to next exercise
      notifier.dispatch(const SkipRestTimer()); // prep ex_lunges
      notifier.dispatch(const SkipRestTimer()); // countdown ex_lunges
      notifier.dispatch(const SkipRestTimer()); // start ex_lunges (exercising)

      final state = container.read(ssWorkoutProvider(key));
      expect(state.currentExerciseIndex, equals(1));
      expect(state.status, equals(SSWorkoutSessionStatus.exercising));
      expect(state.exercises[1].exercise.changeSides, isTrue);
    });
  });
}
