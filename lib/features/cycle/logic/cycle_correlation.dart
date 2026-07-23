import 'dart:convert';
import 'dart:math' as math;

import 'package:ritmo/features/cycle/models/cycle_models.dart';
import 'package:sqflite/sqflite.dart';

class CycleCorrelationAnalyzer {
  static Future<List<CycleCorrelation>> analyzeCorrelations(Database db) async {
    // 1. Fetch cycle day logs
    final List<Map<String, dynamic>> dayLogs = await db.query('cycle_day_logs', orderBy: 'logDate ASC');
    // 2. Fetch energy logs
    final List<Map<String, dynamic>> energyLogs = await db.query('energy_logs', orderBy: 'loggedAt ASC');
    // 3. Fetch sleep logs (bedtime_diagnostics ordered by date)
    final List<Map<String, dynamic>> sleepLogs = await db.query('bedtime_diagnostics', orderBy: 'date ASC');
    // 4. Fetch routine completions
    final List<Map<String, dynamic>> completions = await db.query('routine_completions', orderBy: 'completionTime ASC');

    if (dayLogs.length < 3) {
      return [
        CycleCorrelation(metric: 'انرژی بدنی', insight: 'داده‌های کافی برای محاسبه همبستگی انرژی بدنی وجود ندارد (حداقل ۳ ثبت روزانه نیاز است).'),
        CycleCorrelation(metric: 'کیفیت خواب', insight: 'داده‌های کافی برای محاسبه همبستگی کیفیت خواب وجود ندارد.'),
        CycleCorrelation(metric: 'پایبندی به روتین‌ها', insight: 'داده‌های کافی برای محاسبه همبستگی روتین‌ها وجود ندارد.'),
      ];
    }

    // Build day-to-day map for easy merging
    // Maps date (YYYY-MM-DD) to a map of values
    final mergedData = <String, Map<String, dynamic>>{};

    for (final log in dayLogs) {
      final date = log['logDate'] as String;
      // Flow Level (LIGHT, MEDIUM, HEAVY) mapped to score
      final flowStr = log['flowLevel']?.toString() ?? 'NONE';
      var flowLevel = 0.0;
      if (flowStr == 'LIGHT') flowLevel = 1.0;
      if (flowStr == 'MEDIUM') flowLevel = 2.0;
      if (flowStr == 'HEAVY') flowLevel = 3.0;

      // Parse symptoms list length
      var symptomCount = 0;
      final symptomsJson = log['symptomsJson'] as String?;
      if (symptomsJson != null && symptomsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(symptomsJson);
          if (decoded is List) symptomCount = decoded.length;
        } catch (_) {}
      }
      mergedData[date] = {
        'flowLevel': flowLevel,
        'symptomCount': symptomCount,
        'energy': <double>[],
        'sleepQuality': <double>[],
        'completionCount': 0.0,
      };
    }

    // Map energy logs to dates
    for (final log in energyLogs) {
      final loggedAt = log['loggedAt'] as int;
      final dateStr = DateTime.fromMillisecondsSinceEpoch(loggedAt).toIso8601String().substring(0, 10);
      if (mergedData.containsKey(dateStr)) {
        final levelStr = log['energyLevel'] as String? ?? 'MEDIUM';
        var score = 65.0;
        if (levelStr == 'HIGH') score = 100.0;
        if (levelStr == 'LOW') score = 30.0;
        (mergedData[dateStr]!['energy'] as List<double>).add(score);
      }
    }

    // Map sleep logs (bedtime_diagnostics) to dates using 'date' column
    for (final log in sleepLogs) {
      final dateStr = log['date'] as String?;
      if (dateStr != null && mergedData.containsKey(dateStr)) {
        final quality = (log['quality'] as num?)?.toDouble() ?? 3.0; // 1..5
        (mergedData[dateStr]!['sleepQuality'] as List<double>).add(quality);
      }
    }

    // Map completions to dates
    for (final comp in completions) {
      final compDate = comp['completionDate'] as String?;
      if (compDate != null && mergedData.containsKey(compDate)) {
        final resType = comp['resultType'] as String? ?? 'FULL';
        if (resType != 'SNOOZED') {
          mergedData[compDate]!['completionCount'] = (mergedData[compDate]!['completionCount'] as double) + 1.0;
        }
      }
    }

    // Compute vectors
    final flowVector = <double>[];
    final energyVector = <double>[];
    final sleepVector = <double>[];
    final completionVector = <double>[];

    mergedData.forEach((date, map) {
      final flow = map['flowLevel'] as double;
      if (flow > 0) {
        flowVector.add(flow);

        // Average energy for the day
        final energyList = map['energy'] as List<double>;
        if (energyList.isNotEmpty) {
          energyVector.add(energyList.reduce((a, b) => a + b) / energyList.length);
        } else {
          energyVector.add(65); // default fallback
        }

        // Average sleep for the day
        final sleepList = map['sleepQuality'] as List<double>;
        if (sleepList.isNotEmpty) {
          sleepVector.add(sleepList.reduce((a, b) => a + b) / sleepList.length);
        } else {
          sleepVector.add(3); // default fallback
        }

        // completions
        completionVector.add(map['completionCount'] as double);
      }
    });

    double? energyCorr;
    double? sleepCorr;
    double? compCorr;

