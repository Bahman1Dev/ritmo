import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

enum MotivationWeakestTerm {
  expectation,
  value,
  delay,
  impulsivity,
  none,
}

@immutable
class MotivationDiagnosisInput {
  const MotivationDiagnosisInput({
    required this.routineId,
    required this.routineCompletions,
    this.deferCount = 0,
    this.snoozeCount = 0,
    this.parentGoalTitle,
    this.parentGoalTargetDate,
    this.identityStatement,
    this.isUserActivatedCategory = true,
    this.actualVsScheduledDeltaMinutes = 0,
    this.now,
  });

  final String routineId;
  final List<Map<String, dynamic>> routineCompletions;
  final int deferCount;
  final int snoozeCount;
  final String? parentGoalTitle;
  final DateTime? parentGoalTargetDate;
  final String? identityStatement;
  final bool isUserActivatedCategory;
  final int actualVsScheduledDeltaMinutes;
  final DateTime? now;

  @override
  String toString() {
    return 'MotivationDiagnosisInput(routineId: $routineId, completionsCount: ${routineCompletions.length}, deferCount: $deferCount, snoozeCount: $snoozeCount, parentGoal: $parentGoalTitle, targetDate: $parentGoalTargetDate, identity: $identityStatement, isUserCat: $isUserActivatedCategory, delta: $actualVsScheduledDeltaMinutes, now: $now)';
  }
}

@immutable
class MotivationDiagnosisOutput {
  const MotivationDiagnosisOutput({
    required this.routineId,
    required this.sufficientData,
    required this.sampleCount,
    required this.expectationTerm,
    required this.valueTerm,
    required this.delayTerm,
    required this.impulsivityTerm,
    required this.weakestTerm,
    required this.prescriptionKey,
    required this.humanReadableExplanation,
  });

  final String routineId;
  final bool sufficientData;
  final int sampleCount;
  final double expectationTerm;
  final double valueTerm;
  final double delayTerm;
  final double impulsivityTerm;
  final MotivationWeakestTerm weakestTerm;
  final String prescriptionKey;
  final String humanReadableExplanation;

  factory MotivationDiagnosisOutput.insufficient(String routineId, int count) {
    return MotivationDiagnosisOutput(
      routineId: routineId,
      sufficientData: false,
      sampleCount: count,
      expectationTerm: 1.0,
      valueTerm: 1.0,
      delayTerm: 0.0,
      impulsivityTerm: 0.0,
      weakestTerm: MotivationWeakestTerm.none,
      prescriptionKey: 'none',
      humanReadableExplanation: '',
    );
  }
}

