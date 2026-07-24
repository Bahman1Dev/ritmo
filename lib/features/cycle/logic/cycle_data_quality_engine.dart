import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';
import 'package:sqflite/sqflite.dart';

class CycleDataQualityEngine {
  static Future<DataQualityReport> evaluateDataQuality({
    required Database db,
    required List<Map<String, dynamic>> periodRows,
    required String todayIso,
  }) async {
    final hasEnoughCycles = periodRows.length >= 3;

    // Check forgotten open period
    bool hasForgottenOpenPeriod = false;
    if (periodRows.isNotEmpty) {
      final latest = periodRows.last;
      if (latest['endDate'] == null) {
        final start = DateTime.tryParse(latest['startDate'] as String? ?? '');
        if (start != null) {
          final daysOpen = DateTime.now().difference(start).inDays;
          if (daysOpen > 15) {
            hasForgottenOpenPeriod = true;
          }
        }
      }
    }

    // Query recent day logs count (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
    List<Map<String, dynamic>> recentLogs = [];
    try {
      recentLogs = await db.query(
        'cycle_day_logs',
        where: 'date >= ?',
        whereArgs: [thirtyDaysAgo],
      );
    } catch (_) {}
    final recentLogsCount = recentLogs.length;
    final hasRecentDailyLogs = recentLogsCount >= 5;

    final warningsFa = <String>[];
    if (periodRows.length < 3) {
      warningsFa.add('کمتر از ۳ چرخه ثبت شده است');
    }
    if (hasForgottenOpenPeriod) {
      warningsFa.add('یک دوره باز قدیمی تعیین تکلیف نشده است');
    }
    if (!hasRecentDailyLogs) {
      warningsFa.add('در ۳۰ روز اخیر ثبت روزانه کمی دارید');
    }

    final qualityLabelFa = periodRows.length >= 5 && hasRecentDailyLogs && !hasForgottenOpenPeriod
        ? 'عالی'
        : (periodRows.length >= 2 && !hasForgottenOpenPeriod ? 'متوسط' : 'نیازمند داده بیشتر');

    return DataQualityReport(
      hasEnoughCycles: hasEnoughCycles,
      hasRecentDailyLogs: hasRecentDailyLogs,
      hasForgottenOpenPeriod: hasForgottenOpenPeriod,
      hasPredictionConfidence: hasEnoughCycles && !hasForgottenOpenPeriod,
      recentLogsCount: recentLogsCount,
      qualityLabelFa: qualityLabelFa,
      warningsFa: warningsFa,
    );
  }
}
