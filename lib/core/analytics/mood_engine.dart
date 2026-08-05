import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';

/// Input payload for [MoodEngine].
class MoodEngineInput {

  /// Creates a [MoodEngineInput].
  MoodEngineInput({
    required this.moodLogs,
    required this.energyLogs,
    required this.today,
    this.horizonDays = 30,
    this.isEnergyTuned = false,
    this.isUserMenstruating = false,
  });
  /// List of mood log entries.
  final List<MoodLog> moodLogs;

  /// List of energy log entries.
  final List<EnergyLog> energyLogs;

  /// Target evaluation date.
  final DateTime today;

  /// Horizon in days for historical analysis.
  final int horizonDays;

  /// Flag indicating if energy engine tuning is active.
  final bool isEnergyTuned;

  /// Flag indicating user menstruation context.
  final bool isUserMenstruating;
}

/// Output payload calculated by [MoodEngine].
class MoodEngineOutput {

  /// Creates a [MoodEngineOutput].
  MoodEngineOutput({
    this.dominantMood,
    required this.moodTrend,
    required this.moodByDaypart,
    this.energyMoodCorrelation,
    required this.correlationInsight,
  });
  /// Dominant mood in period.
  final Mood? dominantMood;

  /// List of mood trend average valences.
  final List<double> moodTrend;

  /// Mood distribution grouped by daypart.
  final Map<String, Mood> moodByDaypart;

  /// Pearson correlation score between energy and mood (-1.0 to +1.0).
  final double? energyMoodCorrelation;

  /// Textual insight derived from correlation score.
  final String correlationInsight;

  int get sampleCount => moodTrend.length;
  double? get avgScore => moodTrend.isNotEmpty ? moodTrend.reduce((a, b) => a + b) / moodTrend.length : null;
}

/// Analytics engine for mood trend and energy correlation.
class MoodEngine implements CachedEngine<MoodEngineInput, MoodEngineOutput> {
  @override
  void invalidate() {}

  @override
  bool canRun(MoodEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  @override
  Future<MoodEngineOutput> calculate(MoodEngineInput input) async {
    final cutoff = input.today.subtract(Duration(days: input.horizonDays)).millisecondsSinceEpoch;
    final recentMoodLogs = input.moodLogs.where((l) => l.loggedAt >= cutoff).toList();
    final recentEnergyLogs = input.energyLogs.where((l) => l.loggedAt >= cutoff).toList();

    // 1. Dominant Mood
    Mood? dominant;
    if (recentMoodLogs.isNotEmpty) {
      final counts = <Mood, int>{};
      for (final l in recentMoodLogs) {
        counts[l.mood] = (counts[l.mood] ?? 0) + 1;
      }
      var maxCount = -1;
      for (final entry in counts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          dominant = entry.key;
        }
      }
    }

    // 2. Mood Trend (Valence averages of consecutive days that have data)
    final trend = <double>[];
    // Go day by day from oldest to newest in the horizon
    for (var i = input.horizonDays - 1; i >= 0; i--) {
      final dayDate = input.today.subtract(Duration(days: i));
      final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day).millisecondsSinceEpoch;
      final dayEnd = dayStart + 24 * 60 * 60 * 1000;
      final dayLogs = recentMoodLogs.where((l) => l.loggedAt >= dayStart && l.loggedAt < dayEnd).toList();
      if (dayLogs.isNotEmpty) {
        final avg = dayLogs.map((l) => l.valence).reduce((a, b) => a + b) / dayLogs.length;
        trend.add(avg);
      }
    }

    // 3. Mood By Daypart
    final daypartMoods = <String, Mood>{};
    final daypartLogs = {
      'morning': <MoodLog>[],
      'afternoon': <MoodLog>[],
      'evening': <MoodLog>[],
      'night': <MoodLog>[],
    };

    for (final l in recentMoodLogs) {
      final dt = DateTime.fromMillisecondsSinceEpoch(l.loggedAt);
      final hour = dt.hour;
      String daypart;
      if (hour >= 5 && hour < 12) {
        daypart = 'morning';
      } else if (hour >= 12 && hour < 17) {
        daypart = 'afternoon';
      } else if (hour >= 17 && hour < 22) {
        daypart = 'evening';
      } else {
        daypart = 'night';
      }
      daypartLogs[daypart]!.add(l);
    }

