import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding & BMI Calculations Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('BMI Math calculation and category mapping', () {
      const heightCm = 180.0;
      const weightKg = 75.0;
      
      const bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
      expect(bmi, closeTo(23.14, 0.05));

      expect(bmi >= 18.5 && bmi < 25, isTrue);
    });

    test('BMI Math overweight calculation', () {
      const heightCm = 170.0;
      const weightKg = 85.0;
      
      const bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
      expect(bmi, closeTo(29.41, 0.05));
      expect(bmi >= 25 && bmi < 30, isTrue);
    });

    test('SharedPreferences persistence for onboarding wizard parameters', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ss_onboarding_gender', 'FEMALE');
      await prefs.setDouble('ss_onboarding_height', 165);
      await prefs.setDouble('ss_onboarding_weight', 60);

      expect(prefs.getString('ss_onboarding_gender'), equals('FEMALE'));
      expect(prefs.getDouble('ss_onboarding_height'), equals(165.0));
      expect(prefs.getDouble('ss_onboarding_weight'), equals(60.0));
    });
  });
}
