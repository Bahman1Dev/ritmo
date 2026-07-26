import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';

class DayArcSuggestion {
  const DayArcSuggestion({
    required this.wakeTime,
    required this.sleepTime,
    required this.reasonFa,
    required this.isInferred,
  });

  final String wakeTime;
  final String sleepTime;
  final String reasonFa;
  final bool isInferred;
}

class DayArcInferencer {
  const DayArcInferencer._();

  static Future<DayArcSuggestion> suggest({DateTime? now}) async {
    final today = now ?? DateTime.now();

    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final map = {
        for (final r in settings) r['key']! as String: r['value']! as String
      };

      final cityId = map['prayer_city_id'] ?? map['home_city_id'];

      if (cityId != null && cityId.isNotEmpty) {
        final times = await PrayerTimeProvider.instance.getPrayerTimesForDate(
          cityId: cityId,
          date: today,
        );

        final sunriseStr = times['sunrise'];
        if (sunriseStr != null && sunriseStr.contains(':')) {
          final parts = sunriseStr.split(':');
          final h = int.tryParse(parts[0]) ?? 6;
          final m = int.tryParse(parts[1]) ?? 0;

          final totalMins = h * 60 + m;
          final roundedMins = (totalMins / 30).round() * 30;
          final wakeH = (roundedMins ~/ 60) % 24;
          final wakeM = roundedMins % 60;
          final wakeStr = '${wakeH.toString().padLeft(2, '0')}:${wakeM.toString().padLeft(2, '0')}';

          final sleepH = (wakeH + 17) % 24;
          final sleepStr = '${sleepH.toString().padLeft(2, '0')}:${wakeM.toString().padLeft(2, '0')}';

          return DayArcSuggestion(
            wakeTime: wakeStr,
            sleepTime: sleepStr,
            reasonFa: 'پیشنهادشده بر اساس زمان طلوع آفتاب شهر شما ($sunriseStr)',
            isInferred: true,
          );
        }
      }
    } catch (_) {}

    return const DayArcSuggestion(
      wakeTime: '07:00',
      sleepTime: '23:00',
      reasonFa: 'زمان‌بندی عمومی استاندارد',
      isInferred: false,
    );
  }
}
