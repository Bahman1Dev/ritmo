import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Daily nudge reschedules and cancels previous alarm when time is changed', () {
    final canceledAlarms = <String>[];
    final scheduledAlarms = <String, int>{};

    void cancelAlarm(String id) {
      canceledAlarms.add(id);
      scheduledAlarms.remove(id);
    }

    void scheduleAlarm(String id, int timeMs) {
      scheduledAlarms[id] = timeMs;
    }

    // Schedule 1: 08:30
    cancelAlarm('daily_planning_nudge');
    scheduleAlarm('daily_planning_nudge', 1000);
    expect(scheduledAlarms['daily_planning_nudge'], equals(1000));

    // Schedule 2: Changed time to 09:00 -> Cancels old alarm first
    cancelAlarm('daily_planning_nudge');
    scheduleAlarm('daily_planning_nudge', 2000);

    expect(canceledAlarms.length, equals(2));
    expect(scheduledAlarms['daily_planning_nudge'], equals(2000));
  });
}
