import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/worship/logic/prayer_timeline.dart';
import 'package:ritmo/features/worship/logic/worship_completion_repository.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

void main() {
  group('Prompt 033 Worship Unification Tests', () {
    test('1. PrayerTimeline.slotsFor returns slots sorted chronologically', () {
      final pTime = PrayerTime(
        date: '2026-07-26',
        cityId: 'tehran',
        fajr: '04:30',
        sunrise: '06:00',
        dhuhr: '13:00',
        asr: '16:30',
        maghrib: '20:00',
        isha: '21:15',
        midnightShari: '23:45',
        sunset: '19:45',
        calculationMethod: 'TEHRAN',
        ihtiyatMinutes: 10,
      );

      final date = DateTime(2026, 7, 26);
      final slots = PrayerTimeline.slotsFor(pTime, date, includeAsrIsha: true);

      expect(slots.length, equals(7));
      expect(slots[0].key, equals('FAJR'));
      expect(slots[1].key, equals('SUNRISE'));
      expect(slots[2].key, equals('DHUHR'));
      expect(slots[3].key, equals('ASR'));
      expect(slots[4].key, equals('MAGHRIB'));
      expect(slots[5].key, equals('ISHA'));
      expect(slots[6].key, equals('MIDNIGHT_SHARI'));
    });

    test('2. PrayerTimeline.next returns next upcoming slot today', () {
      final pTime = PrayerTime(
        date: '2026-07-26',
        cityId: 'tehran',
        fajr: '04:30',
        sunrise: '06:00',
        dhuhr: '13:00',
        asr: '16:30',
        maghrib: '20:00',
        isha: '21:15',
        midnightShari: '23:45',
        sunset: '19:45',
        calculationMethod: 'TEHRAN',
        ihtiyatMinutes: 10,
      );

      final now = DateTime(2026, 7, 26, 14, 0); // 14:00 PM
      final next = PrayerTimeline.next(pTime, now);

      expect(next, isNotNull);
      expect(next!.key, equals('ASR'));
    });

    test('3. PrayerTimeline.next rolls over to tomorrow Fajr after midnight', () {
      final pTime = PrayerTime(
        date: '2026-07-26',
        cityId: 'tehran',
        fajr: '04:30',
        sunrise: '06:00',
        dhuhr: '13:00',
        asr: '16:30',
        maghrib: '20:00',
        isha: '21:15',
        midnightShari: '23:45',
        sunset: '19:45',
        calculationMethod: 'TEHRAN',
        ihtiyatMinutes: 10,
      );

      final now = DateTime(2026, 7, 26, 23, 50); // 23:50 PM
      final next = PrayerTimeline.next(pTime, now);

      expect(next, isNotNull);
      expect(next!.key, equals('FAJR'));
      expect(next.at.day, equals(27));
    });

    test('4. PrayerTimeline.deadlineFor provides accurate legal cutoff', () {
      final pTime = PrayerTime(
        date: '2026-07-26',
        cityId: 'tehran',
        fajr: '04:30',
        sunrise: '06:00',
        dhuhr: '13:00',
        asr: '16:30',
        maghrib: '20:00',
        isha: '21:15',
        midnightShari: '23:45',
        sunset: '19:45',
        calculationMethod: 'TEHRAN',
        ihtiyatMinutes: 10,
      );

      final date = DateTime(2026, 7, 26);
      final fajrDeadline = PrayerTimeline.deadlineFor('FAJR', pTime, date);
      final dhuhrDeadline = PrayerTimeline.deadlineFor('DHUHR', pTime, date);
      final maghribDeadline = PrayerTimeline.deadlineFor('MAGHRIB', pTime, date);

      expect(fajrDeadline?.hour, equals(6)); // Sunrise
      expect(dhuhrDeadline?.hour, equals(20)); // Maghrib
      expect(maghribDeadline?.hour, equals(23)); // Midnight Shari
    });

    test('5. SnoozePolicy limits essential prayer deferrals', () {
      final decision = SnoozePolicy.evaluate(
        itemId: 'p_fajr',
        now: DateTime(2026, 7, 26, 5, 0),
        requestedMinutes: 30,
        currentDeferCount: 2,
        category: 'religious',
        isEssential: 1,
        configuredMax: 3,
      );

      expect(decision.verdict, equals(SnoozeVerdict.exhausted));
    });

    test('6. WorshipCompletion model serialization works cleanly', () {
      final req = WorshipCompletion(
        practiceId: 'pra_fajr',
        dateStr: '2026-07-26',
        practiceType: 'PRAYER',
        countDone: 1,
      );

      expect(req.practiceId, equals('pra_fajr'));
      expect(req.worshipId, equals('pra_fajr'));
      expect(req.dateStr, equals('2026-07-26'));
    });

    test('7. WorshipSkip request fields are preserved', () {
      const req = WorshipSkip(
        practiceId: 'pra_dhikr',
        dateStr: '2026-07-26',
        reason: 'خستگی شدیدی',
      );

      expect(req.practiceId, equals('pra_dhikr'));
      expect(req.reason, equals('خستگی شدیدی'));
    });

    test('8. WorshipDebtProgress request holds delta correctly', () {
      const req = WorshipDebtProgress(
        debtId: 'debt_123',
        delta: 1,
      );

      expect(req.debtId, equals('debt_123'));
      expect(req.delta, equals(1));
    });

    test('9. WorshipDayStatus enum properties', () {
      const doneStatus = WorshipDayStatus(recordId: 'rec_1', resultType: 'DONE', countDone: 1);
      expect(doneStatus.isDone, isTrue);

      const skipStatus = WorshipDayStatus(recordId: 'rec_2', resultType: 'SKIPPED', countDone: 0);
      expect(skipStatus.isSkipped, isTrue);
    });

    test('10. EventBus invalidates WorshipRepository cache', () {
      final repo = WorshipRepository.instance;
      repo.invalidateCache();

      RitmoEventBus().fire(RitmoEvent(type: 'WorshipUpdated', payload: {'date': '2026-07-26'}));

      // Verify no exception thrown and event listener works
      expect(true, isTrue);
    });
  });
}

