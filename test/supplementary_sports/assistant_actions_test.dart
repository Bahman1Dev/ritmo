import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Assistant Action Types Registry Tests', () {
    test('AssistantActionType fromString parses new Coach actions correctly', () {
      final swapAct = AssistantActionType.fromString('swapExercise');
      expect(swapAct, equals(AssistantActionType.swapExercise));

      final quietAct = AssistantActionType.fromString('setQuietMode');
      expect(quietAct, equals(AssistantActionType.setQuietMode));

      final changeAct = AssistantActionType.fromString('changeSetProgram');
      expect(changeAct, equals(AssistantActionType.changeSetProgram));

      final rescheduleAct = AssistantActionType.fromString('rescheduleDay');
      expect(rescheduleAct, equals(AssistantActionType.rescheduleDay));
    });

    test('AssistantActionType labels in Persian are correctly mapped', () {
      expect(AssistantActionType.swapExercise.label, equals('تعویض حرکت ورزشی'));
      expect(AssistantActionType.setQuietMode.label, equals('تنظیم حالت بی‌صدا'));
      expect(AssistantActionType.changeSetProgram.label, equals('تغییر برنامه تمرین'));
      expect(AssistantActionType.rescheduleDay.label, equals('تغییر روز تمرین'));
    });
  });
}
