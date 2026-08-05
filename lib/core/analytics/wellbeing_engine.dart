import 'dart:math' as math;

enum WellbeingSignal { sleep, energy, mood, reflection }

/// سهم یک سیگنال در شاخص نهایی — ورودی شیت چرا؟
class WellbeingContribution {
  const WellbeingContribution({
    required this.signal,
    required this.score,
    required this.weight,
    required this.confidence,
    required this.sampleCount,
    required this.windowDays,
    required this.isAiDerived,
  });

  final WellbeingSignal signal;
  final double score;      // 0..100
  final double weight;     // وزن ثابت سیگنال
  final double confidence; // 0..1
  final int sampleCount;   // n واقعی
  final int windowDays;    // پنجرهٔ زمانی
  final bool isAiDerived;  // قانون ۳۲

  double get effectiveWeight => weight * confidence;
}

/// سیگنالی که داده‌اش کافی نبود — ورودی حالت خالی صادقانه.
class WellbeingMissingSignal {
  const WellbeingMissingSignal({
    required this.signal,
    required this.have,
    required this.need,
  });
  final WellbeingSignal signal;
  final int have;
  final int need;
}

class WellbeingIndex {
  const WellbeingIndex({
    required this.value,
    required this.confidence,
    required this.contributions,
    required this.missing,
    required this.computedAtMillis,
  });

  /// null یعنی داده کافی نیست. هرگز این را با 0 جایگزین نکن.
  final double? value;
  final double confidence; // 0..1
  final List<WellbeingContribution> contributions;
  final List<WellbeingMissingSignal> missing;
  final int computedAtMillis;

  bool get hasValue => value != null;

  /// پهنای عدم قطعیت برای نوار اطمینان (پ‌۳).
  double get uncertainty => (1.0 - confidence) * 25.0;
  double? get lowerBound =>
      value == null ? null : (value! - uncertainty).clamp(0.0, 100.0);
  double? get upperBound =>
      value == null ? null : (value! + uncertainty).clamp(0.0, 100.0);

  /// آبشار سهم‌ها نسبت به پایهٔ ۵۰.
  /// تضمین ریاضی: 50 + مجموع مقادیر این نقشه == value
  Map<WellbeingSignal, double> get waterfall {
    final totalW =
        contributions.fold<double>(0, (a, c) => a + c.effectiveWeight);
    if (totalW <= 0) return const {};
    return {
      for (final c in contributions)
        c.signal: (c.effectiveWeight * (c.score - 50.0)) / totalW,
    };
  }
}

class WellbeingEngineInput {
  const WellbeingEngineInput({
    required this.now,
    this.horizonDays = 14,
    this.sleepNights = 0,
    this.avgSleepHours,
    this.targetSleepHours = 7.5,
    this.avgSleepQuality,
    this.sleepConsistency,
    this.energySamples = 0,
    this.avgEnergyLevel,
    this.energyIsAiDerived = false,
    this.moodSamples = 0,
    this.avgMoodScore,
    this.reflectionEntries = 0,
    this.avgReflectionMood,
  });

  final DateTime now;        // قانون ۱۰: زمان تزریق می‌شود
  final int horizonDays;

  final int sleepNights;
  final double? avgSleepHours;
  final double targetSleepHours;
  final double? avgSleepQuality;   // 0..100
  final double? sleepConsistency;  // 0..100 — null یعنی نامعلوم

  final int energySamples;
  final double? avgEnergyLevel;    // 1..3
  final bool energyIsAiDerived;

  final int moodSamples;
  final double? avgMoodScore;      // 1..5

  final int reflectionEntries;
  final double? avgReflectionMood; // 1..5
}

class WellbeingEngine {
  const WellbeingEngine();

  // وزن‌ها — مجموع دقیقاً ۱٫۰
  static const double wSleep = 0.35;
  static const double wEnergy = 0.30;
  static const double wMood = 0.20;
  static const double wReflection = 0.15;

  // حداقل نمونه برای اینکه سیگنال اصلاً وارد محاسبه شود
  static const int minSleepNights = 3;
  static const int minEnergySamples = 3;
  static const int minMoodSamples = 3;
  static const int minReflectionEntries = 3;

  // تعداد نمونه‌ای که اطمینان را به ۱٫۰ می‌رساند
  static const int fullSleepNights = 7;
  static const int fullEnergySamples = 14;
  static const int fullMoodSamples = 14;
  static const int fullReflectionEntries = 7;

  /// اگر مجموع وزن مؤثر از این کمتر باشد، شاخص null است.
  static const double minTotalEffectiveWeight = 0.5;

