import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

class MockWorshipDatabase implements Database {
  @override
  bool get isOpen => true;

  final Map<String, List<Map<String, dynamic>>> tables = {
    'worship_practices': [],
    'app_settings': [],
    'cycle_logs': [],
    'cycle_periods': [],
    'pending_reminders': [],
    'worship_debts': [],
  };

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    tables[table] ??= [];
    tables[table]!.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = tables[table] ?? [];
    if (where == null) return list;

    if (table == 'app_settings') {
      if (where.contains('key = ?')) {
        final keyVal = whereArgs![0]! as String;
        return list.where((row) => row['key'] == keyVal).toList();
      }
      return list;
    }

    if (table == 'cycle_periods') {
      if (where.contains('startDate <= ?')) {
        final todayStr = whereArgs![0]! as String;
        final filtered = list.where((row) {
          final start = row['startDate'] as String;
          return start.compareTo(todayStr) <= 0;
        }).toList();
        filtered.sort((a, b) {
          final startA = a['startDate'] as String;
          final startB = b['startDate'] as String;
          return startB.compareTo(startA);
        });
        return filtered;
      }
    }

    if (table == 'cycle_logs') {
      if (where.contains('cycleStartDate <= ?')) {
        final todayStr = whereArgs![0]! as String;
        return list.where((row) {
          final start = row['cycleStartDate'] as String;
          final end = row['cycleEndDate'] as String?;
          final matchesStart = start.compareTo(todayStr) <= 0;
          final matchesEnd = end == null || end.compareTo(todayStr) >= 0;
          return matchesStart && matchesEnd;
        }).toList();
      }
    }

    return list;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables[table] ?? [];
    if (where != null && where.contains('id = ?')) {
      final idVal = whereArgs![0]! as String;
      for (final row in list) {
        if (row['id'] == idVal) {
          values.forEach((k, v) {
            row[k] = v;
          });
        }
      }
      return 1;
    }
    return 0;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('Worship Feature Implementation Tests', () {
    late MockWorshipDatabase db;

    setUp(() {
      db = MockWorshipDatabase();
      DatabaseHelper.databaseInstance = db;
    });

    test('1. Next Prayer and Countdown Highlight Edge Cases', () {
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

      // Current time is 11:58 (10 minutes before Dhuhr -> should be highlighted as urgent)
      final nowUrgent = DateTime(2026, 6, 23, 11, 58);
      final next1 = pTime.nextPrayer(nowUrgent);
      expect(next1.key, equals('DHUHR'));
      
      final diffUrgent = next1.value.difference(nowUrgent);
      expect(diffUrgent.inMinutes, equals(10));
      expect(diffUrgent.inMinutes < 15, isTrue); // Urgent!

      // Current time is 11:40 (28 minutes before Dhuhr -> not urgent)
      final nowNotUrgent = DateTime(2026, 6, 23, 11, 40);
      final next2 = pTime.nextPrayer(nowNotUrgent);
      final diffNotUrgent = next2.value.difference(nowNotUrgent);
      expect(diffNotUrgent.inMinutes, equals(28));
      expect(diffNotUrgent.inMinutes < 15, isFalse);
    });

    test('2. Snooze Limit Constraints & Pending Reminders', () {
      const practice = WorshipPractice(
        id: 'obligatory_fajr',
        practiceType: 'PRAYER',
        title: 'نماز صبح',
        deferCount: 2,
        createdAt: 1000,
        updatedAt: 1000,
      );

      // Verify defer count increment behaviour
      final afterFirstSnooze = practice.copyWith(deferCount: practice.deferCount + 1);
      expect(afterFirstSnooze.deferCount, equals(3));
      expect(afterFirstSnooze.isDeferExhausted, isTrue); // limit reached at 3
    });

    test('3. Daily Reset of Dhikr Counters', () {
      const dhikrPractice = WorshipPractice(
        id: 'dhikr_salawat',
        practiceType: 'DHIKR',
        title: 'صلوات',
        dailyTarget: 100,
        dailyDone: 80,
        dailyDoneDate: '2026-06-22',
        createdAt: 1000,
        updatedAt: 1000,
      );

      // When date changes, needsReset should be true
      expect(dhikrPractice.needsReset('2026-06-23'), isTrue);

      // If reset, dailyDone becomes 0
      final resetDhikr = dhikrPractice.copyWith(
        dailyDone: 0,
        dailyDoneDate: '2026-06-23',
      );
      expect(resetDhikr.dailyDone, equals(0));
      expect(resetDhikr.needsReset('2026-06-23'), isFalse);
    });

    test('4. Worship Debt Progress and Forecast Predictions', () {
      final debt = WorshipDebt(
        id: 'debt_fast',
        debtType: 'FAST',
        title: 'روزه قضا',
        totalCount: 30,
        remainingCount: 20,
        dailyTarget: 2,
        autoCreated: false,
        isArchived: false,
        createdAt: 1000,
        updatedAt: 1000,
      );

      // Progress Percent: (30 - 20) / 30 = 33.33%
      expect(debt.progressPercent, closeTo(33.33, 0.05));
      // Days to Finish: 20 remaining / 2 per day = 10 days
      expect(debt.daysToFinish, equals(10));
    });

    test('5. Menstruation Rule Enforcement', () async {
      // 1. Male gender -> should NOT report menstruating
      await db.insert('app_settings', {'key': 'user_gender', 'value': 'MALE'});
      await db.insert('app_settings', {'key': 'module_cycle_enabled', 'value': 'true'});
      await db.insert('app_settings', {'key': 'cycle_consent_worship', 'value': 'true'});
      expect(await DatabaseHelper.instance.isUserMenstruating(), isFalse);

      // Reset settings
      db.tables['app_settings']!.clear();
      db.tables['cycle_periods']!.clear();

      // 2. Female gender, cycle disabled -> should NOT report menstruating
      await db.insert('app_settings', {'key': 'user_gender', 'value': 'FEMALE'});
      await db.insert('app_settings', {'key': 'module_cycle_enabled', 'value': 'false'});
      await db.insert('app_settings', {'key': 'cycle_consent_worship', 'value': 'true'});
      expect(await DatabaseHelper.instance.isUserMenstruating(), isFalse);

      // Reset settings
      db.tables['app_settings']!.clear();
      db.tables['cycle_periods']!.clear();

      // 3. Female gender, cycle enabled, active suppressed cycle log -> should report menstruating
      await db.insert('app_settings', {'key': 'user_gender', 'value': 'FEMALE'});
      await db.insert('app_settings', {'key': 'module_cycle_enabled', 'value': 'true'});
      await db.insert('app_settings', {'key': 'cycle_consent_worship', 'value': 'true'});
      
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert('cycle_periods', {
        'id': 'log_1',
        'startDate': todayStr,
        'endDate': null,
      });

      expect(await DatabaseHelper.instance.isUserMenstruating(), isTrue);
    });

    test('6. Hijri Caching and Key Retrieval', () async {
      final date = DateTime(2026, 6, 23);
      const cacheKey = 'hijri_date_2026_06_23';

      // Insert cached hijri mapping
      final hijriMap = {
        'day': 8,
        'month': 12,
        'year': 1447,
        'monthName': 'ذوالحجه',
        'formatted': '۸ ذوالحجه ۱۴۴۷',
      };
      
      await db.insert('app_settings', {
        'key': cacheKey,
        'value': json.encode(hijriMap),
      });

      final cached = await HijriDate.getOrFetch(date, db);
      expect(cached, isNotNull);
      expect(cached!.day, equals(8));
      expect(cached.formatted, equals('۸ ذوالحجه ۱۴۴۷'));
    });
  });
}
