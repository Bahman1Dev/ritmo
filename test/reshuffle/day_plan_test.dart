import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/reshuffle/day_plan.dart';

void main() {
  test('1. reshuffle preserves fixed items and orders flexible items by priority', () {
    final fixedItem = DayPlanItem(
      id: 'prayer-1',
      title: 'Prayer',
      domain: 'prayer',
      durationMinutes: 20,
      priority: 1,
      isFixedTime: true,
    );
    final lowFlex = DayPlanItem(
      id: 'task-low',
      title: 'Low Priority Task',
      domain: 'routine',
      durationMinutes: 45,
      priority: 5,
      isFixedTime: false,
    );
    final highFlex = DayPlanItem(
      id: 'task-high',
      title: 'High Priority Task',
      domain: 'routine',
      durationMinutes: 30,
      priority: 2,
      isFixedTime: false,
    );

    final plan = DayPlan(items: [lowFlex, fixedItem, highFlex]);
    final reshuffled = plan.reshuffle();

    expect(reshuffled.items[0].id, equals('prayer-1'));
    expect(reshuffled.items[1].id, equals('task-high'));
    expect(reshuffled.items[2].id, equals('task-low'));
  });
}