  static const double sigmaUnder = 2.0; // کم‌خوابی
  static const double sigmaOver = 2.5;  // پرخوابی

  /// 0 زیر حداقل، 0.5 روی حداقل، تا 1.0 روی حد کامل.
  static double confidenceFor(int have, int min, int full) {
    if (have < min) return 0.0;
    if (have >= full) return 1.0;
    return 0.5 + ((have - min) / (full - min)) * 0.5;
  }

  /// منحنی گاوسی حول هدف: هم کم‌خوابی هم پرخوابی افت می‌کند.
  static double sleepDurationScore(double hours, double target) {
    final delta = hours - target;
    final sigma = delta < 0 ? sigmaUnder : sigmaOver;
    final z = delta / sigma;
    return (100.0 * math.exp(-(z * z))).clamp(0.0, 100.0);
  }

  /// ترکیب سه بعد خواب با نرمال‌سازی خودکار وزن‌های موجود.
  static double sleepScore({
    required double hours,
    required double target,
    double? quality,
    double? consistency,
  }) {
    final terms = <List<double>>[
      [0.5, sleepDurationScore(hours, target)],
      if (quality != null) [0.3, quality.clamp(0.0, 100.0)],
      if (consistency != null) [0.2, consistency.clamp(0.0, 100.0)],
    ];
    final w = terms.fold<double>(0, (a, t) => a + t[0]);
    final s = terms.fold<double>(0, (a, t) => a + t[0] * t[1]);
    return (s / w).clamp(0.0, 100.0);
  }

  static double _map1to3(double v) => (((v - 1.0) / 2.0) * 100).clamp(0.0, 100.0);
  static double _map1to5(double v) => (((v - 1.0) / 4.0) * 100).clamp(0.0, 100.0);

  WellbeingIndex compute(WellbeingEngineInput i) {
    final contributions = <WellbeingContribution>[];
    final missing = <WellbeingMissingSignal>[];

    void addOrMiss({
      required WellbeingSignal signal,
      required int have,
      required int min,
      required int full,
      required double weight,
      required double? score,
      bool isAi = false,
    }) {
      final c = confidenceFor(have, min, full);
      if (c > 0 && score != null) {
        contributions.add(WellbeingContribution(
          signal: signal,
          score: score,
          weight: weight,
          confidence: c,
          sampleCount: have,
          windowDays: i.horizonDays,
          isAiDerived: isAi,
        ));
      } else {
        missing.add(
            WellbeingMissingSignal(signal: signal, have: have, need: min));
      }
    }

    addOrMiss(
      signal: WellbeingSignal.sleep,
      have: i.sleepNights,
      min: minSleepNights,
      full: fullSleepNights,
      weight: wSleep,
      score: i.avgSleepHours == null
          ? null
          : sleepScore(
              hours: i.avgSleepHours!,
              target: i.targetSleepHours,
              quality: i.avgSleepQuality,
              consistency: i.sleepConsistency,
            ),
    );

    addOrMiss(
      signal: WellbeingSignal.energy,
      have: i.energySamples,
      min: minEnergySamples,
      full: fullEnergySamples,
      weight: wEnergy,
      score: i.avgEnergyLevel == null ? null : _map1to3(i.avgEnergyLevel!),
      isAi: i.energyIsAiDerived,
    );

    addOrMiss(
      signal: WellbeingSignal.mood,
      have: i.moodSamples,
      min: minMoodSamples,
      full: fullMoodSamples,
      weight: wMood,
      score: i.avgMoodScore == null ? null : _map1to5(i.avgMoodScore!),
    );

    addOrMiss(
      signal: WellbeingSignal.reflection,
      have: i.reflectionEntries,
      min: minReflectionEntries,
      full: fullReflectionEntries,
      weight: wReflection,
      score:
          i.avgReflectionMood == null ? null : _map1to5(i.avgReflectionMood!),
    );

    final totalEff =
        contributions.fold<double>(0, (a, c) => a + c.effectiveWeight);
    const totalW = wSleep + wEnergy + wMood + wReflection;
    final confidence = (totalEff / totalW).clamp(0.0, 1.0);

    double? value;
    if (totalEff >= minTotalEffectiveWeight) {
      final sum = contributions.fold<double>(
          0, (a, c) => a + c.effectiveWeight * c.score);
      value = (sum / totalEff).clamp(0.0, 100.0);
    }

    return WellbeingIndex(
      value: value,
      confidence: confidence,
      contributions: contributions,
      missing: missing,
      computedAtMillis: i.now.millisecondsSinceEpoch,
    );
  }
}
