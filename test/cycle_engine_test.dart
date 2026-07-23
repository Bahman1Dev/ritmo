import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/features/cycle/logic/cycle_correlation.dart';
import 'package:sqflite/sqflite.dart';

class MockCycleDatabase implements Database {
  List<Map<String, Object?>> cyclePeriods = [];
  List<Map<String, Object?>> cycleDayLogs = [];

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
    if (table == 'cycle_periods') {
      return cyclePeriods;
    } else if (table == 'cycle_day_logs') {
      return cycleDayLogs;
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #query) {
      return query(
        invocation.positionalArguments[0] as String,
        orderBy: invocation.namedArguments[#orderBy] as String?,
      );
    }
    return null;
  }
}

void main() {
  group('CycleEngine Unit Tests', () {
    late MockCycleDatabase mockDb;
    late Map<String, String> settings;
    late CycleEngine engine;

    setUp(() {
      mockDb = MockCycleDatabase();
      engine = CycleEngine();
      settings = {
        'user_gender': 'FEMALE',
        'module_cycle_enabled': 'true',
        'cycle_avg_length': '28',
        'cycle_avg_period': '6',
      };
    });

    test('returns empty/noData if user is not female or module is disabled', () async {
      settings['user_gender'] = 'MALE';
      final now = DateTime(2026, 6, 24);
      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.currentPhase, CyclePhase.noData);
      expect(output.hasData, false);
      expect(output.dayOfCycle, 0);
    });

    test('returns noData if cycle_periods table is empty', () async {
      final now = DateTime(2026, 6, 24);
      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.currentPhase, CyclePhase.noData);
      expect(output.hasData, false);
      expect(output.dayOfCycle, 0);
    });

    test('calculates correct menstrual phase and cycle day', () async {
      final now = DateTime(2026, 6, 24);
      // Period starts on 2026-06-20 (4 days ago, so day 5)
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-06-20',
          'endDate': null,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.currentPhase, CyclePhase.menstrual);
      expect(output.dayOfCycle, 5);
      expect(output.dayOfPeriod, 5);
    });

    test('calculates follicular phase after period ends', () async {
      final now = DateTime(2026, 6, 28); // 8 days after start, average period is 6 days
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.currentPhase, CyclePhase.follicular);
      expect(output.dayOfCycle, 9);
      expect(output.dayOfPeriod, 0);
    });

    test('calculates ovulation phase', () async {
      final now = DateTime(2026, 7, 4); // 14 days after start (ovulation day for 28-day cycle)
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.currentPhase, CyclePhase.ovulation);
      expect(output.dayOfCycle, 15); // daysSinceStart is 14, so day 15 (which falls within [ovulationDay - 1, ovulationDay] range)
    });

    test('calculates luteal phase', () async {
      final now = DateTime(2026, 7, 8); // 18 days after start
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-06-20',
          'endDate': '2026-06-25',
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.currentPhase, CyclePhase.luteal);
      expect(output.dayOfCycle, 19);
    });

    test('calculates stats and irregularity from historical data', () async {
      final now = DateTime(2026, 9, 20);
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': '2026-06-01', 'endDate': '2026-06-06'}, // 28 day cycle next
        {'id': '2', 'startDate': '2026-06-29', 'endDate': '2026-07-04'}, // 35 day cycle next (irregular gap of 7 days)
        {'id': '3', 'startDate': '2026-08-03', 'endDate': '2026-08-09'}, // 28 day cycle next
        {'id': '4', 'startDate': '2026-08-31', 'endDate': '2026-09-06'},
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.stats.totalRecordedCycles, 4);
      expect(output.stats.avgCycleLength, closeTo(30.33, 0.05));
      expect(output.stats.avgPeriodDuration, closeTo(6.5, 0.05));
      expect(output.isIrregular, true); // max - min = 35 - 28 = 7 >= 7
      expect(output.dataMaturity, 'MEDIUM');
    });

    test('calculates interval predictions, regularity score, and PMS window', () async {
      final now = DateTime(2026, 9, 20);
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': '2026-06-01', 'endDate': '2026-06-06'},
        {'id': '2', 'startDate': '2026-06-29', 'endDate': '2026-07-04'},
        {'id': '3', 'startDate': '2026-08-03', 'endDate': '2026-08-09'},
        {'id': '4', 'startDate': '2026-08-31', 'endDate': '2026-09-06'},
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));

      expect(output.hasData, true);
      expect(output.regularityScore, isNotNull);
      expect(output.nextPeriodWindowStart, isNotNull);
      expect(output.nextPeriodWindowEnd, isNotNull);
      expect(output.pmsWindowStart, isNotNull);
      expect(output.pmsWindowEnd, isNotNull);
      expect(output.trendPoints.length, 4);
    });

    test('short delay prediction (e.g. 26 days start and 28 average cycle) projects to current expected date', () async {
      final now = DateTime(2026, 6, 24);
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-05-29',
          'endDate': null,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));
      expect(output.nextPeriodPrediction, DateTime(2026, 6, 26));
    });

    test('low data returns status insufficient data', () async {
      final now = DateTime(2026, 6, 24);
      mockDb.cyclePeriods = [
        {
          'id': '1',
          'startDate': '2026-06-20',
          'endDate': null,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
        }
      ];

      final output = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));
      expect(output.regularityLabel, 'دادهٔ ناکافی');
    });

    test('regularity status is calculated from range dispersion', () async {
      final now = DateTime(2026, 9, 20);
      
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': '2026-06-01', 'endDate': '2026-06-06'}, 
        {'id': '2', 'startDate': '2026-06-29', 'endDate': '2026-07-04'}, 
        {'id': '3', 'startDate': '2026-08-03', 'endDate': '2026-08-09'}, 
        {'id': '4', 'startDate': '2026-08-31', 'endDate': '2026-09-06'},
      ];
      final output1 = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));
      expect(output1.regularityLabel, 'نامنظم');

      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': '2026-06-01', 'endDate': '2026-06-06'}, 
        {'id': '2', 'startDate': '2026-06-29', 'endDate': '2026-07-04'}, 
        {'id': '3', 'startDate': '2026-07-26', 'endDate': '2026-08-01'}, 
      ];
      final output2 = await engine.calculate(CycleEngineInput(db: mockDb, appSettings: settings, now: now));
      expect(output2.regularityLabel, 'نسبتاً منظم');
    });
  });

  group('CycleCorrelationAnalyzer Tests', () {
    late CycleMockDatabase mockDb;

    setUp(() {
      mockDb = CycleMockDatabase();
    });

    test('returns fallback insights when logs are fewer than 3', () async {
      mockDb.cycleDayLogs = [
        {'logDate': '2026-06-20', 'flowLevel': 2, 'symptomsJson': '[]'}
      ];
      final corrs = await CycleCorrelationAnalyzer.analyzeCorrelations(mockDb);
      expect(corrs.length, 3);
      expect(corrs[0].coefficient, isNull);
      expect(corrs[0].insight, contains('کافی نیست'));
    });

    test('calculates correct Pearson correlation and clusters symptoms', () async {
      mockDb.cycleDayLogs = [
        {'logDate': '2026-06-20', 'flowLevel': 1, 'symptomsJson': '["درد شکم"]'},
        {'logDate': '2026-06-21', 'flowLevel': 2, 'symptomsJson': '["درد شکم", "خستگی"]'},
        {'logDate': '2026-06-22', 'flowLevel': 3, 'symptomsJson': '["خستگی"]'},
      ];
      final nowMs = DateTime(2026, 6, 20).millisecondsSinceEpoch;
      mockDb.energyLogs = [
        {'loggedAt': nowMs, 'energyLevel': 'HIGH'},
        {'loggedAt': nowMs + 86400000, 'energyLevel': 'LOW'},
        {'loggedAt': nowMs + 86400000 * 2, 'energyLevel': 'LOW'},
      ];
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': '2026-06-20', 'endDate': '2026-06-25'}
      ];

      final corrs = await CycleCorrelationAnalyzer.analyzeCorrelations(mockDb);
      expect(corrs.length, 3);
      expect(corrs[0].coefficient, isNotNull);
      expect(corrs[0].coefficient, lessThan(0));

      final symptomStats = await CycleCorrelationAnalyzer.analyzeSymptomStats(mockDb);
      expect(symptomStats.length, 2);
      expect(symptomStats[0].key, anyOf('درد شکم', 'خستگی'));
      expect(symptomStats[0].count, anyOf(2, 1));
    });
  });

  group('CycleConsentBridge and Fiqh Ledger Tests', () {
    late CycleMockDatabase mockDb;

    setUp(() {
      mockDb = CycleMockDatabase();
      DatabaseHelper.databaseInstance = mockDb;
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('isUserMenstruating returns correct status based on date', () async {
      mockDb.appSettings = [
        {'key': 'user_gender', 'value': 'FEMALE'},
        {'key': 'module_cycle_enabled', 'value': 'true'},
        {'key': 'cycle_avg_period', 'value': '6'},
      ];
      
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': todayStr, 'endDate': null}
      ];

      final isMenstruating = await CycleConsentBridge.isUserMenstruating();
      expect(isMenstruating, true);
    });

    test('bodyRhythmInfluence respects settings and returns indirect message', () async {
      mockDb.appSettings = [
        {'key': 'user_gender', 'value': 'FEMALE'},
        {'key': 'module_cycle_enabled', 'value': 'true'},
        {'key': 'cycle_avg_period', 'value': '6'},
        {'key': 'cycle_consent_energy', 'value': 'true'},
        {'key': 'cycle_consent_sleep', 'value': 'false'},
      ];

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': todayStr, 'endDate': null}
      ];

      final energyInfluence = await CycleConsentBridge.bodyRhythmInfluence(forSystem: 'energy');
      expect(energyInfluence, isNotNull);
      expect(energyInfluence!.energyDelta, -15.0);
      expect(energyInfluence.indirectMessage, isNot(contains('پریود')));
      expect(energyInfluence.indirectMessage, isNot(contains('قاعدگی')));

      final sleepInfluence = await CycleConsentBridge.bodyRhythmInfluence(forSystem: 'sleep');
      expect(sleepInfluence, isNull);
    });

    test('isWorshipSuspended respects settings', () async {
      mockDb.appSettings = [
        {'key': 'user_gender', 'value': 'FEMALE'},
        {'key': 'module_cycle_enabled', 'value': 'true'},
        {'key': 'cycle_avg_period', 'value': '6'},
        {'key': 'cycle_consent_worship', 'value': 'true'},
      ];

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      mockDb.cyclePeriods = [
        {'id': '1', 'startDate': todayStr, 'endDate': null}
      ];

      final suspended = await CycleConsentBridge.isWorshipSuspended();
      expect(suspended, true);

      mockDb.appSettings = [
        {'key': 'user_gender', 'value': 'FEMALE'},
        {'key': 'module_cycle_enabled', 'value': 'true'},
        {'key': 'cycle_avg_period', 'value': '6'},
        {'key': 'cycle_consent_worship', 'value': 'false'},
      ];
      final suspended2 = await CycleConsentBridge.isWorshipSuspended();
      expect(suspended2, false);
    });

    test('addFastingDebtIfNeeded registers debt only if cycle_consent_worship is true', () async {
      mockDb.appSettings = [
        {'key': 'cycle_consent_worship', 'value': 'false'},
      ];
      
      const dateStr = '2026-06-25';
      mockDb.cyclePeriods = [
        {'id': 'p1', 'startDate': '2026-06-20', 'endDate': dateStr}
      ];

      await DatabaseHelper.instance.addFastingDebtIfNeeded(mockDb, dateStr);
      expect(mockDb.fastingDebtList.isEmpty, true);

      mockDb.appSettings = [
        {'key': 'cycle_consent_worship', 'value': 'true'},
      ];

      await DatabaseHelper.instance.addFastingDebtIfNeeded(mockDb, dateStr);
      expect(mockDb.fastingDebtList.length, 1);
      expect(mockDb.fastingDebtList.first['daysOwed'], 6);
      expect(mockDb.fastingDebtList.first['isResolved'], 0);
    });
  });
}

