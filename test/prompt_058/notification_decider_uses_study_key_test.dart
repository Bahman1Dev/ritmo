import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/notification_decider.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  test('NotificationDecider uses module_study_enabled for Category.konkur', () {
    final studyRoutine = Routine(
      id: 'routine_study_test',
      title: 'مطالعه و تست',
      category: Category.konkur,
      timeOfDay: '16:00',
    );

    // With module_study_enabled = 'true', decide returns sendStandard
    final outcomeEnabled = NotificationDecider.decide(
      routine: studyRoutine,
      appSettings: {'module_study_enabled': 'true'},
      isCurrentZoneBlocked: false,
    );
    expect(outcomeEnabled, equals(DecisionOutcome.sendStandard));

    // With module_study_enabled = 'false', decide returns ignore
    final outcomeDisabled = NotificationDecider.decide(
      routine: studyRoutine,
      appSettings: {'module_study_enabled': 'false'},
      isCurrentZoneBlocked: false,
    );
    expect(outcomeDisabled, equals(DecisionOutcome.ignore));
  });
}
