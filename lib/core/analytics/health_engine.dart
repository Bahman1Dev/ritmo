import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/features/health/models/health_models.dart';

class HealthEngineInput {

  HealthEngineInput({
    required this.bloodSugarLogs,
    required this.bloodPressureLogs,
    required this.vitalSignLogs,
    required this.medicationLogs,
    required this.prnLogs,
    required this.energyLogs,
    required this.sleepLogs,
    required this.hasDiabetes,
    required this.hasHypertension,
    required this.today,
    this.windowDays = 30,
  });
  final List<BloodSugarLog> bloodSugarLogs;
  final List<BloodPressureLog> bloodPressureLogs;
  final List<VitalSignLog> vitalSignLogs;
  final List<MedicationLog> medicationLogs;
  final List<Map<String, dynamic>> prnLogs; // List of prn_logs raw maps
  final List<Map<String, dynamic>> energyLogs; // List of energy_logs raw maps
  final List<Map<String, dynamic>> sleepLogs; // List of bedtime_diagnostics/sleep logs
  final bool hasDiabetes;
  final bool hasHypertension;
  final DateTime today;
  final int windowDays;
}

class HealthEngineOutput {

  HealthEngineOutput({
    required this.trends,
    required this.adherence,
    required this.correlations,
    required this.trendAlerts,
  });
  final List<VitalTrend> trends;
  final AdherenceStats adherence;
  final List<HealthCorrelation> correlations;
  final List<String> trendAlerts;
}

class HealthEngine implements CachedEngine<HealthEngineInput, HealthEngineOutput> {
  @override
  Future<HealthEngineOutput> calculate(HealthEngineInput input) async {
    return calculateSync(input);
  }

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(HealthEngineInput input) {
    final dayStamp = input.today.toIso8601String().substring(0, 10);
    return '$dayStamp|${input.windowDays}|${input.vitalSignLogs.length}|${input.medicationLogs.length}';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(HealthEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  // Sync helper for testing and easy calculation
  static HealthEngineOutput calculateSync(HealthEngineInput input) {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final cutoffDate = cleanToday.subtract(Duration(days: input.windowDays));
    final cutoffMs = cutoffDate.millisecondsSinceEpoch;

    // --- 1. Vital Trends Calculation ---
    final trendsList = <VitalTrend>[];
    final alerts = <String>[];

    // Blood Sugar Trend
    final activeSugarLogs = input.bloodSugarLogs
        .where((log) => log.loggedAt >= cutoffMs && log.loggedAt <= cleanToday.add(const Duration(days: 1)).millisecondsSinceEpoch)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    if (activeSugarLogs.isNotEmpty) {
      final points = activeSugarLogs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.value.toDouble(),
      )).toList();

      final avg = activeSugarLogs.map((l) => l.value).reduce((a, b) => a + b) / activeSugarLogs.length;

      // In range percent
      var inRangeCount = 0;
      for (final log in activeSugarLogs) {
        if (_isBloodSugarInRange(log.value, log.measurementType, input.hasDiabetes)) {
          inRangeCount++;
        }
      }
      final inRangePct = (inRangeCount / activeSugarLogs.length) * 100.0;
      final dir = _calculateDirection(activeSugarLogs.map((l) => l.value.toDouble()).toList(), 5);

      trendsList.add(VitalTrend(
        metric: 'blood_sugar',
        points: points,
        average: avg,
        direction: dir,
        inRangePercent: inRangePct,
      ));

      // Trend Alert check (Recent 7 days average vs previous window average)
      final sevenDaysAgoMs = cleanToday.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final recentLogs = activeSugarLogs.where((l) => l.loggedAt >= sevenDaysAgoMs).toList();
      final olderLogs = activeSugarLogs.where((l) => l.loggedAt < sevenDaysAgoMs).toList();
      if (recentLogs.isNotEmpty && olderLogs.isNotEmpty) {
        final recentAvg = recentLogs.map((l) => l.value).reduce((a, b) => a + b) / recentLogs.length;
        final olderAvg = olderLogs.map((l) => l.value).reduce((a, b) => a + b) / olderLogs.length;
        if (recentAvg > olderAvg + 15.0) {
          alerts.add('میانگین قند خون شما در روزهای اخیر افزایش داشته است. لطفاً به رژیم غذایی و مصرف داروها توجه کنید.');
        } else if (recentAvg < olderAvg - 15.0) {
          alerts.add('میانگین قند خون شما در روزهای اخیر کاهش یافته است.');
        }
      }
    }

    // Blood Pressure Trend (Systolic & Diastolic separately)
    final activeBPLogs = input.bloodPressureLogs
        .where((log) => log.loggedAt >= cutoffMs && log.loggedAt <= cleanToday.add(const Duration(days: 1)).millisecondsSinceEpoch)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    if (activeBPLogs.isNotEmpty) {
      // Systolic
      final sysPoints = activeBPLogs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.systolic.toDouble(),
      )).toList();
      final sysAvg = activeBPLogs.map((l) => l.systolic).reduce((a, b) => a + b) / activeBPLogs.length;

