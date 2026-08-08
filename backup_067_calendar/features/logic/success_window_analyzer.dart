import 'dart:math';
import 'package:ritmo/core/database/database_helper.dart';

class SuccessWindow {
  const SuccessWindow({
    required this.routineId,
    required this.medianStartMinutes,
    required this.stdDevMinutes,
    required this.sampleCount,
  });

  final String routineId;
  final int medianStartMinutes;
  final int stdDevMinutes;
  final int sampleCount;

  int get windowStart => (medianStartMinutes - stdDevMinutes).clamp(0, 1440);
  int get windowEnd => (medianStartMinutes + stdDevMinutes).clamp(0, 1440);
}

class SuccessWindowAnalyzer {
  const SuccessWindowAnalyzer();

  static Future<SuccessWindow?> analyzeRoutine(String routineId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'routine_completions',
      columns: ['actualStartMinutes'],
      where: 'routineId = ? AND actualStartMinutes IS NOT NULL AND actualStartMinutes > 0',
      whereArgs: [routineId],
      limit: 100,
    );

    if (rows.length < 8) return null;

    final minutesList = rows
        .map((r) => (r['actualStartMinutes'] as num).toInt())
        .where((m) => m >= 0 && m < 1440)
        .toList()..sort();

    if (minutesList.length < 8) return null;

    final count = minutesList.length;
    final median = count % 2 == 1
        ? minutesList[count ~/ 2]
        : ((minutesList[count ~/ 2 - 1] + minutesList[count ~/ 2]) ~/ 2);

    final mean = minutesList.reduce((a, b) => a + b) / count;
    final variance = minutesList.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) / count;
    final stdDev = sqrt(variance).round().clamp(15, 120);

    return SuccessWindow(
      routineId: routineId,
      medianStartMinutes: median,
      stdDevMinutes: stdDev,
      sampleCount: count,
    );
  }
}