    if (flowVector.length >= 3) {
      energyCorr = _calculatePearson(flowVector, energyVector);
      sleepCorr = _calculatePearson(flowVector, sleepVector);
      compCorr = _calculatePearson(flowVector, completionVector);
    }


    // Generate Farsi insights
    var energyInsight = 'همبستگی مشخصی بین شدت چرخه و انرژی بدنی ثبت نشده است.';
    if (energyCorr != null) {
      if (energyCorr < -0.3) {
        energyInsight = 'در روزهای با شدت جریان بیشتر، سطح انرژی بدنی شما کاهش نسبی نشان می‌دهد که طبیعی است. استراحت بیشتری را برنامه‌ریزی کنید. ⚡';
      } else if (energyCorr > 0.3) {
        energyInsight = 'جالب است که در روزهای جریان شدیدتر، سطح انرژی شما باثبات یا افزایشی گزارش شده است. ⚡';
      } else {
        energyInsight = 'سطح انرژی بدنی شما نوسان مستقیمی با شدت فیزیکی چرخه نشان نمی‌دهد. ⚡';
      }
    }

    var sleepInsight = 'رابطه مستقیمی بین کیفیت خواب و شدت ریتم بدنی شما یافت نشد.';
    if (sleepCorr != null) {
      if (sleepCorr < -0.3) {
        sleepInsight = 'کیفیت خواب شما در روزهای جریان شدیدتر اندکی افت می‌کند. دمای اتاق خواب را ملایم‌تر نگه دارید. 🌙';
      } else if (sleepCorr > 0.3) {
        sleepInsight = 'کیفیت خواب شما در روزهای با ریتم بدنی فعال بهبود می‌یابد. 🌙';
      } else {
        sleepInsight = 'کیفیت خواب شما در طول دوره‌های مختلف چرخه پایدار و مستقل است. 🌙';
      }
    }

    var compInsight = 'تأثیر محسوسی روی انجام و پایبندی به روتین‌های روزانه‌تان مشاهده نشد.';
    if (compCorr != null) {
      if (compCorr < -0.3) {
        compInsight = 'پایبندی به برنامه‌ها در روزهای اوج ریتم بدنی کمی سخت‌تر می‌شود؛ پیشنهاد می‌کنیم روتین‌های سبک‌تر را فعال کنید. 🌸';
      } else if (compCorr > 0.3) {
        compInsight = 'تمرکز و تعهد شما به انجام روتین‌ها در این روزها بالا ارزیابی می‌شود. 🌸';
      } else {
        compInsight = 'روال روزانه شما مستقل از فازهای طبیعی بدن با کیفیت مناسب ادامه دارد. 🌸';
      }
    }

    return [
      CycleCorrelation(metric: 'انرژی بدنی', coefficient: energyCorr, insight: energyInsight),
      CycleCorrelation(metric: 'کیفیت خواب', coefficient: sleepCorr, insight: sleepInsight),
      CycleCorrelation(metric: 'پایبندی به روتین‌ها', coefficient: compCorr, insight: compInsight),
    ];
  }

  static double? _calculatePearson(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return null;
    final n = x.length;
    double sumX = 0;
    double sumY = 0;
    double sumX2 = 0;
    double sumY2 = 0;
    double sumXY = 0;

    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
      sumXY += x[i] * y[i];
    }

    final denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    if (denominator == 0) return 0;
    return (n * sumXY - sumX * sumY) / denominator;
  }

  static Future<List<SymptomStat>> analyzeSymptomStats(Database db) async {
    final List<Map<String, dynamic>> dayLogs = await db.query('cycle_day_logs');
    final List<Map<String, dynamic>> periods = await db.query('cycle_periods', orderBy: 'startDate ASC');

    if (dayLogs.isEmpty) return [];

    final symptomCounts = <String, int>{};
    final symptomCycleDays = <String, List<int>>{};

    for (final log in dayLogs) {
      final dateStr = log['logDate'] as String;
      final symptomsJson = log['symptomsJson'] as String?;
      if (symptomsJson == null || symptomsJson.isEmpty) continue;

      var symptoms = <dynamic>[];
      try {
        symptoms = jsonDecode(symptomsJson) as List;
      } catch (_) {}

      if (symptoms.isEmpty) continue;

      // Find which cycle day this log corresponds to
      final logDate = DateTime.parse(dateStr);
      Map<String, dynamic>? activePeriod;
      for (var i = periods.length - 1; i >= 0; i--) {
        final start = DateTime.parse(periods[i]['startDate'] as String);
        if (!start.isAfter(logDate)) {
          activePeriod = periods[i];
          break;
        }
      }

      var cycleDay = 1;
      if (activePeriod != null) {
        final start = DateTime.parse(activePeriod['startDate'] as String);
        cycleDay = logDate.difference(start).inDays + 1;
      }

      for (final sym in symptoms) {
        final key = sym.toString();
        symptomCounts[key] = (symptomCounts[key] ?? 0) + 1;
        symptomCycleDays.putIfAbsent(key, () => []).add(cycleDay);
      }
    }

    final stats = <SymptomStat>[];
    symptomCounts.forEach((key, count) {
      final days = symptomCycleDays[key] ?? [];
      var typicalDay = 1;
      if (days.isNotEmpty) {
        days.sort();
        typicalDay = days[days.length ~/ 2]; // median
      }
      stats.add(SymptomStat(key: key, count: count, typicalCycleDay: typicalDay));
    });

    stats.sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }
}
