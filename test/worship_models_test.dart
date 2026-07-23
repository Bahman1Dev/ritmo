import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

void main() {
  group('Worship Models Unit Tests', () {
    test('1. WorshipPractice needsReset and isDeferExhausted', () {
      const practice = WorshipPractice(
        id: 'p_1',
        practiceType: 'PRAYER',
        title: 'نماز صبح',
        dailyDoneDate: '2026-06-22',
        deferCount: 2,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(practice.isDeferExhausted, isFalse);
      expect(practice.needsReset('2026-06-23'), isTrue);
      expect(practice.needsReset('2026-06-22'), isFalse);

      final practiceExhausted = practice.copyWith(deferCount: 3);
      expect(practiceExhausted.isDeferExhausted, isTrue);
    });

    test('2. PrayerTime nextPrayer and countdown calculations', () {
      const pTime = PrayerTime(
        date: '2026-06-23',
        cityId: 'TEHRAN_TEHRAN',
        fajr: '04:15',
        sunrise: '05:45',
        dhuhr: '12:08',
        asr: '16:00',
        maghrib: '19:30',
        isha: '20:30',
        midnightShari: '23:30',
        calculationMethod: 'TEHRAN_GEOPHYSICS',
        ihtiyatMinutes: 10,
      );

      // Current time: 10:00 AM (before Dhuhr)
      final now1 = DateTime(2026, 6, 23, 10);
      final next1 = pTime.nextPrayer(now1);
      expect(next1.key, equals('DHUHR'));
      expect(next1.value, equals(DateTime(2026, 6, 23, 12, 8)));

      // Current time: 10:00 PM (after Isha, before Fajr next day)
      final now2 = DateTime(2026, 6, 23, 22);
      final next2 = pTime.nextPrayer(now2);
      expect(next2.key, equals('FAJR'));
      expect(next2.value, equals(DateTime(2026, 6, 24, 4, 15)));
    });

    test('3. WorshipDebt progressPercent and daysToFinish', () {
      final debt = WorshipDebt(
        id: 'd_1',
        debtType: 'PRAYER',
        title: 'نماز قضا',
        totalCount: 30,
        remainingCount: 15,
        dailyTarget: 3,
        autoCreated: false,
        isArchived: false,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(debt.progressPercent, equals(50.0));
      expect(debt.daysToFinish, equals(5));

      final completedDebt = WorshipDebt(
        id: 'd_2',
        debtType: 'FAST',
        title: 'روزه قضا',
        totalCount: 10,
        remainingCount: 0,
        dailyTarget: 1,
        autoCreated: false,
        isArchived: false,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(completedDebt.progressPercent, equals(100.0));
      expect(completedDebt.daysToFinish, equals(0));
    });

    test('4. WorshipSeason isActiveNow', () {
      final now = DateTime.now();
      final monthStr = now.month.toString().padLeft(2, '0');
      final dayStr = now.day.toString().padLeft(2, '0');

      final season = WorshipSeason(
        id: 's_1',
        seasonType: 'FASTING',
        title: 'رمضان',
        startDate: '$monthStr-$dayStr', // MM-DD format
        endDate: '$monthStr-$dayStr',
        calendar: 'GREGORIAN',
        isActive: true,
        priorityWeight: 5,
        createdAt: 1000,
      );

      // Dynamic date always falls on today
      expect(season.isActiveNow(), isTrue);
    });

    test('5. English to Persian digit converter', () {
      expect(toPersianDigits('12345'), equals('۱۲۳۴۵'));
      expect(toPersianDigits('09876'), equals('۰۹۸۷۶'));
    });
  });
}
