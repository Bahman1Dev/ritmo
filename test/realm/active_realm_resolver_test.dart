import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/zone_engine.dart';
import 'package:ritmo/core/domain/realm/active_realm_resolver.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  final DateTime currentTime;
  @override
  DateTime now() => currentTime;
}

void main() {
  group('ActiveRealmResolver & ZoneEngine Tests (Prompt 054)', () {
    final realmWork = RealmData(
      id: 'z_work',
      name: 'کار عمیق',
      colorHex: '#6366F1',
      icon: '💻',
      mode: RealmMode.focus,
      createdAt: 1000,
    );

    final realmSleep = RealmData(
      id: 'z_sleep',
      name: 'خواب و استراحت',
      colorHex: '#8B5CF6',
      icon: '🌙',
      mode: RealmMode.silent,
      createdAt: 2000,
    );

    final schedWork = RealmScheduleData(
      id: 's_work',
      zoneId: 'z_work',
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      startTime: '09:00',
      endTime: '17:00',
    );

    final schedSleepOvernight = RealmScheduleData(
      id: 's_sleep',
      zoneId: 'z_sleep',
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      startTime: '23:00',
      endTime: '05:00',
    );

    test('1. Overnight realm (23:00 - 05:00) is ACTIVE at 01:00 (ق-۱)', () {
      // 2026-08-08 01:30 AM
      final clock = TestClock(DateTime(2026, 8, 8, 1, 30));
      final resolver = ActiveRealmResolver(clock: clock);

      final state = resolver.resolve(
        realms: [realmWork, realmSleep],
        schedules: [schedWork, schedSleepOvernight],
      );

      expect(state, isA<ScheduledRealmState>());
      final scheduled = state as ScheduledRealmState;
      expect(scheduled.realm.id, equals('z_sleep'));
      expect(scheduled.realm.name, equals('خواب و استراحت'));
      expect(scheduled.remaining.inHours, equals(3)); // 01:30 to 05:00 = 3.5 hrs
    });

    test('2. Overnight realm (23:00 - 05:00) is ACTIVE at 23:30 (ق-۱)', () {
      // 2026-08-08 11:30 PM
      final clock = TestClock(DateTime(2026, 8, 8, 23, 30));
      final resolver = ActiveRealmResolver(clock: clock);

      final state = resolver.resolve(
        realms: [realmWork, realmSleep],
        schedules: [schedWork, schedSleepOvernight],
      );

      expect(state, isA<ScheduledRealmState>());
      final scheduled = state as ScheduledRealmState;
      expect(scheduled.realm.id, equals('z_sleep'));
      expect(scheduled.remaining.inMinutes, equals(330)); // 23:30 to 05:00 = 5.5 hrs
    });

    test('3. Free realm state is returned when outside all schedules (ق-۱۴, ق-۱۵)', () {
      // 2026-08-08 07:00 AM (between 05:00 and 09:00)
      final clock = TestClock(DateTime(2026, 8, 8, 7, 0));
      final resolver = ActiveRealmResolver(clock: clock);

      final state = resolver.resolve(
        realms: [realmWork, realmSleep],
        schedules: [schedWork, schedSleepOvernight],
      );

      expect(state, isA<FreeRealmState>());
      expect(state.isFree, isTrue);
    });

    test('4. Shorter duration schedule wins in overlapping schedules (ق-۹)', () {
      final realmShort = RealmData(
        id: 'z_meeting',
        name: 'جلسه فوری',
        colorHex: '#EF4444',
        icon: '⚡',
        mode: RealmMode.focus,
        createdAt: 3000,
      );

      final schedShort = RealmScheduleData(
        id: 's_meeting',
        zoneId: 'z_meeting',
        daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
        startTime: '10:00',
        endTime: '11:00', // 1 hour vs work 8 hours
      );

      // 2026-08-08 10:30 AM (both work 09-17 and meeting 10-11 active)
      final clock = TestClock(DateTime(2026, 8, 8, 10, 30));
      final resolver = ActiveRealmResolver(clock: clock);

      final state = resolver.resolve(
        realms: [realmWork, realmShort],
        schedules: [schedWork, schedShort],
      );

      expect(state, isA<ScheduledRealmState>());
      final scheduled = state as ScheduledRealmState;
      expect(scheduled.realm.id, equals('z_meeting'));
    });

    test('5. Manual override state takes precedence over scheduled realms (ق-۷, ق-۱۲)', () {
      final now = DateTime(2026, 8, 8, 10, 0); // During work realm 09-17
      final clock = TestClock(now);
      final resolver = ActiveRealmResolver(clock: clock);

      final overrideUntil = now.add(const Duration(minutes: 50)).millisecondsSinceEpoch;

      final state = resolver.resolve(
        realms: [realmWork, realmSleep],
        schedules: [schedWork, schedSleepOvernight],
        overrideRealmId: 'z_sleep',
        overrideUntilMs: overrideUntil,
      );

      expect(state, isA<ManualRealmState>());
      final manual = state as ManualRealmState;
      expect(manual.realm.id, equals('z_sleep'));
      expect(manual.remaining.inMinutes, equals(50));
    });

    test('6. ZoneEngine boundary conditions start-inclusive end-exclusive (ق-۸)', () {
      final timeExactStart = DateTime(2026, 8, 8, 9, 0);
      final timeExactEnd = DateTime(2026, 8, 8, 17, 0);

      expect(
        ZoneEngine.isTimeWithinRange(time: timeExactStart, startTimeStr: '09:00', endTimeStr: '17:00'),
        isTrue,
      );

      expect(
        ZoneEngine.isTimeWithinRange(time: timeExactEnd, startTimeStr: '09:00', endTimeStr: '17:00'),
        isFalse,
      );
    });
  });
}
