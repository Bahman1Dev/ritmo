import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';
import 'package:sqflite/sqflite.dart';

class CyclePersonalPatternEngine {
  static Future<List<SymptomForecast>> computePersonalForecasts({
    required Database db,
    required List<Map<String, dynamic>> periodRows,
    required double avgCycleLength,
  }) async {
    if (periodRows.length < 2) return [];

    try {
      final dayLogs = await db.query('cycle_day_logs');
      if (dayLogs.isEmpty) return [];

      // Group symptoms by cycle day
      final symptomDayCounts = <String, Map<int, int>>{};

      for (final log in dayLogs) {
        final dateStr = log['date'] as String?;
        if (dateStr == null) continue;
        final logDate = DateTime.tryParse(dateStr);
        if (logDate == null) continue;

        // Find which period this date belongs to
        for (final p in periodRows) {
          final pStart = DateTime.tryParse(p['startDate'] as String? ?? '');
          if (pStart == null) continue;
          if (logDate.isAfter(pStart) || logDate.isAtSameMomentAs(pStart)) {
            final cycleDay = logDate.difference(pStart).inDays + 1;
            if (cycleDay >= 1 && cycleDay <= avgCycleLength + 5) {
              final symptomsStr = log['symptoms'] as String? ?? '';
              if (symptomsStr.isNotEmpty) {
                final symptoms = symptomsStr.split(',');
                for (final sym in symptoms) {
                  final key = sym.trim();
                  if (key.isEmpty) continue;
                  symptomDayCounts.putIfAbsent(key, () => {});
                  symptomDayCounts[key]![cycleDay] = (symptomDayCounts[key]![cycleDay] ?? 0) + 1;
                }
              }
            }
          }
        }
      }

      final forecasts = <SymptomForecast>[];

      symptomDayCounts.forEach((symptomKey, dayMap) {
        if (dayMap.isEmpty) return;
        var maxDay = 1;
        var maxCount = 0;
        dayMap.forEach((day, count) {
          if (count > maxCount) {
            maxCount = count;
            maxDay = day;
          }
        });

        if (maxCount >= 2) {
          final confidence = (maxCount / periodRows.length).clamp(0.4, 0.95);
          final labelFa = _getSymptomFarsiLabel(symptomKey);
          forecasts.add(SymptomForecast(
            symptomKey: symptomKey,
            likelyCycleDay: maxDay,
            confidence: confidence,
            insightFa: 'در داده‌های ثبت‌شده شما، $labelFa معمولاً حوالی روز $maxDay چرخه تکرار شده است.',
          ));
        }
      });

      forecasts.sort((a, b) => b.confidence.compareTo(a.confidence));
      return forecasts.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  static String _getSymptomFarsiLabel(String key) {
    return switch (key.toLowerCase()) {
      'cramps' => 'گرفتگی و درد شکمی',
      'headache' => 'سردرد',
      'bloating' => 'نفخ',
      'backache' => 'کمردرد',
      'mood_swings' => 'نوسانات خلقی',
      'fatigue' => 'خستگی',
      'acne' => 'جوش پوستی',
      _ => key,
    };
  }
}
