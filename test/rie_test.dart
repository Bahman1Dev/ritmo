import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/hormonal_intelligence_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/engines/systems_hub_logic.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:sqflite/sqflite.dart';

class RiemockDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {};

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

    if (table == 'calendar_exceptions') {
      final targetDate = whereArgs![0]! as String;
      return list.where((row) => row['date'] == targetDate).toList();
    }
    if (table == 'worship_seasons') {
      final targetDate = whereArgs!.length > 1 && whereArgs[1] is String ? whereArgs[1]! as String : whereArgs[0]! as String;
      return list.where((row) {
        return row['isActive'] == 1 &&
            (row['startDate'] as String).compareTo(targetDate) <= 0 &&
            (row['endDate'] as String).compareTo(targetDate) >= 0;
      }).toList();
    }
    if (table == 'konkur_mock_exams') {
      final targetDate = whereArgs![0]! as String;
      return list.where((row) => row['examDate'] == targetDate).toList();
    }
    if (table == 'routines') {
      return list;
    }
    if (table == 'routine_schedules') {
      if (where.contains('routineId = ?')) {
        final rId = whereArgs![0]! as String;
        return list.where((row) => row['routineId'] == rId).toList();
      }
      return list;
    }
    if (table == 'routine_zone_rules') {
      final zoneId = whereArgs![0]! as String;
      final ruleType = whereArgs[1]! as String;
      return list.where((row) => row['zoneId'] == zoneId && row['ruleType'] == ruleType).toList();
    }
    if (table == 'routine_completions') {
      final compDate = whereArgs![0]! as String;
      return list.where((row) => row['completionDate'] == compDate && row['resultType'] != 'SNOOZED').toList();
    }
    if (table == 'cycle_logs') {
      if (where.contains('cycleStartDate <= ?')) {
        final targetDate = whereArgs![0]! as String;
        return list.where((row) {
          final start = row['cycleStartDate'] as String;
          final end = row['cycleEndDate'] as String?;
          return start.compareTo(targetDate) <= 0 && (end == null || end.compareTo(targetDate) >= 0);
        }).toList();
      }
      return list;
    }

    return list;
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables[table] ?? [];
    if (where == null) {
      for (final row in list) {
        row.addAll(values);
      }
      return list.length;
    }
    
    if (table == 'cycle_logs' && where.contains('id = ?')) {
      final targetId = whereArgs![0]! as String;
      var count = 0;
      for (final row in list) {
        if (row['id'] == targetId) {
          final editable = Map<String, dynamic>.from(row);
          editable.addAll(values);
          list[list.indexOf(row)] = editable;
          count++;
        }
      }
      return count;
    }
    if (table == 'worship_debts' && where.contains('id = ?')) {
      final targetId = whereArgs![0]! as String;
      var count = 0;
      for (final row in list) {
        if (row['id'] == targetId) {
          final editable = Map<String, dynamic>.from(row);
          editable.addAll(values);
          list[list.indexOf(row)] = editable;
          count++;
        }
      }
      return count;
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('RitmoIntelligenceEngine resolveDailyBehavior Tests', () {
    late RiemockDatabase mockDb;
    late Map<String, String> defaultSettings;

    setUp(() {
      mockDb = RiemockDatabase();
      defaultSettings = {
        'module_religion_enabled': 'true',
        'daily_capacity_minutes': '120',
      };
    });

    test('SICK priority overrides all other exception contexts', () async {
      final date = DateTime(2026, 6, 21);
      const dateStr = '2026-06-21';

      mockDb.tables['calendar_exceptions'] = [
        {'date': dateStr, 'exceptionType': 'SICK', 'behavior': 'ESSENTIAL_ONLY'},
        {'date': dateStr, 'exceptionType': 'TRAVEL', 'behavior': 'SILENCE_ALL'},
      ];

      mockDb.tables['konkur_mock_exams'] = [
        {'id': 'e1', 'title': 'کنکور آزمایشی', 'examDate': dateStr}
      ];

      final dailyBehavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        date: date,
        db: mockDb,
        settings: defaultSettings,
      );

      expect(dailyBehavior.context, LifeContext.sick);
      expect(dailyBehavior.behavior, 'ESSENTIAL_ONLY');
    });

    test('TRAVEL overrides EXAM and BUSY', () async {
      final date = DateTime(2026, 6, 21);
      const dateStr = '2026-06-21';

      mockDb.tables['calendar_exceptions'] = [
        {'date': dateStr, 'exceptionType': 'TRAVEL', 'behavior': 'SILENCE_ALL'},
      ];

      mockDb.tables['konkur_mock_exams'] = [
        {'id': 'e1', 'title': 'کنکور آزمایشی', 'examDate': dateStr}
      ];

      final dailyBehavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        date: date,
        db: mockDb,
        settings: defaultSettings,
      );

      expect(dailyBehavior.context, LifeContext.travel);
      expect(dailyBehavior.behavior, 'SILENCE_ALL');
    });

    test('EXAM overrides BUSY', () async {
      final date = DateTime(2026, 6, 21);
      const dateStr = '2026-06-21';

      mockDb.tables['konkur_mock_exams'] = [
        {'id': 'e1', 'title': 'کنکور آزمایشی', 'examDate': dateStr}
      ];

      // Set routines duration that exceeds capacity (busy)
      mockDb.tables['routines'] = [
        {'id': 'r1', 'routineType': 'timeBased', 'targetDurationMinutes': 80, 'isArchived': 0},
        {'id': 'r2', 'routineType': 'timeBased', 'targetDurationMinutes': 80, 'isArchived': 0},
      ];

      mockDb.tables['routine_schedules'] = [
        {'routineId': 'r1', 'daysOfWeek': '7'}, // Sunday (date 2026-06-21 is Sunday)
        {'routineId': 'r2', 'daysOfWeek': '7'},
      ];

      final dailyBehavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        date: date,
        db: mockDb,
        settings: defaultSettings,
      );

      expect(dailyBehavior.context, LifeContext.exam);
    });

    test('WORSHIP season active returns worship context if religion enabled', () async {
      final date = DateTime(2026, 6, 21);

      mockDb.tables['worship_seasons'] = [
        {
          'id': 's1',
          'seasonType': 'RAMADAN',
          'title': 'Ramadan',
          'startDate': '2026-06-01',
          'endDate': '2026-06-30',
          'isActive': 1,
          'behaviorJson': 'ESSENTIAL_ONLY'
        }
      ];

      final dailyBehavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        date: date,
        db: mockDb,
        settings: defaultSettings,
      );

      expect(dailyBehavior.context, LifeContext.worship);
      expect(dailyBehavior.behavior, 'ESSENTIAL_ONLY');
      expect(dailyBehavior.activeWorshipSeasonTitle, 'Ramadan');
    });
  });

  group('RitmoIntelligenceEngine evaluate pipeline Tests', () {
    late RiemockDatabase mockDb;
    late Map<String, String> appSettings;

    setUp(() {
      mockDb = RiemockDatabase();
      appSettings = {
        'module_religion_enabled': 'true',
        'module_medicine_enabled': 'true',
        'module_courses_enabled': 'true',
        'daily_capacity_minutes': '360',
      };
    });

    test('Biological constraints: menstruating suppresses religious routines but not others', () async {
      final religiousRoutine = Routine(
        id: 'rel1',
        title: 'نماز صبح',
        category: Category.religious,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      final medicalRoutine = Routine(
        id: 'med1',
        title: 'قرص فشار',
        category: Category.medical,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      final result = await RitmoIntelligenceEngine.evaluate(
        routines: [religiousRoutine, medicalRoutine],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.high,
        isMenstruating: true,
        now: DateTime(2026, 6, 21),
        db: mockDb,
      );

      expect(result.visibleRoutines.any((r) => r.id == 'rel1'), false);
      expect(result.visibleRoutines.any((r) => r.id == 'med1'), true);
      expect(result.hiddenRoutines.any((r) => r.id == 'rel1'), true);
    });

    test('Scoring and Boosting: context boosts appropriate categories', () async {
      final studyRoutine = Routine(
        id: 'study',
        title: 'خواندن زیست',
        category: Category.learning,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
      );

      final funRoutine = Routine(
        id: 'fun',
        title: 'بازی رایانه‌ای',
        category: Category.free,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
      );

      // SICK context is active
      mockDb.tables['calendar_exceptions'] = [
        {'date': '2026-06-21', 'exceptionType': 'SICK', 'behavior': 'NORMAL'},
      ];

      await RitmoIntelligenceEngine.evaluate(
        routines: [studyRoutine, funRoutine],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.medium,
        isMenstruating: false,
        now: DateTime(2026, 6, 21),
        db: mockDb,
      );

      // Fitness routines would be suppressed under SICK, but study vs fun:
      // Study has category learning, Fun has category free.
      // Under SICK, study is normal, fun is normal. Let's see what is suggested.
      // Now let's try with EXAM context
      mockDb.tables['calendar_exceptions'] = [
        {'date': '2026-06-21', 'exceptionType': 'EXAM', 'behavior': 'NORMAL'},
      ];

      final resultExam = await RitmoIntelligenceEngine.evaluate(
        routines: [studyRoutine, funRoutine],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.medium,
        isMenstruating: false,
        now: DateTime(2026, 6, 21),
        db: mockDb,
      );

      expect(resultExam.suggestedRoutine?.id, 'study');
    });

    test('Critical Alerts: stock refill warning and scheduling overlaps', () async {
      final medRoutine = Routine(
        id: 'med',
        title: 'انسولین',
        category: Category.medical,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.important,
        isEssential: true,
        energyRule: EnergyRule.none,
        medStockCount: 2,
        medRefillThreshold: 5,
      );

      final routineA = Routine(
        id: 'a',
        title: 'ورزش صبحگاهی',
        category: Category.fitness,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
        targetDurationMinutes: 30,
      );

      final routineB = Routine(
        id: 'b',
        title: 'صبحانه کاری',
        category: Category.work,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
        targetDurationMinutes: 45,
      );

      // Sunday = 7
      mockDb.tables['routine_schedules'] = [
        {'routineId': 'a', 'timeOfDay': '08:00', 'daysOfWeek': '7'},
        {'routineId': 'b', 'timeOfDay': '08:15', 'daysOfWeek': '7'}, // 15 mins offset, overlap exists!
      ];

      final result = await RitmoIntelligenceEngine.evaluate(
        routines: [medRoutine, routineA, routineB],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.high,
        isMenstruating: false,
        now: DateTime(2026, 6, 21),
        db: mockDb,
      );

      expect(result.criticalAlerts.any((msg) => msg.contains('انسولین')), true);
      expect(result.criticalAlerts.any((msg) => msg.contains('تداخل زمانی')), true);
    });
  });

  group('Ritmo Hormonal & Fiqh Engine Tests', () {
    late RiemockDatabase mockDb;
    late Map<String, String> appSettings;

    setUp(() {
      mockDb = RiemockDatabase();
      appSettings = {
        'module_religion_enabled': 'true',
        'module_cycle_enabled': 'true',
        'user_gender': 'FEMALE',
        'cycle_length_days': '28',
        'period_duration_days': '7',
        'daily_capacity_minutes': '360',
      };
      mockDb.tables['app_settings'] = appSettings.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
    });

    test('Fiqh fasting Qada debt creation and prayer suppression during menstruation', () async {
      final now = DateTime(2026, 6, 21);
      const dateStr = '2026-06-21';

      // Seed cycle logs with active period
      mockDb.tables['cycle_logs'] = [
        {
          'id': 'log_1',
          'cycleStartDate': dateStr,
          'cycleEndDate': null,
          'suppressedPrayer': 1,
          'fastDebtCreated': 0,
        }
      ];

      // Seed worship seasons with Ramadan
      mockDb.tables['worship_seasons'] = [
        {
          'id': 'season_1',
          'seasonType': 'RAMADAN',
          'title': 'رمضان',
          'startDate': '2026-06-01',
          'endDate': '2026-06-30',
          'isActive': 1,
        }
      ];

      final prayerRoutine = Routine(
        id: 'prayer',
        title: 'نماز ظهر',
        category: Category.religious,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      final result = await RitmoIntelligenceEngine.evaluate(
        routines: [prayerRoutine],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.high,
        isMenstruating: true,
        now: now,
        db: mockDb,
      );

      // 1. Verify prayer routine is suppressed
      expect(result.visibleRoutines.any((r) => r.id == 'prayer'), false);
      expect(result.hiddenRoutines.any((r) => r.id == 'prayer'), true);

      // 2. Verify fasting debt is NOT created in database (Phase 4 interaction safety)
      final debts = mockDb.tables['worship_debts'] ?? [];
      expect(debts.isEmpty, true);

      // 3. Verify fastDebtCreated remains 0 (Phase 4 interaction safety)
      final logs = mockDb.tables['cycle_logs'] ?? [];
      expect(logs.first['fastDebtCreated'], 0);
    });

    test('Fitness routine intensity adjustments during active menstruation', () async {
      final now = DateTime(2026, 6, 21);
      
      final fitnessRoutine = Routine(
        id: 'workout',
        title: 'دویدن سنگین',
        category: Category.fitness,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.offerLight,
      );

      final result = await RitmoIntelligenceEngine.evaluate(
        routines: [fitnessRoutine],
        appSettings: appSettings,
        activeZoneId: null,
        activeZoneMode: 'NORMAL',
        currentEnergy: EnergyLevel.high,
        isMenstruating: true,
        now: now,
        db: mockDb,
      );

      // Fitness routine should suggest light version under active menstruation
      expect(result.suggestLightVersion, true);
    });

    test('HormonalIntelligenceEngine phase classifications', () async {
      final now = DateTime(2026, 6, 21);
      const dateStr = '2026-06-21';

      // 1. Test Active Menstruation phase (day 1 to 7)
      mockDb.tables['cycle_logs'] = [
        {
          'id': 'log_1',
          'cycleStartDate': dateStr, // Today is day 1
          'cycleEndDate': null,
          'suppressedPrayer': 1,
          'fastDebtCreated': 0,
        }
      ];

      final outputActive = await HormonalIntelligenceEngine.evaluate(
        db: mockDb,
        appSettings: appSettings,
        now: now,
      );
      expect(outputActive.state, HormonalPhase.menstrual);
      expect(outputActive.fiqhState.prayerSuspended, true);
      expect(outputActive.fiqhState.fastingSuspended, true);

      // 2. Test Post-Cycle phase (predicted day 10)
      mockDb.tables['cycle_logs'] = [
        {
          'id': 'log_1',
          'cycleStartDate': '2026-06-12', // 9 days ago, today is day 10
          'cycleEndDate': '2026-06-18',
          'suppressedPrayer': 1,
          'fastDebtCreated': 0,
        }
      ];

      final outputPost = await HormonalIntelligenceEngine.evaluate(
        db: mockDb,
        appSettings: appSettings,
        now: now,
      );
      expect(outputPost.state, HormonalPhase.postCycle);
      expect(outputPost.fiqhState.prayerSuspended, false);

      // 3. Test Pre-Cycle phase (predicted day 25)
      mockDb.tables['cycle_logs'] = [
        {
          'id': 'log_1',
          'cycleStartDate': '2026-05-28', // 24 days ago, today is day 25
          'cycleEndDate': '2026-06-03',
          'suppressedPrayer': 1,
          'fastDebtCreated': 0,
        }
      ];

      final outputPre = await HormonalIntelligenceEngine.evaluate(
        db: mockDb,
        appSettings: appSettings,
        now: now,
      );
      expect(outputPre.state, HormonalPhase.preCycle);
    });
  });

  group('SystemsHubLogic Tests', () {
    test('isCycleVisible returns true for female genders and false for males', () {
      expect(SystemsHubLogic.isCycleVisible('FEMALE'), true);
      expect(SystemsHubLogic.isCycleVisible('female'), false);
      expect(SystemsHubLogic.isCycleVisible('woman'), false);
      expect(SystemsHubLogic.isCycleVisible('زن'), false);
      expect(SystemsHubLogic.isCycleVisible('MALE'), false);
      expect(SystemsHubLogic.isCycleVisible('مرد'), false);
      expect(SystemsHubLogic.isCycleVisible('OTHER'), false);
    });

    test('determineReligionStatus handles combinations of enable and cityId', () {
      expect(SystemsHubLogic.determineReligionStatus(false, null), ModuleStatus.inactive);
      expect(SystemsHubLogic.determineReligionStatus(false, '1'), ModuleStatus.inactive);
      expect(SystemsHubLogic.determineReligionStatus(true, null), ModuleStatus.setupRequired);
      expect(SystemsHubLogic.determineReligionStatus(true, ''), ModuleStatus.setupRequired);
      expect(SystemsHubLogic.determineReligionStatus(true, 'UNSET'), ModuleStatus.setupRequired);
      expect(SystemsHubLogic.determineReligionStatus(true, '12'), ModuleStatus.active);
    });

    test('determineKonkurStatus handles combinations of enable and hasSubjects', () {
      expect(SystemsHubLogic.determineKonkurStatus(false, false), ModuleStatus.inactive);
      expect(SystemsHubLogic.determineKonkurStatus(false, true), ModuleStatus.inactive);
      expect(SystemsHubLogic.determineKonkurStatus(true, false), ModuleStatus.setupRequired);
      expect(SystemsHubLogic.determineKonkurStatus(true, true), ModuleStatus.active);
    });

    test('determineGenericStatus returns active or inactive based on enabled', () {
      expect(SystemsHubLogic.determineGenericStatus(true), ModuleStatus.active);
      expect(SystemsHubLogic.determineGenericStatus(false), ModuleStatus.inactive);
    });
  });
}

