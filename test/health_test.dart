import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/features/health/models/health_models.dart';

void main() {
  group('Medical Overdose and Refill Tests', () {
    test('checkOverdoseStatus - safe path when no logs exist', () {
      final res = MedicalEngine.checkOverdoseStatus(
        now: DateTime.now().millisecondsSinceEpoch,
        prnLogs24h: [],
        minIntervalHours: 4,
        maxDosesPerDay: 4,
      );
      expect(res, OverdoseResult.safe);
    });

    test('checkOverdoseStatus - warning when interval is violated', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final logs = [now - (2 * 60 * 60 * 1000)]; // 2 hours ago

      final res = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: logs,
        minIntervalHours: 4, // 4 hours min interval
        maxDosesPerDay: 4,
      );
      expect(res, OverdoseResult.warningUnderInterval);
    });

    test('checkOverdoseStatus - warning when max doses per day is reached', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 4 doses taken in last 24 hours
      final logs = [
        now - (20 * 60 * 60 * 1000),
        now - (15 * 60 * 60 * 1000),
        now - (10 * 60 * 60 * 1000),
        now - (5 * 60 * 60 * 1000),
      ];

      final res = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: logs,
        minIntervalHours: 4,
        maxDosesPerDay: 4, // max 4 doses per day
      );
      expect(res, OverdoseResult.warningMaxLimitExceeded);
    });

    test('isRefillNeeded - correctly identifies low stock', () {
      expect(MedicalEngine.isRefillNeeded(stockCount: 3, warningThreshold: 5), isTrue);
      expect(MedicalEngine.isRefillNeeded(stockCount: 0, warningThreshold: 5), isFalse);
      expect(MedicalEngine.isRefillNeeded(stockCount: 10, warningThreshold: 5), isFalse);
    });
  });

  group('Blood Sugar Classification Tests', () {
    test('isInRange - identifies value in target range', () {
      final log = BloodSugarLog(
        id: 'bs_test',
        value: 95,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(log.isInRange(70, 100), isTrue);
      expect(log.isInRange(80, 130), isTrue);
      expect(log.isInRange(110, 140), isFalse);
    });
  });

  group('Blood Pressure Stage Tests', () {
    test('stageLabel - correctly classifies crisis and stages', () {
      final normal = BloodPressureLog(
        id: 'bp_normal',
        systolic: 115,
        diastolic: 75,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(normal.stageLabel, 'نرمال');

      final elevated = BloodPressureLog(
        id: 'bp_elevated',
        systolic: 125,
        diastolic: 75,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(elevated.stageLabel, 'پیش فشار خون');

      final stage1 = BloodPressureLog(
        id: 'bp_s1',
        systolic: 135,
        diastolic: 82,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(stage1.stageLabel, 'فشار خون مرحله ۱');

      final stage2 = BloodPressureLog(
        id: 'bp_s2',
        systolic: 145,
        diastolic: 95,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(stage2.stageLabel, 'فشار خون مرحله ۲');

      final crisis = BloodPressureLog(
        id: 'bp_crisis',
        systolic: 190,
        diastolic: 125,
        loggedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(crisis.stageLabel, 'بحران فشار خون');
    });
  });

  group('Vaccination Days Until Next Dose Tests', () {
    test('daysUntilNextDose - calculates correctly', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 10));

      final vac = Vaccination(
        id: 'vac_test',
        vaccineName: 'Measles',
        nextDoseDue: targetDate.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      expect(vac.isDue, isFalse);
      expect(vac.daysUntilNextDose, 10);
    });

    test('isDue - is true when target date has passed', () {
      final now = DateTime.now();
      final targetDate = now.subtract(const Duration(days: 2));

      final vac = Vaccination(
        id: 'vac_test2',
        vaccineName: 'Polio',
        nextDoseDue: targetDate.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      expect(vac.isDue, isTrue);
      expect(vac.daysUntilNextDose, -2);
    });
  });

  group('HealthEngine Analytics Tests', () {
    final today = DateTime(2026, 6, 26);
    final nowMs = today.millisecondsSinceEpoch;

    test('calculateSync - processes 100% adherence and streaks', () {
      final input = HealthEngineInput(
        bloodSugarLogs: [],
        bloodPressureLogs: [],
        vitalSignLogs: [],
        medicationLogs: [
          MedicationLog(id: 'm1', routineId: 'r1', scheduledTime: nowMs, createdAt: nowMs),
          MedicationLog(id: 'm2', routineId: 'r1', scheduledTime: nowMs - 24 * 3600 * 1000, createdAt: nowMs - 24 * 3600 * 1000),
        ],
        prnLogs: [],
        energyLogs: [],
        sleepLogs: [],
        hasDiabetes: false,
        hasHypertension: false,
        today: today,
      );

      final output = HealthEngine.calculateSync(input);
      expect(output.adherence.adherenceRate, 1.0);
      expect(output.adherence.currentStreak, 2);
      expect(output.adherence.longestStreak, 2);
    });

    test('calculateSync - processes partial adherence and missed pattern', () {
      final morningTime = DateTime(2026, 6, 26, 8).millisecondsSinceEpoch;
      final afternoonTime = DateTime(2026, 6, 25, 14).millisecondsSinceEpoch;

      final input = HealthEngineInput(
        bloodSugarLogs: [],
        bloodPressureLogs: [],
        vitalSignLogs: [],
        medicationLogs: [
          MedicationLog(id: 'm1', routineId: 'r1', scheduledTime: morningTime, status: 'SKIPPED', createdAt: morningTime),
          MedicationLog(id: 'm2', routineId: 'r1', scheduledTime: afternoonTime, createdAt: afternoonTime),
        ],
        prnLogs: [],
        energyLogs: [],
        sleepLogs: [],
        hasDiabetes: false,
        hasHypertension: false,
        today: today,
      );

      final output = HealthEngine.calculateSync(input);
      expect(output.adherence.adherenceRate, 0.5);
      expect(output.adherence.missedPattern, 'صبح‌ها بیشتر فراموش می‌شود');
    });

    test('calculateSync - processes trends, averages, and direction', () {
      final input = HealthEngineInput(
        bloodSugarLogs: [
          BloodSugarLog(id: 'bs1', value: 80, loggedAt: nowMs - 4 * 24 * 3600 * 1000),
          BloodSugarLog(id: 'bs2', value: 85, loggedAt: nowMs - 3 * 24 * 3600 * 1000),
          BloodSugarLog(id: 'bs3', value: 110, loggedAt: nowMs - 2 * 24 * 3600 * 1000),
          BloodSugarLog(id: 'bs4', value: 120, loggedAt: nowMs),
        ],
        bloodPressureLogs: [],
        vitalSignLogs: [],
        medicationLogs: [],
        prnLogs: [],
        energyLogs: [],
        sleepLogs: [],
        hasDiabetes: false,
        hasHypertension: false,
        today: today,
      );

      final output = HealthEngine.calculateSync(input);
      final sugarTrend = output.trends.firstWhere((t) => t.metric == 'blood_sugar');
      expect(sugarTrend.average, 98.75);
      expect(sugarTrend.direction, 'up'); // rising sugar trend
      expect(sugarTrend.inRangePercent, 50.0); // 2 of 4 fasting logs are between 70-100
    });

    test('calculateSync - processes correlations (positive/negative/null)', () {
      final tMs = today.millisecondsSinceEpoch;
      final input = HealthEngineInput(
        bloodSugarLogs: [
          BloodSugarLog(id: 'bs1', value: 80, loggedAt: tMs - 2 * 24 * 3600 * 1000),
          BloodSugarLog(id: 'bs2', value: 90, loggedAt: tMs - 1 * 24 * 3600 * 1000),
          BloodSugarLog(id: 'bs3', value: 100, loggedAt: tMs),
        ],
        bloodPressureLogs: [],
        vitalSignLogs: [],
        medicationLogs: [],
        prnLogs: [],
        energyLogs: [
          {'createdAt': tMs - 2 * 24 * 3600 * 1000, 'value': 'LOW'},     // 1.0
          {'createdAt': tMs - 1 * 24 * 3600 * 1000, 'value': 'MEDIUM'},  // 3.0
          {'createdAt': tMs, 'value': 'HIGH'},                           // 5.0
        ],
        sleepLogs: [], // No sleep logs
        hasDiabetes: false,
        hasHypertension: false,
        today: today,
      );

      final output = HealthEngine.calculateSync(input);
      final sugarEnergy = output.correlations.firstWhere((c) => c.metric == 'sugar_energy');
      expect(sugarEnergy.coefficient, closeTo(1.0, 0.01)); // Perfect positive correlation (80->1, 90->3, 100->5)

      final sugarSleep = output.correlations.firstWhere((c) => c.metric == 'sugar_sleep');
      expect(sugarSleep.coefficient, isNull); // Insufficient sleep logs
    });
  });

  group('MedicationLog Model and Status Tests', () {
    test('toMap and fromMap works correctly', () {
      final log = MedicationLog(
        id: 'ml_123',
        routineId: 'r_123',
        scheduledTime: 1000,
        takenTime: 2000,
        status: 'SKIPPED',
        note: 'Forgot',
        createdAt: 3000,
      );

      final map = log.toMap();
      expect(map['id'], 'ml_123');
      expect(map['routineId'], 'r_123');
      expect(map['scheduledTime'], 1000);
      expect(map['takenTime'], 2000);
      expect(map['status'], 'SKIPPED');
      expect(map['note'], 'Forgot');
      expect(map['createdAt'], 3000);

      final log2 = MedicationLog.fromMap(map);
      expect(log2.id, 'ml_123');
      expect(log2.routineId, 'r_123');
      expect(log2.scheduledTime, 1000);
      expect(log2.takenTime, 2000);
      expect(log2.status, 'SKIPPED');
      expect(log2.note, 'Forgot');
      expect(log2.createdAt, 3000);
    });

    test('default status is TAKEN', () {
      final log = MedicationLog(
        id: 'ml_default',
        routineId: 'r_default',
        createdAt: 3000,
      );
      expect(log.status, 'TAKEN');
    });
  });
}
