import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';

void main() {
  test('AlarmSchedulerService correctly calculates overnight quiet hours window (23:00 to 07:00)', () {
    const startStr = '23:00';
    const endStr = '07:00';

    // 23:30 is during quiet hours
    final nightTime = DateTime(2026, 8, 8, 23, 30);
    expect(AlarmSchedulerService.isTimeInQuietHours(nightTime, startStr, endStr), isTrue);

    // 03:00 is during quiet hours
    final earlyMorning = DateTime(2026, 8, 8, 3, 0);
    expect(AlarmSchedulerService.isTimeInQuietHours(earlyMorning, startStr, endStr), isTrue);

    // 12:00 noon is NOT during quiet hours
    final noonTime = DateTime(2026, 8, 8, 12, 0);
    expect(AlarmSchedulerService.isTimeInQuietHours(noonTime, startStr, endStr), isFalse);

    // Adjusted time moves to endStr (07:00)
    final adjusted = AlarmSchedulerService.adjustTimeForQuietHours(nightTime, endStr);
    expect(adjusted.hour, equals(7));
    expect(adjusted.minute, equals(0));
  });
}
