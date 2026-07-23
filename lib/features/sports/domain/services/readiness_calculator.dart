// lib/features/sports/domain/services/readiness_calculator.dart

import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

/// Pure function to calculate daily readiness score (0-100) and suggest WorkoutTier.
/// All inputs are pre-fetched; no DB access.
class ReadinessCalculator {
  /// Calculate readiness score and suggested tier.
  static ReadinessScore calculate({
    required String date, // YYYY-MM-DD
    required int? sleepMinutes,
    required int? sleepQuality, // 1-5
    required int? hrvRmssd,
    required int? restingHr,
    required int sorenessScore, // 0-10
    required int fatigueScore, // 0-10
    required int moodScore, // 1-5
    required bool isMenstrualPhase,
    required List<WorkoutSession> last7DaysSessions,
  }) {
    // ─── Factor Scores (0-100 each) ───
    final sleepScore = _scoreSleep(sleepMinutes, sleepQuality);       // 30%
    final hrvScore = _scoreHRV(hrvRmssd);                             // 20%
    final recoveryScore = _scoreRecovery(sorenessScore, fatigueScore); // 25%
    final loadScore = _scoreAcuteLoad(last7DaysSessions);             // 15%
    final computedMoodScore = _scoreMood(moodScore);                  // 10%

    // ─── Weighted Sum ───
    final raw = (sleepScore * 0.30) +
        (hrvScore * 0.20) +
        (recoveryScore * 0.25) +
        (loadScore * 0.15) +
        (computedMoodScore * 0.10);

    // Menstrual phase modifier (-10 points, floor 0)
    final menstrualModifier = isMenstrualPhase ? -10 : 0;
    final score = (raw + menstrualModifier).clamp(0, 100).round();

    // ─── Tier Decision ───
    WorkoutTier suggestedTier;
    String reason;

    if (score >= 85) {
      suggestedTier = WorkoutTier.full;
      reason = 'آمادگی بهینه —nergie کامل برای تمرین سنگین 🔥';
    } else if (score >= 70) {
      suggestedTier = WorkoutTier.light;
      reason = 'آمادگی خوب — نسخه سبک برای پیشرفت پایدار ⚡';
    } else if (score >= 50) {
      suggestedTier = WorkoutTier.light;
      reason = 'خستگی متوسط — تمرین ملایم و کنترل حجم 🟡';
    } else {
      suggestedTier = WorkoutTier.minimal;
      reason = 'خستگی بالا / ریسک بالاسری — تمرکز ریکاوری و حرکات سبک 💤';
    }

    // Menstrual note
    if (isMenstrualPhase) {
      reason += ' (فاز قاعدگی: اولویت با ریکاوری)';
    }

    // Warnings
    final warnings = <String>[];
    if (sleepMinutes != null && sleepMinutes < 300) warnings.add('خواب خیلی کوتاه (${(sleepMinutes/60).toStringAsFixed(1)}h) — اولویت ریکاوری');
    if (sleepMinutes != null && sleepMinutes < 360) warnings.add('خواب کم — نسخه سبک‌تر پیشنهاد میشه');
    if (hrvRmssd != null && hrvRmssd < 30) warnings.add('HRV پایین — استرس سیستم عصبی بالا');
    if (restingHr != null && restingHr > 80) warnings.add('نبض صبح بالا — احتمال خستگی/استرس');
    if (sorenessScore >= 6) warnings.add('کوفتی بالا — از حرکات سنگین خودداری کن');
    if (fatigueScore >= 6) warnings.add('خستگی بالا — اولویت استراحت فعال');
    if (moodScore <= 2) warnings.add('حال و هوا پایین — تمرین ملایم برای حالت روحی بهتر');

    return ReadinessScore(
      date: date,
      score: score,
      sleepMinutes: sleepMinutes,
      sleepQuality: sleepQuality,
      hrvRmssd: hrvRmssd,
      restingHr: restingHr,
      sorenessScore: sorenessScore,
      fatigueScore: fatigueScore,
      moodScore: moodScore,
      isMenstrualPhase: isMenstrualPhase,
      suggestedTier: suggestedTier,
      reason: reason,
      factorsJson: _factorsJson(sleepScore, hrvScore, recoveryScore, loadScore, moodScore, menstrualModifier),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ─── Factor Scoring (0-100) ───

  static int _scoreSleep(int? minutes, int? quality) {
    if (minutes == null || quality == null) return 60; // Neutral if missing

    var base = 0;
    if (minutes >= 480) {
      base = 100;           // 8h+
    } else if (minutes >= 420) base = 90;       // 7h
    else if (minutes >= 360) base = 75;       // 6h
    else if (minutes >= 300) base = 55;       // 5h
    else base = 30;                           // <5h

    // Quality multiplier (1-5)
    final qMult = quality / 5.0; // 0.2 - 1.0
    return (base * (0.5 + 0.5 * qMult)).round().clamp(0, 100);
  }

  static int _scoreHRV(int? hrvRmssd) {
    if (hrvRmssd == null) return 60;
    if (hrvRmssd >= 60) return 100;
    if (hrvRmssd >= 50) return 90;
    if (hrvRmssd >= 40) return 75;
    if (hrvRmssd >= 30) return 55;
    return 35;
  }

  static int _scoreRecovery(int soreness, int fatigue) {
    // Both 0-10, lower is better
    final avg = (soreness + fatigue) / 2.0; // 0-10
    // Invert: 0 avg -> 100, 10 avg -> 20
    return (100 - avg * 8).round().clamp(20, 100);
  }

  static int _scoreAcuteLoad(List<WorkoutSession> last7Days) {
    if (last7Days.isEmpty) return 70; // Neutral, no recent load

    final totalSets = last7Days.fold(0, (sum, s) => sum + s.totalSets);
    final totalVolume = last7Days.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
    final sessionCount = last7Days.length;

    // Heuristic: high volume/sets -> higher fatigue risk
    double loadIndex = 0;
    loadIndex += (sessionCount / 7.0) * 30;     // Frequency
    loadIndex += (totalSets / 100.0) * 40;      // Total sets (100 sets/week = high)
    loadIndex += (totalVolume / 50000.0) * 30;  // Volume (50M kg/week = high)

    // Invert: high load -> lower recovery score
    return (100 - loadIndex.clamp(0, 80)).round();
  }

  static int _scoreMood(int mood) {
    // 1-5, higher better
    return (mood * 20).clamp(0, 100);
  }

  static Map<String, int> _factorsJson(
    int sleep,
    int hrv,
    int recovery,
    int load,
    int mood,
    int menstrualMod,
  ) {
    return {
      'sleep': sleep,
      'hrv': hrv,
      'recovery': recovery,
      'load': load,
      'mood': mood,
      'menstrual_modifier': menstrualMod,
    };
  }
}