    daypartLogs.forEach((daypart, logs) {
      if (logs.isNotEmpty) {
        final counts = <Mood, int>{};
        for (final l in logs) {
          counts[l.mood] = (counts[l.mood] ?? 0) + 1;
        }
        var bestMood = Mood.neutral;
        var maxVal = -1;
        counts.forEach((m, c) {
          if (c > maxVal) {
            maxVal = c;
            bestMood = m;
          }
        });
        daypartMoods[daypart] = bestMood;
      } else {
        daypartMoods[daypart] = Mood.neutral;
      }
    });

    // 4. Energy-Mood Correlation
    double? correlation;
    final valences = <double>[];
    final energyScores = <double>[];

    for (final mLog in recentMoodLogs) {
      if (recentEnergyLogs.isEmpty) break;
      var closest = recentEnergyLogs.first;
      var minDiff = (mLog.loggedAt - closest.loggedAt).abs();
      for (final eLog in recentEnergyLogs) {
        final diff = (mLog.loggedAt - eLog.loggedAt).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = eLog;
        }
      }

      // Max absolute difference of 2 hours
      if (minDiff <= 2 * 60 * 60 * 1000) {
        valences.add(mLog.valence.toDouble());
        energyScores.add(closest.energyLevel.score.toDouble());
      }
    }

    if (valences.length >= 3) {
      correlation = _calculatePearsonCorrelation(valences, energyScores);
    }

    // 5. Correlation Insight
    var insight = '';
    if (correlation == null) {
      insight = 'داده‌های ثبت‌شده برای تحلیل همبستگی هنوز کافی نیست. با ثبت مداوم حال و انرژی در روزهای آینده، این بخش فعال خواهد شد.';
    } else if (correlation > 0.5) {
      insight = 'همبستگی قوی و مثبتی بین انرژی بدنی و حال روحی شما دیده می‌شود؛ روزهایی که پرانرژی هستید، حال روحی بهتری را هم تجربه می‌کنید ☀️';
    } else if (correlation > 0.1) {
      insight = 'رابطه ملایمی بین سطح انرژی و حال روحی شما برقرار است؛ انرژی فیزیکی به بهبود حال شما کمک می‌کند اما عوامل بیرونی دیگر نیز تأثیرگذارند.';
    } else if (correlation >= -0.1) {
      insight = 'بین نوسانات انرژی بدنی و حال روحی شما همبستگی مستقیمی دیده نمی‌شود؛ به نظر می‌رسد این دو مستقل از یکدیگر در حال تغییرند.';
    } else if (correlation >= -0.5) {
      insight = 'رابطه معکوس ملایمی بین انرژی و حال روحی وجود دارد؛ گاهی در زمان‌های افت انرژی، آرامش ذهنی بیشتری دارید.';
    } else {
      insight = 'همبستگی معکوس شدیدی دیده می‌شود؛ روزهایی با انرژی بالا ممکن است با تنش همراه باشند و روزهای کم‌انرژی‌تر آرامش بیشتری به همراه دارند 🌿';
    }

    if (input.isEnergyTuned && input.isUserMenstruating) {
      insight += '\nهمچنین به نظر می‌رسد ریتمِ طبیعیِ بدن شما در این بازه، پذیرای استراحت و بازسازی بیشتری است 🌿';
    }

    return MoodEngineOutput(
      dominantMood: dominant,
      moodTrend: trend,
      moodByDaypart: daypartMoods,
      energyMoodCorrelation: correlation,
      correlationInsight: insight,
    );
  }

  double? _calculatePearsonCorrelation(List<double> x, List<double> y) {
    final n = x.length;
    var sumX = 0.0;
    var sumY = 0.0;
    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
    }
    final meanX = sumX / n;
    final meanY = sumY / n;

    var num = 0.0;
    var denX = 0.0;
    var denY = 0.0;

    for (var i = 0; i < n; i++) {
      final diffX = x[i] - meanX;
      final diffY = y[i] - meanY;
      num += diffX * diffY;
      denX += diffX * diffX;
      denY += diffY * diffY;
    }

    if (denX == 0.0 || denY == 0.0) return 0.0;
    return num / sqrt(denX * denY);
  }
}
