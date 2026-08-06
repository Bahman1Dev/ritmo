import 'dart:math' as math;
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/util/safe_map.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';

class SleepEngineInput {
  SleepEngineInput({
    required this.sleepLogs,
    required this.target,
    required this.energyLogs,
    required this.moodLogs,
    required this.today,
    this.horizonDays = 14,
  });
  final List<SleepLog> sleepLogs;
  final SleepTarget target;
  final List<Map<String, dynamic>> energyLogs;
  final List<Map<String, dynamic>> moodLogs;
  final DateTime today;
  final int horizonDays;
}

class SleepEngineOutput {
  SleepEngineOutput({
    this.lastNight,
    required this.avgDurationMinutes,
    required this.avgQuality,
    required this.sleepDebtMinutes,
    required this.sleepBalanceHours,
    this.consistencyScore,
    required this.durationTrend,
    required this.qualityTrend,
    this.bestBedtimeWindow,
    this.sleepEnergyCorrelation,
    this.sleepMoodCorrelation,
    required this.correlationInsight,
  });
  final SleepLog? lastNight;
  final double avgDurationMinutes;
  final double avgQuality;
  final int sleepDebtMinutes;
  final double sleepBalanceHours; // T-3.2 / P-7
  final double? consistencyScore; // T-1.4: 0..100 or null
  final List<double> durationTrend;
  final List<double> qualityTrend;
  final String? bestBedtimeWindow; // T-1.7: String? or null
  final double? sleepEnergyCorrelation; // -1..1
  final double? sleepMoodCorrelation;   // -1..1
  final String correlationInsight;
}

class SleepEngine implements CachedEngine<SleepEngineInput, SleepEngineOutput> {
  static const int minLogsForConsistency = 2;
  static const int minPointsForCorrelation = 3;
  static const int minSamplesPerBedtimeWindow = 4;
  static const double halfLifeDays = 7.0;

