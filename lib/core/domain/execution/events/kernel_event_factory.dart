import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class KernelEventFactory {
  static RitmoEvent routineCreated({
    required DateTime now,
    required String? routineId,
  }) {
    return RitmoEvent(
      type: 'RoutineCreated',
      timestamp: now,
      payload: {'routineId': routineId},
    );
  }

  static RitmoEvent routineEdited({
    required DateTime now,
    required String? routineId,
    Map<String, dynamic> payload = const {},
  }) {
    return RitmoEvent(
      type: 'RoutineEdited',
      timestamp: now,
      payload: {
        'routineId': ?routineId,
        ...payload,
      },
    );
  }

  static RitmoEvent routineDeleted({
    required DateTime now,
    required String routineId,
  }) {
    return RitmoEvent(
      type: 'RoutineDeleted',
      timestamp: now,
      payload: {'routineId': routineId},
    );
  }

  static RitmoEvent routineCompleted({
    required DateTime now,
    required String routineId,
  }) {
    return RitmoEvent(
      type: 'RoutineCompleted',
      timestamp: now,
      payload: {'routineId': routineId},
    );
  }

  static RitmoEvent routineSkipped({
    required DateTime now,
    required String routineId,
  }) {
    return RitmoEvent(
      type: 'RoutineSkipped',
      timestamp: now,
      payload: {'routineId': routineId},
    );
  }
}
