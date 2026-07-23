import 'package:adhan/adhan.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class PrayerTimeProvider {
  PrayerTimeProvider._init();
  static final PrayerTimeProvider instance = PrayerTimeProvider._init();

  Future<Map<String, String>> getPrayerTimesForDate({
    required String cityId,
    required DateTime date,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch city coordinates
    final cityResult = await db.query(
      'iran_cities',
      where: 'id = ?',
      whereArgs: [cityId],
      limit: 1,
    );

    var latitude = 35.6892; // default Tehran
    var longitude = 51.3890;

    if (cityResult.isNotEmpty) {
      latitude = cityResult.first['latitude']! as double;
      longitude = cityResult.first['longitude']! as double;
    }

    // 2. Fetch ihtiyatMinutes and calculationMethod from settings
    final settingsResult = await db.query('app_settings');
    final settings = {
      for (final row in settingsResult) row['key']! as String: row['value']! as String
    };

    final ihtiyatMinutes = int.tryParse(settings['ihtiyat_minutes'] ?? '10') ?? 10;
    final calcMethodStr = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';

    return computePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      ihtiyatMinutes: ihtiyatMinutes,
      calcMethodStr: calcMethodStr,
      date: date,
    );
  }

  Map<String, String> computePrayerTimes({
    required double latitude,
    required double longitude,
    required int ihtiyatMinutes,
    required String calcMethodStr,
    required DateTime date,
  }) {
    var method = CalculationMethod.tehran;
    if (calcMethodStr == 'MWL') {
      method = CalculationMethod.muslim_world_league;
    } else if (calcMethodStr == 'ISNA') {
      method = CalculationMethod.north_america;
    } else if (calcMethodStr == 'MAKKAH') {
      method = CalculationMethod.umm_al_qura;
    }

    final params = method.getParameters();

    // 3. Compute today's prayer times
    final todayComponents = DateComponents(date.year, date.month, date.day);
    final todayTimes = PrayerTimes(Coordinates(latitude, longitude), todayComponents, params);

    // 4. Compute tomorrow's prayer times (for Shari Midnight)
    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowComponents = DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowTimes = PrayerTimes(Coordinates(latitude, longitude), tomorrowComponents, params);

    // Apply ihtiyat (safety offset) to prayer times
    final fajr = todayTimes.fajr.add(Duration(minutes: ihtiyatMinutes));
    final sunrise = todayTimes.sunrise; // Sunrise is astronomical, ihtiyat is not applied
    final dhuhr = todayTimes.dhuhr.add(Duration(minutes: ihtiyatMinutes));
    final asr = todayTimes.asr.add(Duration(minutes: ihtiyatMinutes));
    final maghrib = todayTimes.maghrib.add(Duration(minutes: ihtiyatMinutes));
    final isha = todayTimes.isha.add(Duration(minutes: ihtiyatMinutes));

    final tomorrowFajr = tomorrowTimes.fajr.add(Duration(minutes: ihtiyatMinutes));

    // Midnight Shari is the midpoint between Maghrib and tomorrow's Fajr
    final midnightDuration = tomorrowFajr.difference(maghrib);
    final midnightShari = maghrib.add(midnightDuration ~/ 2);

    // Astronomical sunset (using MWL method where Maghrib is sunset)
    final sunniParams = CalculationMethod.muslim_world_league.getParameters();
    final sunniTimes = PrayerTimes(Coordinates(latitude, longitude), todayComponents, sunniParams);
    final sunset = sunniTimes.maghrib;

    return {
      'fajr': _formatTime(fajr),
      'sunrise': _formatTime(sunrise),
      'dhuhr': _formatTime(dhuhr),
      'asr': _formatTime(asr),
      'maghrib': _formatTime(maghrib),
      'isha': _formatTime(isha),
      'midnightShari': _formatTime(midnightShari),
      'sunset': _formatTime(sunset),
    };
  }

  Future<void> cachePrayerTimes({
    required String cityId,
    required DateTime date,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);

    // Fetch times
    final times = await getPrayerTimesForDate(cityId: cityId, date: date);

    // Get settings
    final settingsResult = await db.query('app_settings');
    final settings = {
      for (final row in settingsResult) row['key']! as String: row['value']! as String
    };
    final ihtiyatMinutes = int.tryParse(settings['ihtiyat_minutes'] ?? '10') ?? 10;
    final calcMethodStr = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';

    // Insert or update cache
    await db.insert(
      'prayer_times_cache',
      {
        'date': dateStr,
        'cityId': cityId,
        'fajr': times['fajr'],
        'sunrise': times['sunrise'],
        'dhuhr': times['dhuhr'],
        'asr': times['asr'],
        'maghrib': times['maghrib'],
        'isha': times['isha'],
        'midnightShari': times['midnightShari'],
        'sunset': times['sunset'],
        'calculationMethod': calcMethodStr,
        'ihtiyatMinutes': ihtiyatMinutes,
        'computedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
