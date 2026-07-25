import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/utils/relative_time_formatter.dart';

void main() {
  group('RelativeTimeFormatter Tests', () {
    final now = DateTime(2026, 7, 26, 12, 0);

    test('durationFa formats hours and minutes properly in Persian digits', () {
      expect(RelativeTimeFormatter.durationFa(45), equals('۴۵ دقیقه'));
      expect(RelativeTimeFormatter.durationFa(90), equals('۱ ساعت و ۳۰ دقیقه'));
      expect(RelativeTimeFormatter.durationFa(180), equals('۳ ساعت'));
    });

    test('untilFa handles future minutes (< 60)', () {
      final target = now.add(const Duration(minutes: 42));
      expect(RelativeTimeFormatter.untilFa(target, now: now), equals('تا ۴۲ دقیقه دیگر'));
    });

    test('untilFa handles future hours same day', () {
      final target = now.add(const Duration(minutes: 222));
      expect(RelativeTimeFormatter.untilFa(target, now: now), equals('تا ۳ ساعت و ۴۲ دقیقه دیگر'));
    });

    test('untilFa handles exact current time', () {
      expect(RelativeTimeFormatter.untilFa(now, now: now), equals('همین حالا'));
    });

    test('untilFa handles recent past (-15 mins)', () {
      final target = now.subtract(const Duration(minutes: 15));
      expect(RelativeTimeFormatter.untilFa(target, now: now), equals('۱۵ دقیقه پیش'));
    });

    test('untilFa handles older past (-130 mins)', () {
      final target = now.subtract(const Duration(minutes: 130));
      expect(RelativeTimeFormatter.untilFa(target, now: now), equals('۲ ساعت و ۱۰ دقیقه پیش'));
    });

    test('untilFa handles tomorrow times', () {
      final tomorrowTarget = DateTime(2026, 7, 27, 5, 0);
      expect(RelativeTimeFormatter.untilFa(tomorrowTarget, now: now), equals('فردا ساعت ۰۵:۰۰'));
    });

    test('untilFa handles multi-day future', () {
      final futureTarget = DateTime(2026, 7, 29, 5, 0);
      expect(RelativeTimeFormatter.untilFa(futureTarget, now: now), equals('۳ روز دیگر · ساعت ۰۵:۰۰'));
    });
  });
}
