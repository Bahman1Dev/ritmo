import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/engines/energy_engine.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/notification_decider.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/zone_engine.dart';
import 'package:ritmo/core/domain/models.dart';

void main() {
  group('NotificationDecider Tests', () {
    final defaultSettings = <String, String>{
      'module_religion_enabled': 'true',
      'module_medicine_enabled': 'true',
    };

    test('Node Zero: ignore if module disabled', () {
      final inactiveSettings = {
        'module_religion_enabled': 'false',
        'module_medicine_enabled': 'false',
      };

      final routine = Routine(
        id: 'r1',
        title: 'نماز صبح',
        category: Category.religious,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
      );

      final outcome = NotificationDecider.decide(
        routine: routine,
        appSettings: inactiveSettings,
        isCurrentZoneBlocked: false,
      );

      expect(outcome, DecisionOutcome.ignore);
    });

    test('Essential bypasses blocked zone and low energy', () {
      final routine = Routine(
        id: 'r2',
        title: 'داروی قلب',
        category: Category.medical,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.important,
        isEssential: true,
        energyRule: EnergyRule.highEnergyOnly,
      );

      final outcome = NotificationDecider.decide(
        routine: routine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: true,
      );

      expect(outcome, DecisionOutcome.sendStandard);
    });

    test('Non-essential blocked in blocked zone', () {
      final routine = Routine(
        id: 'r3',
        title: 'ورزش سبک',
        category: Category.fitness,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
      );

      final outcome = NotificationDecider.decide(
        routine: routine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: true,
      );

      expect(outcome, DecisionOutcome.deferOrCancel);
    });

    test('Energy decision matrix matching rules', () {
      final routine = Routine(
        id: 'r4',
        title: 'مطالعه',
        category: Category.personal,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.offerLight,
      );

      // Since energy logic is removed, both should return sendStandard
      final outcome = NotificationDecider.decide(
        routine: routine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: false,
      );
      expect(outcome, DecisionOutcome.sendStandard);
    });

    test('Menstruation ignores religious routines but not others', () {
      final religiousRoutine = Routine(
        id: 'rel1',
        title: 'نماز ظهر',
        category: Category.religious,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      final medicalRoutine = Routine(
        id: 'med1',
        title: 'قرص مسکن',
        category: Category.medical,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.important,
        isEssential: true,
        energyRule: EnergyRule.none,
      );

      // When menstruating is true
      final outcome1 = NotificationDecider.decide(
        routine: religiousRoutine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: false,
        isMenstruating: true,
      );
      expect(outcome1, DecisionOutcome.ignore);

      final outcome2 = NotificationDecider.decide(
        routine: medicalRoutine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: false,
        isMenstruating: true,
      );
      expect(outcome2, DecisionOutcome.sendStandard);

      // When menstruating is false
      final outcome3 = NotificationDecider.decide(
        routine: religiousRoutine,
        appSettings: defaultSettings,
        isCurrentZoneBlocked: false,
      );
      expect(outcome3, DecisionOutcome.sendStandard);
    });
  });

  group('ZoneEngine Tests', () {
    test('Normal range check', () {
      final time = DateTime(2026, 6, 20, 10, 30);
      final isInside = ZoneEngine.isTimeWithinRange(
        time: time,
        startTimeStr: '09:00',
        endTimeStr: '17:00',
      );
      expect(isInside, true);
    });

    test('Cross-midnight range check', () {
      // 23:30 is inside 23:00 to 05:00
      final timeInside = DateTime(2026, 6, 20, 23, 30);
      final isInside = ZoneEngine.isTimeWithinRange(
        time: timeInside,
        startTimeStr: '23:00',
        endTimeStr: '05:00',
      );
      expect(isInside, true);

      // 12:00 is outside 23:00 to 05:00
      final timeOutside = DateTime(2026, 6, 20, 12);
      final isOutside = ZoneEngine.isTimeWithinRange(
        time: timeOutside,
        startTimeStr: '23:00',
        endTimeStr: '05:00',
      );
      expect(isOutside, false);
    });

    test('Weekday index mapping conversions', () {
      // Test displayIndexToDartWeekday
      expect(ZoneEngine.displayIndexToDartWeekday(0), 6); // Saturday -> 6
      expect(ZoneEngine.displayIndexToDartWeekday(1), 7); // Sunday -> 7
      expect(ZoneEngine.displayIndexToDartWeekday(2), 1); // Monday -> 1
      expect(ZoneEngine.displayIndexToDartWeekday(3), 2); // Tuesday -> 2
      expect(ZoneEngine.displayIndexToDartWeekday(4), 3); // Wednesday -> 3
      expect(ZoneEngine.displayIndexToDartWeekday(5), 4); // Thursday -> 4
      expect(ZoneEngine.displayIndexToDartWeekday(6), 5); // Friday -> 5

      // Test dartWeekdayToDisplayIndex
      expect(ZoneEngine.dartWeekdayToDisplayIndex(6), 0); // Saturday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(7), 1); // Sunday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(1), 2); // Monday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(2), 3); // Tuesday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(3), 4); // Wednesday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(4), 5); // Thursday
      expect(ZoneEngine.dartWeekdayToDisplayIndex(5), 6); // Friday

      // Out of bounds checks
      expect(() => ZoneEngine.displayIndexToDartWeekday(-1), throwsArgumentError);
      expect(() => ZoneEngine.displayIndexToDartWeekday(7), throwsArgumentError);
      expect(() => ZoneEngine.dartWeekdayToDisplayIndex(0), throwsArgumentError);
      expect(() => ZoneEngine.dartWeekdayToDisplayIndex(8), throwsArgumentError);
    });

    test('Weekly Minutes Schedule Generator', () {
      // Normal: Sat (6) 08:00 to 17:00
      // Day offset = (6-1)*1440 = 7200
      // Start = 7200 + 480 = 7680
      // End = 7200 + 1020 = 8220
      final normalRange = ZoneEngine.getWeeklyMinutesForSchedule(6, '08:00', '17:00');
      expect(normalRange.length, 1);
      expect(normalRange[0][0], 7680);
      expect(normalRange[0][1], 8220);

      // Cross-midnight: Sat (6) 23:00 to Sun (7) 07:00
      // Sat Day offset = 7200
      // Sun Day offset = 8640
      // Start = 7200 + 23*60 = 8580
      // End = 8640 + 7*60 = 9060
      final crossRange = ZoneEngine.getWeeklyMinutesForSchedule(6, '23:00', '07:00');
      expect(crossRange.length, 1);
      expect(crossRange[0][0], 8580);
      expect(crossRange[0][1], 9060);

      // Cross-week wrapping: Sun (7) 23:00 to Mon (1) 07:00
      // Sun offset = 8640
      // Mon offset = 0
      // Start = 8640 + 1380 = 10020
      // End = 0 + 420 = 420
      final wrappingRange = ZoneEngine.getWeeklyMinutesForSchedule(7, '23:00', '07:00');
      expect(wrappingRange.length, 2);
      expect(wrappingRange[0][0], 10020);
      expect(wrappingRange[0][1], 10080); // end of week
      expect(wrappingRange[1][0], 0);
      expect(wrappingRange[1][1], 420); // start of week
    });

    test('Zone Schedules Overlap Check logic', () {
      final existing = [
        {
          'daysOfWeek': '6,7,1,2,3', // Saturday to Wednesday
          'startTime': '08:00',
          'endTime': '17:00',
          'zoneName': 'کار',
        },
      ];

      // Overlap: Same days (Saturday), overlapping hours (09:00 - 12:00)
      final overlapRes = ZoneEngine.checkOverlap(
        proposedDays: {6},
        proposedStart: '09:00',
        proposedEnd: '12:00',
        existingSchedules: existing,
      );
      expect(overlapRes['hasOverlap'], true);
      expect(overlapRes['suggestedStart'], '17:00');

      // No Overlap: Same days (Saturday), different hours (18:00 - 20:00)
      final noOverlapRes1 = ZoneEngine.checkOverlap(
        proposedDays: {6},
        proposedStart: '18:00',
        proposedEnd: '20:00',
        existingSchedules: existing,
      );
      expect(noOverlapRes1['hasOverlap'], false);

      // No Overlap: Different days (Thursday), same hours (08:00 - 17:00)
      final noOverlapRes2 = ZoneEngine.checkOverlap(
        proposedDays: {4},
        proposedStart: '08:00',
        proposedEnd: '17:00',
        existingSchedules: existing,
      );
      expect(noOverlapRes2['hasOverlap'], false);
    });
  });

  group('EnergyEngine Tests', () {
    test('Return default energy when no logs present', () {
      final resolved = EnergyEngine.resolve(
        logs: [],
        validityMinutes: 180,
        defaultEnergy: EnergyLevel.medium,
        now: DateTime.now(),
      );
      expect(resolved, EnergyLevel.medium);
    });

    test('Return energy from log when within validity window', () {
      final now = DateTime.now();
      final logs = [
        EnergyLog(
          id: 'log1',
          energyLevel: EnergyLevel.high,
          source: 'MANUAL',
          loggedAt: now.subtract(const Duration(minutes: 60)),
        ),
      ];

      final resolved = EnergyEngine.resolve(
        logs: logs,
        validityMinutes: 180,
        defaultEnergy: EnergyLevel.medium,
        now: now,
      );
      expect(resolved, EnergyLevel.high);
    });

    test('Return default energy when latest log is stale', () {
      final now = DateTime.now();
      final logs = [
        EnergyLog(
          id: 'log2',
          energyLevel: EnergyLevel.high,
          source: 'MANUAL',
          loggedAt: now.subtract(const Duration(minutes: 200)),
        ),
      ];

      final resolved = EnergyEngine.resolve(
        logs: logs,
        validityMinutes: 180,
        defaultEnergy: EnergyLevel.medium,
        now: now,
      );
      expect(resolved, EnergyLevel.medium);
    });
  });

  group('ContextEngine Tests', () {
    test('Propose highest priority executable task', () {
      final now = DateTime.now();
      final settings = {'module_religion_enabled': 'true'};

      final lowPriorityRoutine = Routine(
        id: 'low',
        title: 'کار کم اهمیت',
        category: Category.personal,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.normal,
        isEssential: false,
        energyRule: EnergyRule.none,
      );

      final highPriorityRoutine = Routine(
        id: 'high',
        title: 'کار مهم',
        category: Category.personal,
        routineType: RoutineType.timeBased,
        notificationLevel: NotificationLevel.important,
        isEssential: false,
        energyRule: EnergyRule.none,
        priority: 2,
      );

      final tasks = [
        RoutineTask(routine: lowPriorityRoutine, scheduledTime: now.add(const Duration(minutes: 10))),
        RoutineTask(routine: highPriorityRoutine, scheduledTime: now.add(const Duration(minutes: 20))),
      ];

      final next = ContextEngine.getNextProposedTask(
        activeTasksForToday: tasks,
        completedRoutineIdsToday: [],
        appSettings: settings,
        blockedZoneIdsForRoutines: {},
      );

      // Should choose highPriorityRoutine because its priority is 2.0 > 1.0
      expect(next?.routine.id, 'high');
    });
  });

  group('MedicalEngine Tests', () {
    test('checkOverdoseStatus detects normal safe use', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prnLogs = [
        now - 4 * 60 * 60 * 1000, // 4 hours ago
      ];
      final status = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: prnLogs,
        minIntervalHours: 2,
        maxDosesPerDay: 4,
      );
      expect(status, OverdoseResult.safe);
    });

    test('checkOverdoseStatus detects warning under interval', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prnLogs = [
        now - 1 * 60 * 60 * 1000, // 1 hour ago
      ];
      final status = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: prnLogs,
        minIntervalHours: 2,
        maxDosesPerDay: 4,
      );
      expect(status, OverdoseResult.warningUnderInterval);
    });

    test('checkOverdoseStatus detects warning max limit exceeded', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prnLogs = [
        now - 5 * 60 * 60 * 1000,
        now - 4 * 60 * 60 * 1000,
        now - 3 * 60 * 60 * 1000,
      ];
      final status = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: prnLogs,
        minIntervalHours: 1,
        maxDosesPerDay: 3,
      );
      expect(status, OverdoseResult.warningMaxLimitExceeded);
    });

    test('isRefillNeeded alerts on low stock', () {
      expect(MedicalEngine.isRefillNeeded(stockCount: 5, warningThreshold: 10), true);
      expect(MedicalEngine.isRefillNeeded(stockCount: 0, warningThreshold: 10), false);
      expect(MedicalEngine.isRefillNeeded(stockCount: 15, warningThreshold: 10), false);
    });
  });

  group('ReshuffleEngine Tests', () {
    final now = DateTime(2026, 6, 20, 12);

    test('Reshuffle compresses task if possible', () {
      final todayTasks = [
        RoutineTask(
          routine: Routine(
            id: 'r1',
            title: 'ورزش',
            category: Category.fitness,
            routineType: RoutineType.timeBased,
            notificationLevel: NotificationLevel.normal,
            isEssential: false,
            energyRule: EnergyRule.none,
            targetDurationMinutes: 60,
            lightDurationMinutes: 30,
            minimalDurationMinutes: 15,
          ),
          scheduledTime: now,
        ),
      ];

      final event = ReshuffleEvent(
        id: 'evt1',
        title: 'جلسه ناگهانی',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );

      final result = ReshuffleEngine.decideReshuffle(
        event: event,
        todayTasks: todayTasks,
        tomorrowTasks: [],
        preferredRoutineIds: {},
        maxCapacityMinutesTomorrow: 360,
      );

      expect(result.success, true);
      expect(result.actions.length, 1);
      expect(result.actions.first.actionType, ReshuffleActionType.compress);
      expect(result.actions.first.newDuration, 15);
    });

    test('Reshuffle fails when conflicting with essential task', () {
      final todayTasks = [
        RoutineTask(
          routine: Routine(
            id: 'r1',
            title: 'داروی حیاتی',
            category: Category.medical,
            routineType: RoutineType.timeBased,
            notificationLevel: NotificationLevel.important,
            isEssential: true,
            energyRule: EnergyRule.none,
          ),
          scheduledTime: now,
        ),
      ];

      final event = ReshuffleEvent(
        id: 'evt1',
        title: 'جلسه',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );

      final result = ReshuffleEngine.decideReshuffle(
        event: event,
        todayTasks: todayTasks,
        tomorrowTasks: [],
        preferredRoutineIds: {},
        maxCapacityMinutesTomorrow: 360,
      );

      expect(result.success, false);
      expect(result.message, contains('حیاتی'));
    });
  });
}
