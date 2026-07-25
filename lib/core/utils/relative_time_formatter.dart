import 'package:ritmo/core/utils/persian_digits.dart';

class RelativeTimeFormatter {
  RelativeTimeFormatter._();

  /// Converts a duration in minutes to natural Persian text.
  /// 45 -> "۴۵ دقیقه"
  /// 90 -> "۱ ساعت و ۳۰ دقیقه"
  /// 180 -> "۳ ساعت" (no "و ۰ دقیقه")
  static String durationFa(int minutes) {
    final sanitized = minutes.clamp(1, 1440);
    final hours = sanitized ~/ 60;
    final mins = sanitized % 60;

    if (hours == 0) {
      return '${toPersianDigits(mins)} دقیقه';
    } else if (mins == 0) {
      return '${toPersianDigits(hours)} ساعت';
    } else {
      return '${toPersianDigits(hours)} ساعت و ${toPersianDigits(mins)} دقیقه';
    }
  }

  /// Converts time difference between [target] and reference [now] into natural Persian relative time.
  static String untilFa(DateTime target, {required DateTime now}) {
    final diffMs = target.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    final diffMinutes = (diffMs / 60000).round();

    // 1. More than 60 minutes in past (< -60)
    if (diffMinutes < -60) {
      final absMins = diffMinutes.abs();
      return '${durationFa(absMins)} پیش';
    }

    // 2. 1 to 60 minutes in past (-60 <= diff < -1)
    if (diffMinutes < -1) {
      final absMins = diffMinutes.abs();
      return '${toPersianDigits(absMins)} دقیقه پیش';
    }

    // 3. Right now (-1 <= diff <= 1)
    if (diffMinutes >= -1 && diffMinutes <= 1) {
      return 'همین حالا';
    }

    // 4. 1 to 60 minutes in future (1 < diff < 60)
    if (diffMinutes > 1 && diffMinutes < 60) {
      return 'تا ${toPersianDigits(diffMinutes)} دقیقه دیگر';
    }

    // 5. 60 <= diff < 1440
    if (diffMinutes >= 60 && diffMinutes < 1440) {
      final isSameDay = target.year == now.year && target.month == now.month && target.day == now.day;
      if (isSameDay) {
        return 'تا ${durationFa(diffMinutes)} دیگر';
      }

      final tomorrow = now.add(const Duration(days: 1));
      final isTomorrow = target.year == tomorrow.year && target.month == tomorrow.month && target.day == tomorrow.day;

      final timeStr = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
      final faTimeStr = toPersianDigits(timeStr);

      if (isTomorrow) {
        return 'فردا ساعت $faTimeStr';
      }
    }

    // 6. Days difference
    final targetMidnight = DateTime(target.year, target.month, target.day);
    final nowMidnight = DateTime(now.year, now.month, now.day);
    final days = targetMidnight.difference(nowMidnight).inDays;

    final timeStr = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
    final faTimeStr = toPersianDigits(timeStr);

    if (days == 1) {
      return 'فردا ساعت $faTimeStr';
    } else if (days > 1) {
      return '${toPersianDigits(days)} روز دیگر · ساعت $faTimeStr';
    }

    return 'تا ${durationFa(diffMinutes)} دیگر';
  }
}
