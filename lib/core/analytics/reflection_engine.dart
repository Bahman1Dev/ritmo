import 'dart:math' as math;
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/util/safe_map.dart';

class ReflectionEngineInput {
  ReflectionEngineInput({
    required this.dailyReflections,
    required this.dailyCheckins,
    required this.energyLogs,
    required this.moodLogs,
    required this.today,
    this.horizonDays = 14,
    this.computeThemes = false, // T-2.6 / W-35: default false
  });
  final List<Map<String, dynamic>> dailyReflections;
  final List<Map<String, dynamic>> dailyCheckins;
  final List<Map<String, dynamic>> energyLogs;
  final List<Map<String, dynamic>> moodLogs;
  final DateTime today;
  final int horizonDays;
  final bool computeThemes;
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
    this.activeCount = 0,
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
  final int activeCount;
}

class ReflectionEngine implements CachedEngine<ReflectionEngineInput, ReflectionEngineOutput> {
  static const int minPointsForCorrelation = 30;

  @override
  Future<ReflectionEngineOutput> calculate(ReflectionEngineInput input) async {
    final cleanToday = RitmoDate.startOfDay(input.today);
    final todayStr = RitmoDate.dayKey(cleanToday);

    // T-3.3 / W-09: Exact horizon window using RitmoDate
    final dayKeys = RitmoDate.lastNDayKeys(cleanToday, input.horizonDays);
    final allowedKeys = dayKeys.toSet();

    final activeReflections = input.dailyReflections.where((r) {
      final d = r.readString('date');
      return d != null && allowedKeys.contains(d);
    }).toList();

    // 2. Streaks
    var currentStreak = 0;
    var longestStreak = 0;

    final reflectionDates = input.dailyReflections
        .map((r) => r.readString('date'))
        .whereType<String>()
        .toSet();

    if (reflectionDates.isNotEmpty) {
      final sortedDates = reflectionDates.toList()..sort();

      // Current streak:
      final yesterdayStr = RitmoDate.dayKey(cleanToday.subtract(const Duration(days: 1)));
      if (!reflectionDates.contains(todayStr) && !reflectionDates.contains(yesterdayStr)) {
        currentStreak = 0;
      } else {
        var checkDate = reflectionDates.contains(todayStr) ? cleanToday : cleanToday.subtract(const Duration(days: 1));
        while (reflectionDates.contains(RitmoDate.dayKey(checkDate))) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }

      // Longest streak:
      var currentRun = 0;
      DateTime? prevDate;
      for (final dateStr in sortedDates) {
        final date = RitmoDate.tryParseDayKey(dateStr);
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
      totalMood += (r.readDouble('mood_score') ?? 3.0);
    }
    final avgMood = activeReflections.isNotEmpty ? totalMood / activeReflections.length : 0.0;

    // 4. Completion rate (T-3.3 / W-10: never exceeds 1.0)
    final compRate = dayKeys.isNotEmpty
        ? (activeReflections.length / dayKeys.length).clamp(0.0, 1.0)
        : 0.0;

    // 5. Mood Trend
    activeReflections.sort((a, b) {
      final da = a.readString('date') ?? '';
      final db = b.readString('date') ?? '';
      return da.compareTo(db);
    });
    final moodTrendList = activeReflections
        .map((r) => (r.readDouble('mood_score') ?? 3.0))
        .toList();

    // 6. Theme frequency (T-2.6 / W-35: guarded by input.computeThemes)
    Map<String, int> themeFreq = const {};
    if (input.computeThemes) {
      final freq = <String, int>{};
      final stopWords = {'و', 'از', 'در', 'به', 'که', 'من', 'ما', 'این', 'آن', 'با', 'را', 'برای', 'است', 'بود', 'شد', 'یک', 'هم', 'تا', 'کرد', 'کند', 'روی', 'اما', 'ولی', 'یا', 'have', 'the', 'and', 'with', 'for'};
      for (final r in activeReflections) {
        final texts = [
          r.readString('reflection_text') ?? '',
          r.readString('reflectionNote') ?? '',
          r.readString('learnings') ?? '',
          r.readString('gratitude') ?? '',
          r.readString('wins') ?? '',
          r.readString('challenges') ?? '',
          r.readString('tomorrowFocus') ?? '',
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
      themeFreq = Map<String, int>.fromEntries(sortedFreq.take(10));
    }

    // 7. Pearson Correlations (T-1.5: 30 point gate)
    final reflectionScoresForEnergy = <double>[];
    final dayEnergies = <double>[];
    final reflectionScoresForMood = <double>[];
    final dayMoods = <double>[];

    final energyGrouping = <String, List<double>>{};
    for (final e in input.energyLogs) {
      final epoch = e.readInt('loggedAt') ?? e.readInt('timestamp') ?? 0;
      if (epoch == 0) continue;
      final eDate = RitmoDate.dayKeyFromMillis(epoch);
      final level = (e.readString('energyLevel') ?? 'MEDIUM').toUpperCase();
      final score = level == 'HIGH' ? 3.0 : (level == 'LOW' ? 1.0 : 2.0);
      energyGrouping.putIfAbsent(eDate, () => []).add(score);
    }
    final avgEnergyMap = energyGrouping.map((key, list) => MapEntry(key, list.reduce((a, b) => a + b) / list.length));

    final moodGrouping = <String, List<double>>{};
    for (final m in input.moodLogs) {
      final epoch = m.readInt('loggedAt') ?? m.readInt('timestamp') ?? 0;
      if (epoch == 0) continue;
      final mDate = RitmoDate.dayKeyFromMillis(epoch);
      final val = m.readDouble('valence') ?? 3.0;
      moodGrouping.putIfAbsent(mDate, () => []).add(val);
    }
    final avgMoodMap = moodGrouping.map((key, list) => MapEntry(key, list.reduce((a, b) => a + b) / list.length));

    for (final r in input.dailyReflections) {
      final rDate = r.readString('date');
      if (rDate == null) continue;
      final rScore = r.readDouble('mood_score') ?? 3.0;

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

    if (reflectionScoresForEnergy.length >= minPointsForCorrelation && dayEnergies.length >= minPointsForCorrelation) {
      energyCorr = _calculatePearson(reflectionScoresForEnergy, dayEnergies);
    }
    if (reflectionScoresForMood.length >= minPointsForCorrelation && dayMoods.length >= minPointsForCorrelation) {
      moodCorr = _calculatePearson(reflectionScoresForMood, dayMoods);
    }

    var correlationInsight = 'در حال تحلیل همبستگی خودمراقبتی شما 🧐';
    final n = math.max(reflectionScoresForEnergy.length, reflectionScoresForMood.length);
    if (moodCorr != null) {
      if (moodCorr > 0.3) {
        correlationInsight = 'به نظر می‌رسد ثبت منظم خودارزیابی، همراه بوده با روحیه بالاتری در پایان روز. (بر پایهٔ ${RitmoNumber.faInt(n)} ثبت)';
      } else if (moodCorr < -0.3) {
        correlationInsight = 'این الگو دیده شده که در روزهای پرچالش‌تر بازتاب‌های بیشتری ثبت کرده‌ای. (بر پایهٔ ${RitmoNumber.faInt(n)} ثبت)';
      } else {
        correlationInsight = 'ارتباط مستقیمی بین نوسانات روحیه و زمان ژورنال‌نویسی دیده نشده است. (بر پایهٔ ${RitmoNumber.faInt(n)} ثبت)';
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
      activeCount: activeReflections.length,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(ReflectionEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

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
