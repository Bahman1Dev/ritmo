import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
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
    required this.consistencyScore,
    required this.durationTrend,
    required this.qualityTrend,
    required this.bestBedtimeWindow,
    this.sleepEnergyCorrelation,
    this.sleepMoodCorrelation,
    required this.correlationInsight,
  });
  final SleepLog? lastNight;
  final double avgDurationMinutes;
  final double avgQuality;
  final int sleepDebtMinutes;
  final int consistencyScore; // 0..100
  final List<double> durationTrend;
  final List<double> qualityTrend;
  final String bestBedtimeWindow;
  final double? sleepEnergyCorrelation; // -1..1
  final double? sleepMoodCorrelation;   // -1..1
  final String correlationInsight;
}

class SleepEngine implements CachedEngine<SleepEngineInput, SleepEngineOutput> {
  @override
  Future<SleepEngineOutput> calculate(SleepEngineInput input) async {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);
    final yesterdayStr = _formatDateIso(cleanToday.subtract(const Duration(days: 1)));

    // 1. lastNight
    final lastNightLog = input.sleepLogs.where((log) => log.date == yesterdayStr).firstOrNull;

    // Filter logs in horizonDays
    final horizonStart = cleanToday.subtract(Duration(days: input.horizonDays));
    final horizonStartStr = _formatDateIso(horizonStart);
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

    // 3. sleepDebtMinutes
    var debt = 0;
    for (final log in activeLogs) {
      if (log.durationMinutes < input.target.durationMinutes) {
        debt += input.target.durationMinutes - log.durationMinutes;
      }
    }

    // 4. consistencyScore
    final consistency = _calculateConsistency(activeLogs, input.target);

    // 5. Trends
    final durationTrendList = activeLogs.map((log) => log.durationMinutes.toDouble()).toList();
    final qualityTrendList = activeLogs.map((log) => log.quality.score.toDouble()).toList();

    // 6. Correlation Sleep vs Next Day Energy/Mood
    final correlationData = _calculateCorrelation(activeLogs, input.energyLogs, input.moodLogs);

    return SleepEngineOutput(
      lastNight: lastNightLog,
      avgDurationMinutes: avgDuration,
      avgQuality: avgQual,
      sleepDebtMinutes: debt,
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
  void invalidate() {}

  @override
  bool canRun(SleepEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _calculateConsistency(List<SleepLog> logs, SleepTarget target) {
    if (logs.length < 2) return 100;

    // Standard deviation of bedtime and wake time deviations
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

        // Bedtime diff
        var btDiff = actualBtMin - targetBedtimeMin;
        if (btDiff > 720) btDiff -= 1440;
        if (btDiff < -720) btDiff += 1440;
        bedtimeDevs.add(btDiff.toDouble());

        // Wake diff
        var wtDiff = actualWtMin - targetWakeMin;
        if (wtDiff > 720) wtDiff -= 1440;
        if (wtDiff < -720) wtDiff += 1440;
        wakeDevs.add(wtDiff.toDouble());
      }
    }

    if (bedtimeDevs.isEmpty || wakeDevs.isEmpty) return 100;

    final sdBedtime = _calculateStdDev(bedtimeDevs);
    final sdWake = _calculateStdDev(wakeDevs);

    // Consistency score starts at 100, drops by 0.5 points for every minute of combined SD
    final totalSD = (sdBedtime + sdWake) / 2;
    final score = 100 - (totalSD * 0.5).round();
    return score.clamp(0, 100);
  }

