// lib/features/sports/movement/domain/movement_suggester.dart

import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/sports/movement/domain/movement_budget.dart';
import 'package:ritmo/features/sports/movement/domain/movement_kind.dart';
import 'package:shamsi_date/shamsi_date.dart';

class MovementSuggestion {
  const MovementSuggestion({
    required this.kind,
    required this.suggestedMinutes,
    required this.suggestedIntensity,
    required this.reasonFa,
    required this.confidence,
    required this.alternatives,
  });

  final MovementKind kind;
  final int suggestedMinutes;
  final MovementIntensity suggestedIntensity;
  final String reasonFa;
  final double confidence;
  final List<MovementKind> alternatives;
}

class MovementSuggester {
  static Future<MovementSuggestion?> suggestToday() async {
    final db = await DatabaseHelper.instance.database;

    // Load user physical limitations
    final limitList = <String>[];
    try {
      final pRows = await db.query('ss_user_profile', limit: 1);
      if (pRows.isNotEmpty) {
        final limStr = pRows.first['physicalLimitations']?.toString() ?? '';
        if (limStr.contains('knee')) limitList.add('knee');
        if (limStr.contains('back')) limitList.add('back');
        if (limStr.contains('shoulder')) limitList.add('shoulder');
      }
    } catch (_) {}

    final hasKneePain = limitList.contains('knee');

    // Get current budget snapshot
    final budgetSnapshot = await MovementBudgetService.instance.getCurrentWeekSnapshot();
    final budgetGap = budgetSnapshot.weeklyMetMinutesTarget - budgetSnapshot.achievedMetMinutes;

    // Get available kinds
    final allKinds = await MovementRepository.instance.getKinds();
    if (allKinds.isEmpty) return null;

    // Hard Gate: Filter out jointImpact = 3 if knee pain exists
    final safeKinds = allKinds.where((k) {
      if (hasKneePain && k.jointImpact >= 3) return false;
      return k.isEnabled;
    }).toList();

    if (safeKinds.isEmpty) return null;

    MovementKind primary = safeKinds.first;
    String reason = 'یک فعالیت سبک و عالی برای امروز 🌿';

    if (hasKneePain) {
      final swimming = safeKinds.firstWhere((k) => k.code == 'SWIMMING', orElse: () => safeKinds.first);
      primary = swimming;
      reason = 'شنا بدون فشار به زانو است و ۱۲۰ MET-min از بودجه این هفته را جبران می‌کند 🏊';
    } else if (budgetGap > 200) {
      final running = safeKinds.firstWhere((k) => k.code == 'RUNNING' || k.code == 'BRISK_WALKING', orElse: () => safeKinds.first);
      primary = running;
      reason = 'با توجه به کسری بودجه هفته، ${primary.titleFa} بهترین پیشنهاد است 🔥';
    } else {
      final walking = safeKinds.firstWhere((k) => k.code == 'WALKING', orElse: () => safeKinds.first);
      primary = walking;
      reason = 'یک پیاده‌روی دلپذیر ۳۰ دقیقه‌ای برای حفظ ریتم حرکت 🚶';
    }

    final alternatives = safeKinds.where((k) => k.code != primary.code).take(2).toList();

    return MovementSuggestion(
      kind: primary,
      suggestedMinutes: 30,
      suggestedIntensity: MovementIntensity.medium,
      reasonFa: reason,
      confidence: 0.9,
      alternatives: alternatives,
    );
  }
}
