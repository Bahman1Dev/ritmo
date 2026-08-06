import 'package:adhan/adhan.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/online_prayer_time_service.dart';
import 'package:sqflite/sqflite.dart';

class PrayerTimeProvider {
  PrayerTimeProvider._init();
  static final PrayerTimeProvider instance = PrayerTimeProvider._init();

  Future<Map<String, String>> getPrayerTimesForDate({
    required String cityId,
    required DateTime date,
    bool forceOnline = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);

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

    final settingsResult = await db.query('app_settings');
    final settings = {
      for (final row in settingsResult) row['key']! as String: row['value']! as String
    };

    final calcMethodStr = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';

    // 2. Try online API first (if forced or not in SQLite cache)
    if (forceOnline) {
      final onlineTimes = await OnlinePrayerTimeService.instance.fetchPrayerTimesFromApi(
        latitude: latitude,
        longitude: longitude,
        date: date,
      );
      if (onlineTimes != null) {
        return onlineTimes;
      }
    }

    // 3. Check SQLite cache
    final cacheRows = await db.query(
      'prayer_times_cache',
      where: 'date = ? AND cityId = ?',
      whereArgs: [dateStr, cityId],
      limit: 1,
    );

    if (cacheRows.isNotEmpty) {
      final row = cacheRows.first;
      return {
        'fajr': row['fajr'] as String,
        'sunrise': row['sunrise'] as String,
        'dhuhr': row['dhuhr'] as String,
        'asr': row['asr'] as String,
        'maghrib': row['maghrib'] as String,
        'isha': row['isha'] as String,
        'midnightShari': row['midnightShari'] as String,
        'sunset': row['sunset'] as String? ?? row['maghrib'] as String,
      };
    }

    // 4. Try online API fetch before local calculation
    final onlineTimes = await OnlinePrayerTimeService.instance.fetchPrayerTimesFromApi(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );

    if (onlineTimes != null) {
      return onlineTimes;
    }

    // 5. Offline Fallback: compute astronomical prayer times locally via package:adhan
    return computePrayerTimesLocally(
      latitude: latitude,
      longitude: longitude,
      calcMethodStr: calcMethodStr,
      date: date,
    );
  }

  Map<String, String> computePrayerTimesLocally({
    required double latitude,
    required double longitude,
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

    final todayComponents = DateComponents(date.year, date.month, date.day);
    final todayTimes = PrayerTimes(Coordinates(latitude, longitude), todayComponents, params);

    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowComponents = DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowTimes = PrayerTimes(Coordinates(latitude, longitude), tomorrowComponents, params);

    final fajr = todayTimes.fajr;
    final sunrise = todayTimes.sunrise;
    final dhuhr = todayTimes.dhuhr;
    final asr = todayTimes.asr;
    final maghrib = todayTimes.maghrib;
    final isha = todayTimes.isha;

    final tomorrowFajr = tomorrowTimes.fajr;

    final sunniParams = CalculationMethod.muslim_world_league.getParameters();
    final sunniTimes = PrayerTimes(Coordinates(latitude, longitude), todayComponents, sunniParams);
    final sunset = sunniTimes.maghrib;

    // Midnight Shari is midpoint between Sunset and tomorrow's Fajr
    final midnightDuration = tomorrowFajr.difference(sunset);
    final midnightShari = sunset.add(midnightDuration ~/ 2);

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
    bool forceOnline = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);

    final times = await getPrayerTimesForDate(cityId: cityId, date: date, forceOnline: forceOnline);

    final settingsResult = await db.query('app_settings');
    final settings = {
      for (final row in settingsResult) row['key']! as String: row['value']! as String
    };
    final calcMethodStr = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';

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
        'ihtiyatMinutes': 0,
        'computedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> cacheRange({
    required String cityId,
    required DateTime from,
    required int days,
    bool forceOnline = false,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch city coordinates ONCE
    final cityResult = await db.query(
      'iran_cities',
      where: 'id = ?',
      whereArgs: [cityId],
      limit: 1,
    );

    var latitude = 35.6892;
    var longitude = 51.3890;

    if (cityResult.isNotEmpty) {
      latitude = cityResult.first['latitude']! as double;
      longitude = cityResult.first['longitude']! as double;
    }

    // 2. Fetch app_settings ONCE
    final settingsResult = await db.query('app_settings');
    final settings = {
      for (final row in settingsResult) row['key']! as String: row['value']! as String
    };

    final calcMethodStr = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 3. Batch insert using db.batch() for blazing fast atomic I/O
    final batch = db.batch();

    for (int i = 0; i < days; i++) {
      final date = from.add(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final times = computePrayerTimesLocally(
        latitude: latitude,
        longitude: longitude,
        calcMethodStr: calcMethodStr,
        date: date,
      );

      batch.insert(
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
          'ihtiyatMinutes': 0,
          'computedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    final thresholdDate = from.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10);
    try {
      await db.delete(
        'prayer_times_cache',
        where: 'date < ?',
        whereArgs: [thresholdDate],
      );
    } catch (_) {}

    return days;
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