  @override
  Future<SleepEngineOutput> calculate(SleepEngineInput input) async {
    final cleanToday = RitmoDate.startOfDay(input.today);
    final todayStr = RitmoDate.dayKey(cleanToday);
    final yesterdayStr = RitmoDate.dayKey(cleanToday.subtract(const Duration(days: 1)));

    // 1. lastNight
    final lastNightLog = input.sleepLogs.where((log) => log.date == yesterdayStr).firstOrNull;

    // Filter logs in horizonDays
    final horizonStart = cleanToday.subtract(Duration(days: input.horizonDays));
    final horizonStartStr = RitmoDate.dayKey(horizonStart);
    final activeLogs = input.sleepLogs
        .where((log) => log.date.compareTo(horizonStartStr) >= 0 && log.date.compareTo(todayStr) < 0)
        .toList();

    // Sort active logs by date ascending for trends
    activeLogs.sort((a, b) => a.date.compareTo(b.date));

    // 2. avgDurationMinutes & avgQuality
    double totalDuration = 0;
    double totalQuality = 0;
    for (final log in activeLogs) {
      totalDuration += log.durationMinutes;
      totalQuality += log.quality.score;
    }
    final avgDuration = activeLogs.isNotEmpty ? totalDuration / activeLogs.length : 0.0;
    final avgQual = activeLogs.isNotEmpty ? totalQuality / activeLogs.length : 0.0;

    // 3. sleepDebtMinutes & sleepBalanceHours (T-3.2)
    var debt = 0;
    for (final log in activeLogs) {
      if (log.durationMinutes < input.target.durationMinutes) {
        debt += input.target.durationMinutes - log.durationMinutes;
      }
    }
    final balance = calculateSleepBalanceHours(
      logs: activeLogs,
      targetHours: input.target.durationMinutes / 60.0,
      now: input.today,
    );

    // 4. consistencyScore (T-1.4)
    final consistency = _calculateConsistency(activeLogs, input.target);

    // 5. Trends
    final durationTrendList = activeLogs.map((log) => log.durationMinutes.toDouble()).toList();
    final qualityTrendList = activeLogs.map((log) => log.quality.score.toDouble()).toList();

    // 6. Correlation Sleep vs Next Day Energy/Mood (T-1.5, T-1.6, T-1.7)
    final correlationData = _calculateCorrelation(activeLogs, input.energyLogs, input.moodLogs);

    return SleepEngineOutput(
      lastNight: lastNightLog,
      avgDurationMinutes: avgDuration,
      avgQuality: avgQual,
      sleepDebtMinutes: debt,
      sleepBalanceHours: balance,
      consistencyScore: consistency,
      durationTrend: durationTrendList,
      qualityTrend: qualityTrendList,
      bestBedtimeWindow: correlationData.bestWindow,
      sleepEnergyCorrelation: correlationData.energyCorr,
      sleepMoodCorrelation: correlationData.moodCorr,
      correlationInsight: correlationData.insight,
    );
  }

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(SleepEngineInput input) {
    final dayStamp = input.today.toIso8601String().substring(0, 10);
    return '$dayStamp|${input.horizonDays}|${input.sleepLogs.length}|${input.target.durationMinutes}';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(SleepEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  /// T-3.2 / P-7: Exponential decay sleep balance calculation.
  static double calculateSleepBalanceHours({
    required List<SleepLog> logs,
    required double targetHours,
    required DateTime now,
  }) {
    double balance = 0;
    for (final log in logs) {
      final logDate = RitmoDate.tryParseDayKey(log.date);
      if (logDate == null) continue;
      final ageDays = RitmoDate.startOfDay(now)
          .difference(RitmoDate.startOfDay(logDate))
          .inDays
          .toDouble();
      if (ageDays < 0) continue;
      final decay = math.pow(0.5, ageDays / halfLifeDays).toDouble();
      final delta = log.durationHours - targetHours; // negative = deficit, positive = surplus
      balance += delta * decay;
    }
    return balance;
  }

  /// T-1.4: Consistency score requires at least 5 logs.
  double? _calculateConsistency(List<SleepLog> logs, SleepTarget target) {
    if (logs.length < minLogsForConsistency) return null;

    final bedtimeDevs = <double>[];
    final wakeDevs = <double>[];

    final targetBedtimeMin = target.bedtimeHour * 60 + target.bedtimeMinute;
    final targetWakeMin = target.wakeHour * 60 + target.wakeMinute;

    for (final log in logs) {
      if (log.bedtimeAt != null && log.wakeAt != null) {
        final bt = DateTime.fromMillisecondsSinceEpoch(log.bedtimeAt!);
        final wt = DateTime.fromMillisecondsSinceEpoch(log.wakeAt!);

        final actualBtMin = bt.hour * 60 + bt.minute;
        final actualWtMin = wt.hour * 60 + wt.minute;

        var btDiff = actualBtMin - targetBedtimeMin;
        if (btDiff > 720) btDiff -= 1440;
        if (btDiff < -720) btDiff += 1440;
        bedtimeDevs.add(btDiff.toDouble());

        var wtDiff = actualWtMin - targetWakeMin;
        if (wtDiff > 720) wtDiff -= 1440;
        if (wtDiff < -720) wtDiff += 1440;
        wakeDevs.add(wtDiff.toDouble());
      }
    }

    if (bedtimeDevs.isEmpty || wakeDevs.isEmpty) return null;

    final sdBedtime = _calculateStdDev(bedtimeDevs);
    final sdWake = _calculateStdDev(wakeDevs);

    final totalSD = (sdBedtime + sdWake) / 2;
    final score = 100.0 - (totalSD * 0.5);
    return score.clamp(0.0, 100.0);
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  _CorrelationResult _calculateCorrelation(
    List<SleepLog> logs,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> moodLogs,
  ) {
    final energyByDate = <String, List<double>>{};
    for (final el in energyLogs) {
      final loggedAt = el.readInt('loggedAt');
      if (loggedAt != null) {
        final date = RitmoDate.dayKeyFromMillis(loggedAt);
        final level = el.readString('energyLevel') ?? 'MEDIUM';
        var val = 2.0;
        if (level == 'HIGH') val = 3.0;
        if (level == 'LOW') val = 1.0;
        energyByDate.putIfAbsent(date, () => []).add(val);
      }
    }

    final moodByDate = <String, List<double>>{};
    for (final ml in moodLogs) {
      final loggedAt = ml.readInt('loggedAt');
      if (loggedAt != null) {
        final date = RitmoDate.dayKeyFromMillis(loggedAt);
        final valence = ml.readDouble('valence') ?? 3.0;
        moodByDate.putIfAbsent(date, () => []).add(valence);
      }
    }

    // T-1.6: Paired entries without baseline placeholders
    final pairedQuality = <double>[];
    final pairedEnergy = <double>[];

    final pairedQualityMood = <double>[];
    final pairedMood = <double>[];

    final dayRatingsByBedtimeWindow = <String, List<double>>{};

    for (final log in logs) {
      final logDate = RitmoDate.tryParseDayKey(log.date);
      if (logDate == null) continue;
      final nextDay = RitmoDate.startOfDay(logDate).add(const Duration(days: 1));
      final nextDayStr = RitmoDate.dayKey(nextDay);

      final nextDayEnergyList = energyByDate[nextDayStr];
      final nextDayMoodList = moodByDate[nextDayStr];

      double? avgEnergy;
      if (nextDayEnergyList != null && nextDayEnergyList.isNotEmpty) {
        avgEnergy = nextDayEnergyList.reduce((a, b) => a + b) / nextDayEnergyList.length;
        pairedQuality.add(log.quality.score.toDouble());
        pairedEnergy.add(avgEnergy);
      }

      double? avgMood;
      if (nextDayMoodList != null && nextDayMoodList.isNotEmpty) {
        avgMood = nextDayMoodList.reduce((a, b) => a + b) / nextDayMoodList.length;
        pairedQualityMood.add(log.quality.score.toDouble());
        pairedMood.add(avgMood);
      }

      // Group for best bedtime window
      if (log.bedtimeAt != null && (avgEnergy != null || avgMood != null)) {
        final bt = DateTime.fromMillisecondsSinceEpoch(log.bedtimeAt!);
        final minOfDay = bt.hour * 60 + bt.minute;

        final slotStartMin = (minOfDay ~/ 30) * 30;
        final h = slotStartMin ~/ 60;
        final m = slotStartMin % 60;
        final nextH = (slotStartMin + 30) ~/ 60;
        final nextM = (slotStartMin + 30) % 60;

        final windowKey = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} - '
            '${(nextH % 24).toString().padLeft(2, '0')}:${nextM.toString().padLeft(2, '0')}';

        final dayRating = (avgEnergy ?? 2.0) + (avgMood ?? 3.0);
        dayRatingsByBedtimeWindow.putIfAbsent(windowKey, () => []).add(dayRating);
      }
    }

    double? energyCorr;
    double? moodCorr;

    // T-1.5: Requires at least 30 data points
    if (pairedQuality.length >= minPointsForCorrelation && pairedEnergy.length >= minPointsForCorrelation) {
      energyCorr = _calculatePearson(pairedQuality, pairedEnergy);
    }
    if (pairedQualityMood.length >= minPointsForCorrelation && pairedMood.length >= minPointsForCorrelation) {
      moodCorr = _calculatePearson(pairedQualityMood, pairedMood);
    }

    // T-1.7: Best bedtime window requires min 4 samples, no magic sentinel numbers
    String? bestWindow;
    double? bestRating;
    for (final entry in dayRatingsByBedtimeWindow.entries) {
      if (entry.value.length < minSamplesPerBedtimeWindow) continue;
      final avgRating = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (bestRating == null || avgRating > bestRating) {
        bestRating = avgRating;
        bestWindow = entry.key;
      }
    }

    // T-1.5: Non-deterministic hypothetical phrasing with n
    var insight = 'در حال یادگیری الگوی خواب شما 🌙';
    final n = math.max(pairedQuality.length, pairedQualityMood.length);
    if (energyCorr != null && moodCorr != null) {
      if (energyCorr > 0.3 && moodCorr > 0.3) {
        insight = 'به نظر می‌رسد شب‌هایی که بهتر خوابیده‌ای، روز بعدش انرژی و روحیه بیشتری ثبت کرده‌ای. (بر پایهٔ ${RitmoNumber.faInt(n)} شب)';
      } else if (energyCorr < -0.3) {
        insight = 'این الگو دیده شده که در روزهای پرفشار خواب بیشتری داشته‌ای. (بر پایهٔ ${RitmoNumber.faInt(n)} شب)';
      } else {
        insight = 'روند خوابت منظم است و همراه بوده با نوسانات طبیعی روزانه. (بر پایهٔ ${RitmoNumber.faInt(n)} شب)';
      }
    }

    return _CorrelationResult(
      energyCorr: energyCorr,
      moodCorr: moodCorr,
      bestWindow: bestWindow,
      insight: insight,
    );
  }

  double? _calculatePearson(List<double> x, List<double> y) {
    if (x.length != y.length) {
      throw ArgumentError('Pearson requires equal-length series');
    }
    if (x.length < 2) return null;

    final n = x.length;
    double sumX = 0;
    double sumY = 0;
    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
    }
    final meanX = sumX / n;
    final meanY = sumY / n;

    double num = 0;
    double denX = 0;
    double denY = 0;

    for (var i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      num += dx * dy;
      denX += dx * dx;
      denY += dy * dy;
    }

    if (denX == 0 || denY == 0) return null;
    return num / math.sqrt(denX * denY);
  }
}

class _CorrelationResult {
  _CorrelationResult({
    this.energyCorr,
    this.moodCorr,
    this.bestWindow,
    required this.insight,
  });
  final double? energyCorr;
  final double? moodCorr;
  final String? bestWindow;
  final String insight;
}
