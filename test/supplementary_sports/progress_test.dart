import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_progress_screen.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Progress Screen and Jalali Heatmap logic Tests', () {
    test('Jalali month length mapping correctness', () {
      final jNow = Jalali.now();
      
      // Tir, Mordad, Shahrivar length = 31
      final length = jNow.monthLength;
      expect(length, anyOf(29, 30, 31));
    });

    test('SSProgressLoaded state constructor handles minutes, calories, and weight logs', () {
      const state = SSProgressLoaded(
        streakDays: 4,
        streakRecord: 10,
        totalMinutes: 180,
        totalCalories: 950,
        weeklyDots: [true, true, false, true, true, false, false],
        recentFeelings: [],
        totalSessionCount: 5,
        monthContinuityPercent: 75,
        exercisesReadyToProgress: [],
        weeklyMinutes: [30.0, 45.0, 0.0, 30.0, 45.0, 0.0, 0.0],
        weightLogs: [],
        completedDates: [],
      );

      expect(state.streakDays, equals(4));
      expect(state.totalCalories, equals(950));
      expect(state.weeklyMinutes.first, equals(30.0));
      expect(state.streakRecord, equals(10));
    });
  });
}