class CycleMockDatabase implements Database {
  List<Map<String, Object?>> cyclePeriods = [];
  List<Map<String, Object?>> cycleDayLogs = [];
  List<Map<String, Object?>> appSettings = [];
  List<Map<String, Object?>> energyLogs = [];
  List<Map<String, Object?>> bedtimeDiagnostics = [];
  List<Map<String, Object?>> routineCompletions = [];
  List<Map<String, dynamic>> fastingDebtList = [];

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
    if (table == 'cycle_periods') {
      if (where != null && where.contains('startDate <= ?')) {
        final date = whereArgs![0]! as String;
        final list = cyclePeriods.where((r) => (r['startDate']! as String).compareTo(date) <= 0).toList();
        final mutableList = list.map(Map<String, Object?>.from).toList();
        mutableList.sort((a, b) => (b['startDate']! as String).compareTo(a['startDate']! as String));
        return mutableList;
      }
      if (where != null && where.contains('endDate = ?')) {
        final date = whereArgs![0]! as String;
        final list = cyclePeriods.where((r) => r['endDate'] == date).toList();
        final mutableList = list.map(Map<String, Object?>.from).toList();
        mutableList.sort((a, b) => (b['startDate']! as String).compareTo(a['startDate']! as String));
        return mutableList;
      }
      return cyclePeriods;
    } else if (table == 'cycle_day_logs') {
      return cycleDayLogs;
    } else if (table == 'app_settings') {
      if (where != null && where.contains('key = ?')) {
        final keyVal = whereArgs![0]! as String;
        return appSettings.where((r) => r['key'] == keyVal).toList();
      }
      return appSettings;
    } else if (table == 'energy_logs') {
      return energyLogs;
    } else if (table == 'bedtime_diagnostics') {
      return bedtimeDiagnostics;
    } else if (table == 'routine_completions') {
      return routineCompletions;
    } else if (table == 'fasting_debt') {
      return fastingDebtList;
    }
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == 'fasting_debt') {
      fastingDebtList.removeWhere((r) => r['id'] == values['id']);
      fastingDebtList.add(Map<String, dynamic>.from(values));
      return 1;
    }
    return 0;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == 'fasting_debt') {
      if (where != null && where.contains('id = ?')) {
        final id = whereArgs![0]! as String;
        for (final row in fastingDebtList) {
          if (row['id'] == id) {
            row.addAll(values);
          }
        }
        return 1;
      }
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #query) {
      return query(
        invocation.positionalArguments[0] as String,
        where: invocation.namedArguments[#where] as String?,
        whereArgs: invocation.namedArguments[#whereArgs] as List<Object?>?,
        orderBy: invocation.namedArguments[#orderBy] as String?,
      );
    }
    if (invocation.memberName == #insert) {
      return insert(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
      );
    }
    if (invocation.memberName == #update) {
      return update(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
        where: invocation.namedArguments[#where] as String?,
        whereArgs: invocation.namedArguments[#whereArgs] as List<Object?>?,
      );
    }
    return null;
  }
}