/// Motivation Diagnosis Engine (Temporal Motivation Theory — Steel & König)
/// Motivation ≈ (Expectation × Value) / (1 + Impulsivity × Delay)
class MotivationDiagnosisEngine
    implements CachedEngine<MotivationDiagnosisInput, MotivationDiagnosisOutput> {
  static const int minSamplesRequired = 10;
  static const int observationWindowDays = 28;

  @override
  bool canRun(MotivationDiagnosisInput input) => input.routineId.isNotEmpty;

  @override
  List<Type> dependencies() => [];

  @override
  Duration get ttl => const Duration(minutes: 15);

  @override
  void invalidate() {}

  @override
  String fingerprint(MotivationDiagnosisInput input) => input.toString();

  @override
  Future<MotivationDiagnosisOutput> calculate(MotivationDiagnosisInput input) async {
    final now = input.now ?? DateTime.now();
    final windowStart = now.subtract(const Duration(days: observationWindowDays));

    // Filter completions in 28-day window
    final recentCompletions = input.routineCompletions.where((comp) {
      final timeMs = comp['completionTime'] as int?;
      if (timeMs != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timeMs);
        return date.isAfter(windowStart);
      }
      final dateStr = comp['completionDate'] as String?;
      if (dateStr != null) {
        final parsed = DateTime.tryParse(dateStr);
        return parsed != null && parsed.isAfter(windowStart);
      }
      return false;
    }).toList();

    final sampleCount = recentCompletions.length;
    if (sampleCount < minSamplesRequired) {
      return MotivationDiagnosisOutput.insufficient(input.routineId, sampleCount);
    }

    // 1. Calculate Expectation Term (Success rate in last 28 days)
    int successfulCount = 0;
    for (final comp in recentCompletions) {
      final result = (comp['resultType'] as String? ?? '').toUpperCase();
      if (result == 'COMPLETED' || result == 'DONE' || result == 'PARTIAL') {
        successfulCount++;
      }
    }
    final expectationTerm = (successfulCount / sampleCount).clamp(0.0, 1.0);

    // 2. Calculate Value Term (Connection to parent goal / identity statement)
    double valueTerm = 1.0;
    if (input.parentGoalTitle != null && input.parentGoalTitle!.isNotEmpty) {
      valueTerm += 0.4;
    }
    if (input.identityStatement != null && input.identityStatement!.isNotEmpty) {
      valueTerm += 0.4;
    }
    if (!input.isUserActivatedCategory) {
      valueTerm -= 0.5;
    }
    valueTerm = valueTerm.clamp(0.1, 1.0);

    // 3. Calculate Delay Term (Distance to goal target date)
    double delayTerm = 0.2;
    if (input.parentGoalTargetDate != null) {
      final daysToTarget = input.parentGoalTargetDate!.difference(now).inDays;
      if (daysToTarget > 30) {
        delayTerm = 0.9;
      } else if (daysToTarget > 14) {
        delayTerm = 0.6;
      } else if (daysToTarget > 7) {
        delayTerm = 0.4;
      } else {
        delayTerm = 0.1;
      }
    }

    // 4. Calculate Impulsivity Term (Defer count, snooze rate, execution time delta)
    double impulsivityTerm = (input.deferCount * 0.15) +
        (input.snoozeCount * 0.10) +
        ((input.actualVsScheduledDeltaMinutes / 60.0) * 0.10);
    impulsivityTerm = impulsivityTerm.clamp(0.0, 1.0);

    // Identify weakest term
    // Normalization score for weakness:
    // Low Expectation => High Weakness
    // Low Value => High Weakness
    // High Delay => High Weakness
    // High Impulsivity => High Weakness
    final expectationWeakness = 1.0 - expectationTerm; // >0.2 is weak
    final valueWeakness = 1.0 - valueTerm;             // >0.3 is weak
    final delayWeakness = delayTerm;                   // >0.5 is weak
    final impulsivityWeakness = impulsivityTerm;       // >0.4 is weak

    MotivationWeakestTerm weakest = MotivationWeakestTerm.none;
    double maxWeakness = 0.25; // threshold required to declare weakness

    // Check expectation first (Tie-breaker rule §4: Expectation takes priority)
    if (expectationWeakness >= maxWeakness) {
      weakest = MotivationWeakestTerm.expectation;
      maxWeakness = expectationWeakness;
    }
    if (valueWeakness > maxWeakness) {
      weakest = MotivationWeakestTerm.value;
      maxWeakness = valueWeakness;
    }
    if (delayWeakness > maxWeakness) {
      weakest = MotivationWeakestTerm.delay;
      maxWeakness = delayWeakness;
    }
    if (impulsivityWeakness > maxWeakness) {
      weakest = MotivationWeakestTerm.impulsivity;
      maxWeakness = impulsivityWeakness;
    }

    String prescriptionKey = 'none';
    String explanation = '';

    switch (weakest) {
      case MotivationWeakestTerm.expectation:
        prescriptionKey = 'shrink_to_success';
        explanation = 'نرخ موفقیت‌های اخیر کمتر از حد انتظار است. پیشنهادی برای کوچک‌سازی گام جهت ثبت موفقیت و افزایش انگیزه ارائه می‌شود.';
        break;
      case MotivationWeakestTerm.value:
        prescriptionKey = 'remind_why';
        explanation = 'ارتباط این اقدام با اهداف کلیدی مبهم است. یادآوری دلیل و ارزش اصلی پیشنهاد می‌شود.';
        break;
      case MotivationWeakestTerm.delay:
        prescriptionKey = 'near_milestone';
        explanation = 'نتیجهٔ هدف در فاصلهٔ دور قرار دارد. تعریف یک نقطهٔ عطف کوتاه‌مدت کمتر از ۷ روز جهت بازخورد نزدیک پیشنهاد می‌شود.';
        break;
      case MotivationWeakestTerm.impulsivity:
        prescriptionKey = 'change_cue';
        explanation = 'تعویق‌های متوالی مشاهده شد. تغییر نشانه، زنجیره‌سازی یا انتقال به زمان اوج انرژی پیشنهاد می‌شود.';
        break;
      case MotivationWeakestTerm.none:
        prescriptionKey = 'maintain';
        explanation = 'عملکرد و انگیزه در سطح پایدار و مطلوب قرار دارد.';
        break;
    }

    return MotivationDiagnosisOutput(
      routineId: input.routineId,
      sufficientData: true,
      sampleCount: sampleCount,
      expectationTerm: expectationTerm,
      valueTerm: valueTerm,
      delayTerm: delayTerm,
      impulsivityTerm: impulsivityTerm,
      weakestTerm: weakest,
      prescriptionKey: prescriptionKey,
      humanReadableExplanation: explanation,
    );
  }
}
