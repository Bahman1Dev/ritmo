import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:sqflite/sqflite.dart';

class FiqhState {

  FiqhState({
    required this.prayerSuspended,
    required this.fastingSuspended,
    required this.qadaTracked,
  });
  final bool prayerSuspended;
  final bool fastingSuspended;
  final bool qadaTracked;
}

class PrivateReminder {

  PrivateReminder({
    required this.level,
    required this.message,
    required this.date,
  });
  final String level; // 'T-7', 'T-3', 'T-1', 'T0'
  final String message;
  final DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'message': message,
      'date': date.millisecondsSinceEpoch,
    };
  }
}

class HormonalEngineOutput {

  HormonalEngineOutput({
    required this.state,
    required this.dayOfCycle,
    required this.dayOfMenstruation,
    required this.privateReminderQueue,
    required this.fiqhState,
    required this.nextCycleStartDate,
    required this.hasData,
  });
  final HormonalPhase state;
  final int dayOfCycle;
  final int dayOfMenstruation;
  final List<PrivateReminder> privateReminderQueue;
  final FiqhState fiqhState;
  final DateTime nextCycleStartDate;
  final bool hasData;
}

class HormonalIntelligenceEngine {
  static Future<HormonalEngineOutput> evaluate({
    required Database db,
    required Map<String, String> appSettings,
    required DateTime now,
  }) async {
    final cycleEnabled = appSettings['module_cycle_enabled'] == 'true';
    final isFemale = CyclePrivacyGuard.isVisible(appSettings);

    if (!cycleEnabled || !isFemale) {
      return HormonalEngineOutput(
        state: HormonalPhase.disabled,
        dayOfCycle: 0,
        dayOfMenstruation: 0,
        privateReminderQueue: [],
        fiqhState: FiqhState(
          prayerSuspended: false,
          fastingSuspended: false,
          qadaTracked: false,
        ),
        nextCycleStartDate: now.add(const Duration(days: 14)),
        hasData: false,
      );
    }

    final cycleLength = int.tryParse(appSettings['cycle_length_days'] ?? '28') ?? 28;
    final periodDuration = int.tryParse(appSettings['period_duration_days'] ?? '7') ?? 7;
    final todayStr = now.toIso8601String().substring(0, 10);

    // Query logs to find active menstruation or compute predictions
    final logs = await db.query('cycle_logs', orderBy: 'cycleStartDate DESC');

    if (logs.isEmpty) {
      return HormonalEngineOutput(
        state: HormonalPhase.noData,
        dayOfCycle: 0,
        dayOfMenstruation: 0,
        privateReminderQueue: [],
        fiqhState: FiqhState(
          prayerSuspended: false,
          fastingSuspended: false,
          qadaTracked: false,
        ),
        nextCycleStartDate: now,
        hasData: false,
      );
    }

    var state = HormonalPhase.normal;
    var dayOfCycle = 15;
    var dayOfMenstruation = 0;
    var isActiveCycle = false;

    // Check if there is an active logged period
    Map<String, dynamic>? activeLog;
    for (final log in logs) {
      final startStr = log['cycleStartDate']! as String;
      final endStr = log['cycleEndDate'] as String?;
      
      if (startStr.compareTo(todayStr) <= 0 && (endStr == null || endStr.compareTo(todayStr) >= 0)) {
        activeLog = log;
        isActiveCycle = true;
        break;
      }
    }

    if (isActiveCycle && activeLog != null) {
      state = HormonalPhase.menstrual;
      final start = DateTime.tryParse(activeLog['cycleStartDate'] as String) ?? now;
      dayOfMenstruation = now.difference(start).inDays + 1;
      dayOfCycle = dayOfMenstruation;
    } else {
      final lastLog = logs.first;
      final lastStart = DateTime.tryParse(lastLog['cycleStartDate']! as String) ?? now;
      final daysSinceLastStart = now.difference(lastStart).inDays;
      
      // Calculate current cycle day based on predicted repetition
      dayOfCycle = (daysSinceLastStart % cycleLength) + 1;
      
      if (dayOfCycle <= periodDuration) {
        state = HormonalPhase.menstrual;
        dayOfMenstruation = dayOfCycle;
      } else if (dayOfCycle > periodDuration && dayOfCycle <= periodDuration + 7) {
        state = HormonalPhase.postCycle;
      } else if (dayOfCycle >= cycleLength - 7) {
        state = HormonalPhase.preCycle;
      } else {
        state = HormonalPhase.normal;
      }
    }

    // Set suggestions based on cycle phase
    var fiqh = FiqhState(prayerSuspended: false, fastingSuspended: false, qadaTracked: false);

    if (state == HormonalPhase.menstrual) {
      fiqh = FiqhState(
        prayerSuspended: true,
        fastingSuspended: true,
        qadaTracked: true,
      );
    }

    // Predict next cycle start date
    DateTime nextCycleStartDate;
    if (logs.isNotEmpty) {
      final lastLog = logs.first;
      final lastStart = DateTime.tryParse(lastLog['cycleStartDate']! as String) ?? now;
      final daysSinceLastStart = now.difference(lastStart).inDays;
      final cyclesElapsed = (daysSinceLastStart / cycleLength).floor() + 1;
      nextCycleStartDate = lastStart.add(Duration(days: cyclesElapsed * cycleLength));
    } else {
      nextCycleStartDate = now.add(const Duration(days: 14));
    }

    // Generate Private Reminders queue
    final reminders = <PrivateReminder>[
      PrivateReminder(
        level: 'T-7',
        message: '۷ روز تا شروع دوره بعدی باقی مانده است. شرایط بدنی متعادل است.',
        date: nextCycleStartDate.subtract(const Duration(days: 7)),
      ),
      PrivateReminder(
        level: 'T-3',
        message: '۳ روز تا شروع احتمالی دوره بعدی. آماده‌سازی‌های اولیه را در نظر بگیرید.',
        date: nextCycleStartDate.subtract(const Duration(days: 3)),
      ),
      PrivateReminder(
        level: 'T-1',
        message: '۱ روز تا شروع دوره بعدی. لطفاً برنامه فردا را منعطف‌تر بچینید.',
        date: nextCycleStartDate.subtract(const Duration(days: 1)),
      ),
      PrivateReminder(
        level: 'T0',
        message: 'امروز زمان احتمالی شروع دوره است. آیا دوره شما آغاز شده؟',
        date: nextCycleStartDate,
      ),
    ];

    return HormonalEngineOutput(
      state: state,
      dayOfCycle: dayOfCycle,
      dayOfMenstruation: dayOfMenstruation,
      privateReminderQueue: reminders,
      fiqhState: fiqh,
      nextCycleStartDate: nextCycleStartDate,
      hasData: true,
    );
  }
}

class CycleEngineInput {
  CycleEngineInput({required this.db, required this.appSettings, required this.now});
  final Database db;
  final Map<String, String> appSettings;
  final DateTime now;
}

class CycleEngine implements CachedEngine<CycleEngineInput, HormonalEngineOutput> {
  @override
  Future<HormonalEngineOutput> calculate(CycleEngineInput input) async {
    return HormonalIntelligenceEngine.evaluate(
      db: input.db,
      appSettings: input.appSettings,
      now: input.now,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(CycleEngineInput input) => true;

  @override
  List<Type> dependencies() => [];
}
