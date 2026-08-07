import 'package:ritmo/core/database/database_helper.dart';

class DailyPulseInput {
  const DailyPulseInput({
    required this.ratingScore, // 1 to 5 slider ("امروز چطور بود؟")
    this.note,                 // Optional note / reflection text
    this.dateStr,
  });

  final int ratingScore;
  final String? note;
  final String? dateStr;
}

class DailyPulseService {
  DailyPulseService._();
  static final DailyPulseService instance = DailyPulseService._();

  /// Consolidates morning checkin, mood, energy, and night reflection into a single 10-second pulse (§6).
  Future<void> submitPulse(DailyPulseInput input) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final dateStr = input.dateStr ?? now.toIso8601String().substring(0, 10);
    final nowMs = now.millisecondsSinceEpoch;

    final moodScore = input.ratingScore.clamp(1, 5).toDouble();

    // 1. Record/Update mood_logs
    await db.insert(
      'mood_logs',
      {
        'id': 'pulse_mood_${dateStr}_$nowMs',
        'date': dateStr,
        'timestamp': nowMs,
        'moodScore': moodScore,
        'note': input.note,
        'createdAt': nowMs,
      },
    );

    // 2. Record/Update daily_reflections
    if (input.note != null && input.note!.isNotEmpty) {
      await db.insert(
        'daily_reflections',
        {
          'id': 'pulse_reflection_${dateStr}_$nowMs',
          'date': dateStr,
          'timestamp': nowMs,
          'content': input.note,
          'moodScore': moodScore,
          'createdAt': nowMs,
        },
      );
    }
  }

  /// Derives energy level from real user behavior (completion rate, density) instead of asking user (§6).
  Future<double> deriveBehavioralEnergy(List<Map<String, dynamic>> completionsToday) async {
    if (completionsToday.isEmpty) return 2.5; // neutral baseline
    int doneCount = 0;
    for (final c in completionsToday) {
      final res = (c['resultType'] as String? ?? '').toUpperCase();
      if (res == 'COMPLETED' || res == 'DONE' || res == 'PARTIAL') {
        doneCount++;
      }
    }
    final ratio = doneCount / completionsToday.length;
    // Map ratio to 1.0 - 5.0 scale
    return (1.0 + (ratio * 4.0)).clamp(1.0, 5.0);
  }
}