      // Diastolic
      final diaPoints = activeBPLogs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.diastolic.toDouble(),
      )).toList();
      final diaAvg = activeBPLogs.map((l) => l.diastolic).reduce((a, b) => a + b) / activeBPLogs.length;

      // In range percent (both systolic and diastolic must be in range)
      var bpInRangeCount = 0;
      for (final log in activeBPLogs) {
        if (_isBloodPressureInRange(log.systolic, log.diastolic, input.hasHypertension)) {
          bpInRangeCount++;
        }
      }
      final bpInRangePct = (bpInRangeCount / activeBPLogs.length) * 100.0;

      final sysDir = _calculateDirection(activeBPLogs.map((l) => l.systolic.toDouble()).toList(), 3);
      final diaDir = _calculateDirection(activeBPLogs.map((l) => l.diastolic.toDouble()).toList(), 3);

      trendsList.add(VitalTrend(
        metric: 'blood_pressure_systolic',
        points: sysPoints,
        average: sysAvg,
        direction: sysDir,
        inRangePercent: bpInRangePct,
      ));

      trendsList.add(VitalTrend(
        metric: 'blood_pressure_diastolic',
        points: diaPoints,
        average: diaAvg,
        direction: diaDir,
        inRangePercent: bpInRangePct,
      ));

      // BP Alert
      final sevenDaysAgoMs = cleanToday.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final recentLogs = activeBPLogs.where((l) => l.loggedAt >= sevenDaysAgoMs).toList();
      final olderLogs = activeBPLogs.where((l) => l.loggedAt < sevenDaysAgoMs).toList();
      if (recentLogs.isNotEmpty && olderLogs.isNotEmpty) {
        final recentSysAvg = recentLogs.map((l) => l.systolic).reduce((a, b) => a + b) / recentLogs.length;
        final olderSysAvg = olderLogs.map((l) => l.systolic).reduce((a, b) => a + b) / olderLogs.length;
        if (recentSysAvg > olderSysAvg + 8.0) {
          alerts.add('میانگین فشار خون سیستولیک شما اخیراً افزایش داشته است. در صورت تداوم با پزشک مشورت کنید.');
        }
      }
    }

    // Weight, SpO2, Temperature from VitalSignLog
    final activeVitalLogs = input.vitalSignLogs
        .where((log) => log.loggedAt >= cutoffMs && log.loggedAt <= cleanToday.add(const Duration(days: 1)).millisecondsSinceEpoch)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    final weightLogs = activeVitalLogs.where((l) => l.vitalType == 'WEIGHT').toList()..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    if (weightLogs.isNotEmpty) {
      final points = weightLogs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.value,
      )).toList();
      final avg = weightLogs.map((l) => l.value).reduce((a, b) => a + b) / weightLogs.length;
      final dir = _calculateDirection(weightLogs.map((l) => l.value).toList(), 0.5);

      trendsList.add(VitalTrend(
        metric: 'weight',
        points: points,
        average: avg,
        direction: dir,
        inRangePercent: 100,
      ));
    }

    final spo2Logs = activeVitalLogs.where((l) => l.vitalType == 'SPO2').toList()..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    if (spo2Logs.isNotEmpty) {
      final points = spo2Logs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.value,
      )).toList();
      final avg = spo2Logs.map((l) => l.value).reduce((a, b) => a + b) / spo2Logs.length;
      final dir = _calculateDirection(spo2Logs.map((l) => l.value).toList(), 1);
      final inRangeCount = spo2Logs.where((l) => l.value >= 95.0 && l.value <= 100.0).length;
      final inRangePct = (inRangeCount / spo2Logs.length) * 100.0;

      trendsList.add(VitalTrend(
        metric: 'spo2',
        points: points,
        average: avg,
        direction: dir,
        inRangePercent: inRangePct,
      ));
    }

    final tempLogs = activeVitalLogs.where((l) => l.vitalType == 'TEMPERATURE').toList()..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    if (tempLogs.isNotEmpty) {
      final points = tempLogs.map((l) => TrendPoint(
        dateIso: _formatDateIso(DateTime.fromMillisecondsSinceEpoch(l.loggedAt)),
        value: l.value,
      )).toList();
      final avg = tempLogs.map((l) => l.value).reduce((a, b) => a + b) / tempLogs.length;
      final dir = _calculateDirection(tempLogs.map((l) => l.value).toList(), 0.1);
      final inRangeCount = tempLogs.where((l) => l.value >= 36.0 && l.value <= 37.5).length;
      final inRangePct = (inRangeCount / tempLogs.length) * 100.0;

      trendsList.add(VitalTrend(
        metric: 'temperature',
        points: points,
        average: avg,
        direction: dir,
        inRangePercent: inRangePct,
      ));
    }

    // --- 2. Adherence Calculations ---
    final activeMedLogs = input.medicationLogs
        .where((log) => log.createdAt >= cutoffMs)
        .toList();

    var adherenceRate = 1.0;
    if (activeMedLogs.isNotEmpty) {
      final takenCount = activeMedLogs.where((l) => l.status == 'TAKEN').length;
      adherenceRate = takenCount / activeMedLogs.length;
    }

    // Streaks (based on daily checklist compliance)
    // Map of date -> taken count, skipped count
    final dailyTaken = <String, int>{};
    final dailySkipped = <String, int>{};

    for (final log in activeMedLogs) {
      final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(log.createdAt));
      if (log.status == 'TAKEN') {
        dailyTaken[dateStr] = (dailyTaken[dateStr] ?? 0) + 1;
      } else {
        dailySkipped[dateStr] = (dailySkipped[dateStr] ?? 0) + 1;
      }
    }

    // Also include prn_logs as taken (no skipped)
    final prnDates = <String>{};
    for (final log in input.prnLogs) {
      final takenAt = log['takenAt'] as int?;
      if (takenAt != null && takenAt >= cutoffMs) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(takenAt));
        dailyTaken[dateStr] = (dailyTaken[dateStr] ?? 0) + 1;
        prnDates.add(dateStr);
      }
    }

    // Determine all unique dates with activity
    final allDates = {...dailyTaken.keys, ...dailySkipped.keys}..toList();
    final sortedDates = allDates.toList()..sort();

    var currentStreak = 0;
    var longestStreak = 0;

    if (sortedDates.isNotEmpty) {
      final todayStr = _formatDateIso(cleanToday);
      final yesterdayStr = _formatDateIso(cleanToday.subtract(const Duration(days: 1)));

      final hasToday = dailyTaken.containsKey(todayStr) && !dailySkipped.containsKey(todayStr);
      final hasYesterday = dailyTaken.containsKey(yesterdayStr) && !dailySkipped.containsKey(yesterdayStr);

      if (!hasToday && !hasYesterday) {
        currentStreak = 0;
      } else {
        var checkDate = hasToday ? cleanToday : cleanToday.subtract(const Duration(days: 1));
        while (true) {
          final dateStr = _formatDateIso(checkDate);
          if (dailyTaken.containsKey(dateStr) && !dailySkipped.containsKey(dateStr)) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      // Longest streak
      var currentRun = 0;
      DateTime? prevDate;
      for (final dateStr in sortedDates) {
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final hasTaken = dailyTaken.containsKey(dateStr);
        final hasSkipped = dailySkipped.containsKey(dateStr);

        if (hasTaken && !hasSkipped) {
          if (prevDate == null) {
            currentRun = 1;
          } else {
            final diff = date.difference(prevDate).inDays;
            if (diff == 1) {
              currentRun++;
            } else if (diff > 1) {
              if (currentRun > longestStreak) longestStreak = currentRun;
              currentRun = 1;
            }
          }
          prevDate = date;
        } else if (hasSkipped) {
          if (currentRun > longestStreak) longestStreak = currentRun;
          currentRun = 0;
          prevDate = null;
        }
      }
      if (currentRun > longestStreak) longestStreak = currentRun;
    }

    // Missed pattern analysis
    String? missedPattern;
    if (activeMedLogs.isNotEmpty) {
      final skippedLogs = activeMedLogs.where((l) => l.status == 'SKIPPED').toList();
      if (skippedLogs.isNotEmpty) {
        var morningCount = 0;
        var afternoonCount = 0;
        var eveningCount = 0;

        for (final log in skippedLogs) {
          final dt = DateTime.fromMillisecondsSinceEpoch(log.scheduledTime ?? log.createdAt);
          final hour = dt.hour;
          if (hour >= 5 && hour < 12) {
            morningCount++;
          } else if (hour >= 12 && hour < 17) {
            afternoonCount++;
          } else {
            eveningCount++;
          }
        }

        final maxCount = [morningCount, afternoonCount, eveningCount].reduce(max);
        if (maxCount > 0) {
          if (maxCount == morningCount) {
            missedPattern = 'صبح‌ها بیشتر فراموش می‌شود';
          } else if (maxCount == afternoonCount) {
            missedPattern = 'ظهرها بیشتر فراموش می‌شود';
          } else {
            missedPattern = 'عصر و شب‌ها بیشتر فراموش می‌شود';
          }
        }
      }
    }

    final adherenceStats = AdherenceStats(
      adherenceRate: adherenceRate,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      missedPattern: missedPattern,
    );

    // --- 3. Health Correlations ---
    final correlationList = <HealthCorrelation>[];

    // Prepare matched daily datasets for Pearson Correlation
    // Group sleep by date
    final sleepByDate = <String, double>{};
    for (final log in input.sleepLogs) {
      final timestamp = log['updatedAt'] as int? ?? log['createdAt'] as int?;
      final quality = log['quality'] as int?;
      if (timestamp != null && quality != null) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(timestamp));
        sleepByDate[dateStr] = quality.toDouble();
      }
    }

    // Group energy by date
    final energyByDate = <String, double>{};
    for (final log in input.energyLogs) {
      final timestamp = log['updatedAt'] as int? ?? log['createdAt'] as int?;
      final levelStr = log['value'] as String?; // e.g. 'HIGH', 'MEDIUM', 'LOW'
      if (timestamp != null && levelStr != null) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(timestamp));
        var val = 3.0; // default medium
        if (levelStr == 'HIGH') val = 5.0;
        if (levelStr == 'LOW') val = 1.0;
        energyByDate[dateStr] = val;
      }
    }

    // 3.1 Blood Sugar correlations
    if (activeSugarLogs.isNotEmpty) {
      // Sugar vs Energy
      final sugarVals = <double>[];
      final energyVals = <double>[];
      for (final log in activeSugarLogs) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        if (energyByDate.containsKey(dateStr)) {
          sugarVals.add(log.value.toDouble());
          energyVals.add(energyByDate[dateStr]!);
        }
      }
      final sugarEnergyCoeff = _calculatePearson(sugarVals, energyVals);
      correlationList.add(HealthCorrelation(
        metric: 'sugar_energy',
        coefficient: sugarEnergyCoeff,
        insight: _generateInsight('قند خون', 'انرژی روزانه', sugarEnergyCoeff),
      ));

      // Sugar vs Sleep
      final sugarValsS = <double>[];
      final sleepVals = <double>[];
      for (final log in activeSugarLogs) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        if (sleepByDate.containsKey(dateStr)) {
          sugarValsS.add(log.value.toDouble());
          sleepVals.add(sleepByDate[dateStr]!);
        }
      }
      final sugarSleepCoeff = _calculatePearson(sugarValsS, sleepVals);
      correlationList.add(HealthCorrelation(
        metric: 'sugar_sleep',
        coefficient: sugarSleepCoeff,
        insight: _generateInsight('قند خون', 'کیفیت خواب دیشب', sugarSleepCoeff),
      ));
    }

    // 3.2 Blood Pressure (Systolic) correlations
    if (activeBPLogs.isNotEmpty) {
      // BP vs Energy
      final bpVals = <double>[];
      final energyVals = <double>[];
      for (final log in activeBPLogs) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        if (energyByDate.containsKey(dateStr)) {
          bpVals.add(log.systolic.toDouble());
          energyVals.add(energyByDate[dateStr]!);
        }
      }
      final bpEnergyCoeff = _calculatePearson(bpVals, energyVals);
      correlationList.add(HealthCorrelation(
        metric: 'bp_energy',
        coefficient: bpEnergyCoeff,
        insight: _generateInsight('فشار خون سیستولیک', 'انرژی روزانه', bpEnergyCoeff),
      ));

      // BP vs Sleep
      final bpValsS = <double>[];
      final sleepVals = <double>[];
      for (final log in activeBPLogs) {
        final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        if (sleepByDate.containsKey(dateStr)) {
          bpValsS.add(log.systolic.toDouble());
          sleepVals.add(sleepByDate[dateStr]!);
        }
      }
      final bpSleepCoeff = _calculatePearson(bpValsS, sleepVals);
      correlationList.add(HealthCorrelation(
        metric: 'bp_sleep',
        coefficient: bpSleepCoeff,
        insight: _generateInsight('فشار خون سیستولیک', 'کیفیت خواب دیشب', bpSleepCoeff),
      ));
    }

    return HealthEngineOutput(
      trends: trendsList,
      adherence: adherenceStats,
      correlations: correlationList,
      trendAlerts: alerts,
    );
  }

  // --- Helper Math Methods ---
  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool _isBloodSugarInRange(int value, String type, bool hasDiabetes) {
    if (hasDiabetes) {
      switch (type) {
        case 'FASTING':
        case 'BEFORE_MEAL':
          return value >= 80 && value <= 130;
        case 'AFTER_MEAL':
          return value >= 80 && value <= 180;
        case 'BEDTIME':
          return value >= 100 && value <= 150;
        default:
          return value >= 80 && value <= 180;
      }
    } else {
      switch (type) {
        case 'FASTING':
          return value >= 70 && value <= 100;
        case 'BEFORE_MEAL':
          return value >= 70 && value <= 110;
        case 'AFTER_MEAL':
          return value >= 70 && value <= 140;
        case 'BEDTIME':
          return value >= 100 && value <= 140;
        default:
          return value >= 70 && value <= 140;
      }
    }
  }

  static bool _isBloodPressureInRange(int systolic, int diastolic, bool hasHypertension) {
    final sysMax = hasHypertension ? 130 : 120;
    const diaMax = 80;
    return systolic <= sysMax && diastolic <= diaMax;
  }

  static String _calculateDirection(List<double> values, double threshold) {
    if (values.length < 2) return 'stable';
    // Compare the average of the second half of the points to the first half
    final halfLen = values.length ~/ 2;
    if (halfLen == 0) return 'stable';

    final firstHalf = values.sublist(0, halfLen);
    final secondHalf = values.sublist(values.length - halfLen);

    final avgFirst = firstHalf.reduce((a, b) => a + b) / halfLen;
    final avgSecond = secondHalf.reduce((a, b) => a + b) / halfLen;

    if (avgSecond > avgFirst + threshold) return 'up';
    if (avgSecond < avgFirst - threshold) return 'down';
    return 'stable';
  }

  static double? _calculatePearson(List<double> x, List<double> y) {
    if (x.length < 3 || y.length < 3 || x.length != y.length) return null;
    final n = x.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;
    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }
    final num = n * sumXY - sumX * sumY;
    final den = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    if (den == 0) return null;
    return num / den;
  }

  static String _generateInsight(String metricA, String metricB, double? coeff) {
    if (coeff == null) {
      return 'داده‌های کافی جهت بررسی ارتباط بین $metricA و $metricB وجود ندارد.';
    }
    final strength = coeff.abs() > 0.7
        ? 'قوی'
        : (coeff.abs() > 0.4 ? 'متوسط' : 'ضعیف');

    if (coeff.abs() < 0.2) {
      return 'ارتباط مشخصی بین تغییرات $metricA و $metricB یافت نشد.';
    }

    if (coeff > 0) {
      return 'بین تغییرات $metricA و $metricB یک همبستگی مثبت $strength وجود دارد. معمولاً در روزهایی که $metricB بهبود می‌یابد یا بیشتر است، $metricA نیز افزایش نشان می‌دهد (توجه داشته باشید که این رابطه لزوماً علّی نیست).';
    } else {
      return 'بین تغییرات $metricA و $metricB یک همبستگی منفی $strength وجود دارد. معمولاً در روزهایی که $metricB بهبود می‌یابد یا بیشتر است، $metricA در سطح پایین‌تر و مناسب‌تری قرار دارد (توجه داشته باشید که این رابطه لزوماً علّی نیست).';
    }
  }
}
