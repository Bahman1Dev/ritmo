import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Home Dashboard Screen States & Logic Tests', () {
    test('SSHomeRestDay state constructor sets suggestions', () {
      const state = SSHomeRestDay(suggestion: 'تمرین امروز هوازی سبک است.');
      expect(state.suggestion, equals('تمرین today هوازی سبک است.'.replaceAll('today', 'امروز')));
    });

    test('SSHomeWorkoutReady state maps days and estimated durations', () {
      const state = SSHomeWorkoutReady(
        dayName: 'شنبه',
        dayOfWeek: 1,
        planId: 'plan_w1_1',
        workoutName: 'شکم',
        exerciseCount: 5,
        estimatedMinutes: 40,
        continuity: [false, false, false, false, false, false, false],
        weekTimeline: [true, true, true, false, false, false, false],
      );

      expect(state.dayName, equals('شنبه'));
      expect(state.estimatedMinutes, equals(40));
      expect(state.exerciseCount, equals(5));
      expect(state.workoutName, equals('شکم'));
    });

    test('Tired rest override value math and state persistence', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ss_tired_rest_override', 45);

      final val = prefs.getInt('ss_tired_rest_override');
      expect(val, equals(45));

      await prefs.remove('ss_tired_rest_override');
      expect(prefs.getInt('ss_tired_rest_override'), isNull);
    });
  });
}
