import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';

void main() {
  test('SnoozePolicy returns exhausted without throwing exception when defer count cap reached', () {
    final decision = SnoozePolicy.evaluate(
      itemId: 'r_123',
      now: DateTime(2026, 7, 26, 10, 0),
      requestedMinutes: 10,
      currentDeferCount: 3,
      configuredMax: 3,
    );

    expect(decision.verdict, equals(SnoozeVerdict.exhausted));
    expect(decision.remaining, equals(0));
    expect(decision.userMessage, contains('سقف تعویق'));
    expect(decision.exits, isNotEmpty);
  });
}
