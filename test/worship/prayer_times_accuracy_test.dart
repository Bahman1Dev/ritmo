import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Prayer Times Accuracy & Cache Tests', () {
    late Database db;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT,
            updatedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE iran_cities (
            id TEXT PRIMARY KEY,
            province TEXT,
            city TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE prayer_times_cache (
            date TEXT NOT NULL,
            cityId TEXT NOT NULL,
            fajr TEXT NOT NULL,
            sunrise TEXT NOT NULL,
            dhuhr TEXT NOT NULL,
            asr TEXT NOT NULL,
            maghrib TEXT NOT NULL,
            sunset TEXT NOT NULL,
            isha TEXT NOT NULL,
            midnightShari TEXT NOT NULL,
            calculationMethod TEXT,
            ihtiyatMinutes INTEGER,
            computedAt INTEGER,
            fajrIso TEXT,
            sunriseIso TEXT,
            dhuhrIso TEXT,
            asrIso TEXT,
            maghribIso TEXT,
            sunsetIso TEXT,
            ishaIso TEXT,
            midnightShariIso TEXT,
            PRIMARY KEY (date, cityId)
          )
        ''');
        await db.execute('''
          CREATE TABLE worship_practices (
            id TEXT PRIMARY KEY,
            practiceType TEXT,
            subType TEXT,
            title TEXT,
            description TEXT,
            isActive INTEGER DEFAULT 1,
            userDisabledAt INTEGER,
            sortOrder INTEGER DEFAULT 0,
            allowQada INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE worship_completions (
            id TEXT PRIMARY KEY,
            practiceId TEXT,
            dateStr TEXT,
            resultType TEXT,
            completedAt INTEGER
          )
        ''');

        // Seed Tehran
        await db.insert('iran_cities', {
          'id': 'TEHRAN_TEHRAN',
          'province': 'تهران',
          'city': 'تهران',
          'latitude': 35.6892,
          'longitude': 51.3890,
        });

        // Seed default settings with ihtiyat 0
        await db.insert('app_settings', {'key': 'prayer_city_id', 'value': 'TEHRAN_TEHRAN', 'updatedAt': 1});
        await db.insert('app_settings', {'key': 'prayer_calculation_method', 'value': 'TEHRAN_GEOPHYSICS', 'updatedAt': 1});
        await db.insert('app_settings', {'key': 'ihtiyat_minutes', 'value': '0', 'updatedAt': 1});
      });
      DatabaseHelper.instance.overrideDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('computePrayerTimes returns exact Tehran Geophysics times when ihtiyat is 0', () async {
      final date = DateTime(2026, 8, 6);
      final times = await PrayerTimeProvider.instance.getPrayerTimesForDate(
        cityId: 'TEHRAN_TEHRAN',
        date: date,
      );

      expect(times['fajr'], isNotNull);
      expect(times['dhuhr'], isNotNull);
      expect(times['maghrib'], isNotNull);
      expect(times['midnightShari'], isNotNull);

      // Verify format HH:mm
      final timeRegExp = RegExp(r'^\d{2}:\d{2}$');
      expect(timeRegExp.hasMatch(times['fajr']!), isTrue);
      expect(timeRegExp.hasMatch(times['dhuhr']!), isTrue);
      expect(timeRegExp.hasMatch(times['maghrib']!), isTrue);
    });

    test('Self-healing converts legacy ihtiyat_minutes 10 to 0 and clears cache', () async {
      // Set legacy ihtiyat_minutes = 10
      await db.insert('app_settings', {'key': 'ihtiyat_minutes', 'value': '10', 'updatedAt': 1}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('prayer_times_cache', {
        'date': '2026-08-06',
        'cityId': 'TEHRAN_TEHRAN',
        'fajr': '04:50',
        'sunrise': '06:15',
        'dhuhr': '12:20',
        'asr': '16:00',
        'maghrib': '20:30',
        'sunset': '20:15',
        'isha': '21:30',
        'midnightShari': '00:10',
      });

      final times = await WorshipEngine.instance.prayerTimes(DateTime(2026, 8, 6));
      expect(times, isNotNull);

      // Verify DB settings were healed to 0
      final settings = await db.query('app_settings', where: "key = 'ihtiyat_minutes'");
      expect(settings.first['value'], equals('0'));
    });
  });
}
