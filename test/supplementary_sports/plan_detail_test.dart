import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_plan_day_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Plan Day Detail and Editing Tests', () {
    test('SSInlineAiSuggestion constructor mapping details', () {
      final suggestion = SSInlineAiSuggestion(
        id: 'sug_test',
        message: 'پیشنهاد مربی هوشمند',
        crossRefId: 'ref_1',
        newWeight: 15,
      );

      expect(suggestion.id, equals('sug_test'));
      expect(suggestion.newWeight, equals(15.0));
      expect(suggestion.crossRefId, equals('ref_1'));
    });
  });
}