  double _calculateStdDev(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  _CorrelationResult _calculateCorrelation(
    List<SleepLog> logs,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> moodLogs,
  ) {
    final energyByDate = <String, List<double>>{};
    for (final el in energyLogs) {
      final loggedAt = el['loggedAt'] as int?;
      if (loggedAt != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(loggedAt).toIso8601String().substring(0, 10);
        final level = el['energyLevel'] as String? ?? 'MEDIUM';
        var val = 2.0;
        if (level == 'HIGH') val = 3.0;
        if (level == 'LOW') val = 1.0;
        energyByDate.putIfAbsent(date, () => []).add(val);
      }
    }

    final moodByDate = <String, List<double>>{};
    for (final ml in moodLogs) {
      final loggedAt = ml['loggedAt'] as int?;
      if (loggedAt != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(loggedAt).toIso8601String().substring(0, 10);
        final valence = (ml['valence'] as num?)?.toDouble() ?? 3.0;
        moodByDate.putIfAbsent(date, () => []).add(valence);
      }
    }

    final sleepQualities = <double>[];
    final nextDayEnergies = <double>[];
    final nextDayMoods = <double>[];

    // Group actual bedtimes by 30-min windows for best bedtime calculation
    final dayRatingsByBedtimeWindow = <String, List<double>>{};

    for (final log in logs) {
      final nextDay = DateTime.parse(log.date).add(const Duration(days: 1));
      final nextDayStr = _formatDateIso(nextDay);

      final nextDayEnergyList = energyByDate[nextDayStr];
      final nextDayMoodList = moodByDate[nextDayStr];

      double? avgEnergy;
      if (nextDayEnergyList != null && nextDayEnergyList.isNotEmpty) {
        avgEnergy = nextDayEnergyList.reduce((a, b) => a + b) / nextDayEnergyList.length;
      }

      double? avgMood;
      if (nextDayMoodList != null && nextDayMoodList.isNotEmpty) {
        avgMood = nextDayMoodList.reduce((a, b) => a + b) / nextDayMoodList.length;
      }

      if (avgEnergy != null) {
        sleepQualities.add(log.quality.score.toDouble());
        nextDayEnergies.add(avgEnergy);
      }
      if (avgMood != null) {
        // If not already added
        if (avgEnergy == null) {
          sleepQualities.add(log.quality.score.toDouble());
          nextDayEnergies.add(2); // baseline placeholder for Pearson sync length
        }
        nextDayMoods.add(avgMood);
      } else if (avgEnergy != null) {
        nextDayMoods.add(3); // baseline
      }

      // Group for best bedtime window
      if (log.bedtimeAt != null && (avgEnergy != null || avgMood != null)) {
        final bt = DateTime.fromMillisecondsSinceEpoch(log.bedtimeAt!);
        final minOfDay = bt.hour * 60 + bt.minute;
        
        // Find 30-min slot
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

    if (sleepQualities.length >= 3 && nextDayEnergies.length >= 3) {
      energyCorr = _calculatePearson(sleepQualities, nextDayEnergies);
    }
    if (sleepQualities.length >= 3 && nextDayMoods.length >= 3) {
      moodCorr = _calculatePearson(sleepQualities, nextDayMoods);
    }

    var bestWindow = 'نامشخص';
    var highestRating = -999.0;
    for (final entry in dayRatingsByBedtimeWindow.entries) {
      final avgRating = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgRating > highestRating) {
        highestRating = avgRating;
        bestWindow = entry.key;
      }
    }

    var insight = 'در حال یادگیری الگوی خواب شما 🌙';
    if (energyCorr != null && moodCorr != null) {
      if (energyCorr > 0.3 && moodCorr > 0.3) {
        insight = 'خواب باکیفیت‌تر دیشب با انرژی و روحیه بالاتر در روز بعد ارتباط مستقیم دارد.';
      } else if (energyCorr < -0.3) {
        insight = 'رابطه معکوس غیرمعمولی مشاهده شده؛ شاید در روزهای پرفشار خواب بیشتری داری.';
      } else {
        insight = 'روند خوابت منظم است، همبستگی مستقیمی با نوسانات روزانه ندارد.';
      }
    }

    return _CorrelationResult(
      energyCorr: energyCorr,
      moodCorr: moodCorr,
      bestWindow: bestWindow,
      insight: insight,
    );
  }

  double _calculatePearson(List<double> x, List<double> y) {
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

    if (denX == 0 || denY == 0) return 0;
    return num / sqrt(denX * denY);
  }
}

class _CorrelationResult {

  _CorrelationResult({
    this.energyCorr,
    this.moodCorr,
    required this.bestWindow,
    required this.insight,
  });
  final double? energyCorr;
  final double? moodCorr;
  final String bestWindow;
  final String insight;
}
