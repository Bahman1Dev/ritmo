import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/routines/shared/routine_actions.dart';

void main() {
  test('RoutineActions exists and exposes completeRoutine & snoozeRoutine', () {
    expect(RoutineActions.completeRoutine, isNotNull);
    expect(RoutineActions.snoozeRoutine, isNotNull);
  });
}
