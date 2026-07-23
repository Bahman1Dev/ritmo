import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

class ReflectionEngineInput {

  ReflectionEngineInput({
    required this.dailyReflections,
    required this.dailyCheckins,
    required this.energyLogs,
    required this.moodLogs,
    required this.today,
    this.horizonDays = 14,
  });
  final List<Map<String, dynamic>> dailyReflections;
  final List<Map<String, dynamic>> dailyCheckins;
  final List<Map<String, dynamic>> energyLogs;
  final List<Map<String, dynamic>> moodLogs;
  final DateTime today;
  final int horizonDays;
}

class ReflectionEngineOutput {

  ReflectionEngineOutput({
    required this.currentStreak,
    required this.longestStreak,
    required this.entryCount,
    required this.completionRate,
    required this.avgMoodScore,
    required this.moodTrend,
    required this.themeFrequency,
    this.reflectionEnergyCorrelation,
    this.reflectionMoodCorrelation,
    required this.correlationInsight,
  });
  final int currentStreak;
  final int longestStreak;
  final int entryCount;
  final double completionRate;
  final double avgMoodScore;
  final List<double> moodTrend;
  final Map<String, int> themeFrequency;
  final double? reflectionEnergyCorrelation;
  final double? reflectionMoodCorrelation;
  final String correlationInsight;
}

class ReflectionEngine implements CachedEngine<ReflectionEngineInput, ReflectionEngineOutput> {
  @override
  Future<ReflectionEngineOutput> calculate(ReflectionEngineInput input) async {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);

    // 1. Filter reflections in horizonDays
    final horizonStart = cleanToday.subtract(Duration(days: input.horizonDays));
    final horizonStartStr = _formatDateIso(horizonStart);
    final activeReflections = input.dailyReflections
        .where((r) => (r['date'] as String).compareTo(horizonStartStr) >= 0 && (r['date'] as String).compareTo(todayStr) <= 0)
        .toList();

    // 2. Streaks
    var currentStreak = 0;
    var longestStreak = 0;

    final reflectionDates = input.dailyReflections
        .map((r) => r['date'] as String)
        .toSet();

    if (reflectionDates.isNotEmpty) {
      final sortedDates = reflectionDates.toList()..sort();
      
      // Current streak:
      final yesterdayStr = _formatDateIso(cleanToday.subtract(const Duration(days: 1)));
      if (!reflectionDates.contains(todayStr) && !reflectionDates.contains(yesterdayStr)) {
        currentStreak = 0;
      } else {
        var checkDate = reflectionDates.contains(todayStr) ? cleanToday : cleanToday.subtract(const Duration(days: 1));
        while (reflectionDates.contains(_formatDateIso(checkDate))) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }

      // Longest streak:
      var currentRun = 0;
      DateTime? prevDate;
      for (final dateStr in sortedDates) {
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
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
      }
      if (currentRun > longestStreak) longestStreak = currentRun;
    }

    // 3. Avg mood score
    double totalMood = 0;
    for (final r in activeReflections) {
      totalMood += (r['mood_score'] as num? ?? 3).toDouble();
    }
    final avgMood = activeReflections.isNotEmpty ? totalMood / activeReflections.length : 0.0;

    // 4. Completion rate
    final compRate = input.horizonDays > 0 ? activeReflections.length / input.horizonDays : 0.0;

    // 5. Mood Trend
    activeReflections.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    final moodTrendList = activeReflections.map((r) => (r['mood_score'] as num? ?? 3).toDouble()).toList();

