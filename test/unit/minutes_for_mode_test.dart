import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';

void main() {
  group('DurationBounds & Mode Sanitization Tests', () {
    test('sanitize clamps values properly', () {
      expect(DurationBounds.sanitize(0), equals(1));
      expect(DurationBounds.sanitize(-10), equals(1));
      expect(DurationBounds.sanitize(30), equals(30));
      expect(DurationBounds.sanitize(2000), equals(1440));
    });

    test('Routine duration fallbacks work properly', () {
      final routine = Routine(
        id: 'test_r1',
        title: 'Workout',
        targetDurationMinutes: 45,
        lightDurationMinutes: 20,
        minimalDurationMinutes: 10,
        category: Category.fitness,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      expect(routine.targetDurationMinutes, equals(45));
      expect(routine.lightDurationMinutes, equals(20));
      expect(routine.minimalDurationMinutes, equals(10));
    });
  });
}
