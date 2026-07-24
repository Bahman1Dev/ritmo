import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
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

/// Compatibility adapter over [CycleEngine] (Canonical Source of Truth).
/// Deprecated: Direct callers should consume [CycleEngine] or [CycleConsentBridge].
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

    final engineOutput = await CycleEngine().calculate(
      CycleEngineInput(db: db, appSettings: appSettings, now: now),
    );

    if (!engineOutput.hasData) {
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

    final state = switch (engineOutput.currentPhase) {
      CyclePhase.menstrual => HormonalPhase.menstrual,
      CyclePhase.follicular => HormonalPhase.postCycle,
      CyclePhase.ovulation => HormonalPhase.normal,
      CyclePhase.luteal => HormonalPhase.preCycle,
      CyclePhase.noData => HormonalPhase.noData,
    };

    final isMenstrual = engineOutput.currentPhase == CyclePhase.menstrual;

    return HormonalEngineOutput(
      state: state,
      dayOfCycle: engineOutput.dayOfCycle,
      dayOfMenstruation: engineOutput.dayOfPeriod,
      privateReminderQueue: [],
      fiqhState: FiqhState(
        prayerSuspended: isMenstrual,
        fastingSuspended: isMenstrual,
        qadaTracked: isMenstrual,
      ),
      nextCycleStartDate: engineOutput.nextPeriodPrediction,
      hasData: true,
    );
  }
}
