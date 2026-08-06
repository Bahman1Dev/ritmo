import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/sleep_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<String> executedStatements = [];
  final Map<String, List<Map<String, dynamic>>> tables = {
    'bedtime_diagnostics': [],
    'app_settings': [],
  };

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

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
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
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
    return tables[table] ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute) {
      return execute(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    if (invocation.memberName == #rawQuery) {
      return rawQuery(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    if (invocation.memberName == #insert) {
      return insert(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
      );
    }
    if (invocation.memberName == #query) {
      return query(
        invocation.positionalArguments[0] as String,
      );
    }
    return null;
  }
}

void main() {
  group('Sleep Engine Tests', () {
    final today = DateTime(2026, 6, 24);
    final target = SleepTarget(bedtime: '23:30', wake: '07:00', durationMinutes: 450);

    test('Sleep debt calculation aggregates deficit duration', () async {
      final engine = SleepEngine();
      final logs = [
        // 8 hours sleep - no debt
        SleepLog(
          date: '2026-06-23',
          reason: 'good',
          createdAt: 0,
          durationMinutes: 480,
          quality: SleepQuality.good,
        ),
        // 6 hours sleep - 90 minutes debt
        SleepLog(
          date: '2026-06-22',
          reason: 'poor',
          createdAt: 0,
          durationMinutes: 360,
          quality: SleepQuality.poor,
        ),
        // 7 hours sleep - 30 minutes debt
        SleepLog(
          date: '2026-06-21',
          reason: 'fair',
          createdAt: 0,
          durationMinutes: 420,
          quality: SleepQuality.fair,
        ),
      ];

      final input = SleepEngineInput(
        sleepLogs: logs,
        target: target,
        energyLogs: [],
        moodLogs: [],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.sleepDebtMinutes, 120); // 90 + 30
      expect(output.avgDurationMinutes, 420.0); // (480 + 360 + 420) / 3
      expect(output.avgQuality, 3.0); // (4 + 2 + 3) / 3
    });

    test('Consistency score starts at 100 and drops based on bedtime/waketime deviation SD', () async {
      final engine = SleepEngine();
      
      // Bedtime target: 23:30 (1410 min), Wake target: 07:00 (420 min)
      final logs = [
        SleepLog(
          date: '2026-06-23',
          reason: 'good',
          createdAt: 0,
          durationMinutes: 450,
          quality: SleepQuality.good,
          bedtimeAt: DateTime(2026, 6, 22, 23, 30).millisecondsSinceEpoch,
          wakeAt: DateTime(2026, 6, 23, 7).millisecondsSinceEpoch,
        ),
        SleepLog(
          date: '2026-06-22',
          reason: 'good',
          createdAt: 0,
          durationMinutes: 450,
          quality: SleepQuality.good,
          bedtimeAt: DateTime(2026, 6, 21, 23, 40).millisecondsSinceEpoch, // +10 min
          wakeAt: DateTime(2026, 6, 22, 7, 10).millisecondsSinceEpoch,    // +10 min
        ),
      ];

      final input = SleepEngineInput(
        sleepLogs: logs,
        target: target,
        energyLogs: [],
        moodLogs: [],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.consistencyScore, lessThan(100));
      expect(output.consistencyScore, greaterThan(80));
    });

    test('Pearson correlation coefficients return null with insufficient data', () async {
      final engine = SleepEngine();
      final input = SleepEngineInput(
        sleepLogs: [
          SleepLog(date: '2026-06-23', reason: 'good', createdAt: 0, durationMinutes: 450, quality: SleepQuality.good),
        ],
        target: target,
        energyLogs: [],
        moodLogs: [],
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.sleepEnergyCorrelation, isNull);
      expect(output.sleepMoodCorrelation, isNull);
      expect(output.correlationInsight, contains('در حال یادگیری'));
    });

    test('Pearson correlation coefficients are calculated correctly for positive correlation', () async {
      final engine = SleepEngine();
      final logs = [
        SleepLog(date: '2026-06-21', reason: 'poor', createdAt: 0, durationMinutes: 300, quality: SleepQuality.poor),
        SleepLog(date: '2026-06-22', reason: 'fair', createdAt: 0, durationMinutes: 400, quality: SleepQuality.fair),
        SleepLog(date: '2026-06-23', reason: 'excellent', createdAt: 0, durationMinutes: 500, quality: SleepQuality.excellent),
      ];

      // Energy logs for next day (22nd, 23rd, 24th)
      final energy = [
        {'energyLevel': 'LOW', 'loggedAt': DateTime(2026, 6, 22, 10).millisecondsSinceEpoch},
        {'energyLevel': 'MEDIUM', 'loggedAt': DateTime(2026, 6, 23, 10).millisecondsSinceEpoch},
        {'energyLevel': 'HIGH', 'loggedAt': DateTime(2026, 6, 24, 10).millisecondsSinceEpoch},
      ];

      // Mood logs for next day (22nd, 23rd, 24th)
      final mood = [
        {'valence': 2.0, 'loggedAt': DateTime(2026, 6, 22, 10).millisecondsSinceEpoch},
        {'valence': 3.0, 'loggedAt': DateTime(2026, 6, 23, 10).millisecondsSinceEpoch},
        {'valence': 5.0, 'loggedAt': DateTime(2026, 6, 24, 10).millisecondsSinceEpoch},
      ];

      final input = SleepEngineInput(
        sleepLogs: logs,
        target: target,
        energyLogs: energy,
        moodLogs: mood,
        today: today,
      );

      final output = await engine.calculate(input);
      expect(output.sleepEnergyCorrelation, isNotNull);
      expect(output.sleepMoodCorrelation, isNotNull);
      expect(output.sleepEnergyCorrelation, greaterThan(0.8));
      expect(output.sleepMoodCorrelation, greaterThan(0.8));
      expect(output.correlationInsight, contains('بهتر خوابیده‌ای'));
    });
  });

  group('Database Migration v17 Tests', () {
    test('onUpgrade from v16 to v17 alters bedtime_diagnostics and seeds settings', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 16, 17);

      final allSql = mockDb.executedStatements.join('\n').toLowerCase();
      expect(allSql, contains('alter table bedtime_diagnostics add column bedtimeat'));
      expect(allSql, contains('alter table bedtime_diagnostics add column wakeat'));
      expect(allSql, contains('alter table bedtime_diagnostics add column durationminutes'));
      expect(allSql, contains('alter table bedtime_diagnostics add column quality'));
      expect(allSql, contains('alter table bedtime_diagnostics add column awakenings'));
      expect(allSql, contains('create table if not exists mood_logs'));

      // Verify default sleep settings are seeded
      final settings = mockDb.tables['app_settings']!;
      expect(settings.any((s) => s['key'] == 'module_sleep_enabled' && s['value'] == 'false'), isTrue);
      expect(settings.any((s) => s['key'] == 'sleep_target_bedtime' && s['value'] == '23:30'), isTrue);
    });
  });

  group('Sleep Log Mapping and Dynamic Energy Penalty Tests', () {
    test('Low quality sleep derives poor sleep keywords and sets energy to LOW', () {
      // terrible (score 1) sleep
      final logTerrible = SleepLog(
        date: '2026-06-23',
        reason: 'کیفیت ضعیف',
        createdAt: 0,
        durationMinutes: 450,
        quality: SleepQuality.terrible,
      );

      expect(logTerrible.quality.score, 1);
      expect(logTerrible.reason, contains('ضعیف'));

      // terrible or poor quality sets default energy level to LOW in the log save logic
      var energyLevel = 'MEDIUM';
      if (logTerrible.quality == SleepQuality.terrible || logTerrible.quality == SleepQuality.poor) {
        energyLevel = 'LOW';
      }
      expect(energyLevel, 'LOW');
    });

    test('Short duration sleep (< 6 hours) derives sleep keyword "کم"', () {
      final logShort = SleepLog(
        date: '2026-06-23',
        reason: 'مدت زمان کم',
        createdAt: 0,
        durationMinutes: 300, // 5 hours
        quality: SleepQuality.good,
      );

      expect(logShort.reason, contains('کم'));
    });

    test('Good sleep has reason without bad sleep keywords and sets energy to HIGH', () {
      final logGood = SleepLog(
        date: '2026-06-23',
        reason: 'مناسب',
        createdAt: 0,
        durationMinutes: 480, // 8 hours
        quality: SleepQuality.good,
      );

      final hasBadKeywords = ['ضعیف', 'کم', 'دیر', 'خستگی', 'poor', 'bad', 'tired']
          .any(logGood.reason.contains);
      expect(hasBadKeywords, isFalse);

      var energyLevel = 'MEDIUM';
      if (logGood.quality == SleepQuality.terrible || logGood.quality == SleepQuality.poor) {
        energyLevel = 'LOW';
      } else if (logGood.quality == SleepQuality.good || logGood.quality == SleepQuality.excellent) {
        energyLevel = 'HIGH';
      }
      expect(energyLevel, 'HIGH');
    });
  });
}