    // 6. Theme frequency
    final freq = <String, int>{};
    final stopWords = {'و', 'از', 'در', 'به', 'که', 'من', 'ما', 'این', 'آن', 'با', 'را', 'برای', 'است', 'بود', 'شد', 'یک', 'هم', 'تا', 'کرد', 'کند', 'روی', 'اما', 'ولی', 'یا', 'have', 'the', 'and', 'with', 'for'};
    for (final r in input.dailyReflections) {
      final texts = [
        r['reflection_text']?.toString() ?? '',
        r['reflectionNote']?.toString() ?? '',
        r['learnings']?.toString() ?? '',
        r['gratitude']?.toString() ?? '',
        r['wins']?.toString() ?? '',
        r['challenges']?.toString() ?? '',
        r['tomorrowFocus']?.toString() ?? '',
      ];
      for (final text in texts) {
        if (text.isEmpty) continue;
        final words = text.toLowerCase().split(RegExp(r'[\s\p{P}]+', unicode: true));
        for (var word in words) {
          word = word.trim();
          if (word.length < 3 || stopWords.contains(word)) continue;
          freq[word] = (freq[word] ?? 0) + 1;
        }
      }
    }
    final sortedFreq = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final themeFreq = Map<String, int>.fromEntries(sortedFreq.take(10));

    // 7. Pearson Correlations
    final reflectionScoresForEnergy = <double>[];
    final dayEnergies = <double>[];
    final reflectionScoresForMood = <double>[];
    final dayMoods = <double>[];


    // Better grouping
    final energyGrouping = <String, List<double>>{};
    for (final e in input.energyLogs) {
      final epoch = e['loggedAt'] as int? ?? e['timestamp'] as int? ?? 0;
      final eDate = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(epoch));
      final level = e['energyLevel']?.toString().toUpperCase() ?? 'MEDIUM';
      final score = level == 'HIGH' ? 3.0 : (level == 'LOW' ? 1.0 : 2.0);
      energyGrouping.putIfAbsent(eDate, () => []).add(score);
    }
    final avgEnergyMap = energyGrouping.map((key, list) => MapEntry(key, list.reduce((a, b) => a + b) / list.length));

    final moodGrouping = <String, List<double>>{};
    for (final m in input.moodLogs) {
      final epoch = m['loggedAt'] as int? ?? m['timestamp'] as int? ?? 0;
      final mDate = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(epoch));
      final val = (m['valence'] as num? ?? 3).toDouble();
      moodGrouping.putIfAbsent(mDate, () => []).add(val);
    }
    final avgMoodMap = moodGrouping.map((key, list) => MapEntry(key, list.reduce((a, b) => a + b) / list.length));

    for (final r in input.dailyReflections) {
      final rDate = r['date'] as String;
      final rScore = (r['mood_score'] as num? ?? 3).toDouble();

      final energyVal = avgEnergyMap[rDate];
      if (energyVal != null) {
        reflectionScoresForEnergy.add(rScore);
        dayEnergies.add(energyVal);
      }

      final moodVal = avgMoodMap[rDate];
      if (moodVal != null) {
        reflectionScoresForMood.add(rScore);
        dayMoods.add(moodVal);
      }
    }

    double? energyCorr;
    double? moodCorr;

    if (reflectionScoresForEnergy.length >= 3) {
      energyCorr = _calculatePearson(reflectionScoresForEnergy, dayEnergies);
    }
    if (reflectionScoresForMood.length >= 3) {
      moodCorr = _calculatePearson(reflectionScoresForMood, dayMoods);
    }

    var correlationInsight = 'در حال تحلیل همبستگی خودمراقبتی شما 🧐';
    if (moodCorr != null) {
      if (moodCorr > 0.3) {
        correlationInsight = 'ثبت منظم خودارزیابی در پایان روز، رابطه مثبتی با تعادل و بهبود روحیه شما دارد.';
      } else if (moodCorr < -0.3) {
        correlationInsight = 'تأمل در روزهای پرچالش‌تر ثبت شده است که نشان‌دهنده نیاز شما به خودآگاهی در سختی‌هاست.';
      } else {
        correlationInsight = 'روحیه روزانه شما نوسان کمی نسبت به خودمراقبتی و ژورنال‌نویسی نشان می‌دهد.';
      }
    }

    return ReflectionEngineOutput(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      entryCount: input.dailyReflections.length,
      completionRate: compRate,
      avgMoodScore: avgMood,
      moodTrend: moodTrendList,
      themeFrequency: themeFreq,
      reflectionEnergyCorrelation: energyCorr,
      reflectionMoodCorrelation: moodCorr,
      correlationInsight: correlationInsight,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(ReflectionEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
