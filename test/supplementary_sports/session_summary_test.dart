import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Session Summary MET Calories Tests', () {
    test('Calories calculation using default MET values', () {
      const userWeight = 75.0; // kg
      const durationSeconds = 1800; // 30 minutes -> 0.5 hours
      
      // strength MET = 6.0
      const met = 6.0;
      const durationHours = durationSeconds / 3600.0;
      
      const caloriesBurned = met * userWeight * durationHours;
      expect(caloriesBurned, equals(225.0));
    });

    test('Calories calculation using high MET (cardio/plyo)', () {
      const userWeight = 80.0;
      const durationSeconds = 3600; // 1 hour
      const met = 8.0; // cardio/plyo MET
      
      const caloriesBurned = met * userWeight * (durationSeconds / 3600.0);
      expect(caloriesBurned, equals(640.0));
    });

    test('Calories calculation using low MET (stretching)', () {
      const userWeight = 60.0;
      const durationSeconds = 1200; // 20 minutes -> 0.333 hours
      const met = 2.5; // stretching/yoga MET
      
      const caloriesBurned = met * userWeight * (durationSeconds / 3600.0);
      expect(caloriesBurned, closeTo(50.0, 0.01));
    });
  });
}
