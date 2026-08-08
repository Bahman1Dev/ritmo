import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/notification_decider.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  test('Essential routine bypasses quiet hours and blocked zones', () {
    final essentialRoutine = Routine(
      id: 'routine_essential_test',
      title: 'داروی حیاتی',
      category: Category.medical,
      isEssential: true,
      timeOfDay: '02:00',
    );

    final outcome = NotificationDecider.decide(
      routine: essentialRoutine,
      appSettings: {'module_medicine_enabled': 'true'},
      isCurrentZoneBlocked: true,
    );

    expect(outcome, equals(DecisionOutcome.sendStandard));
  });
}
