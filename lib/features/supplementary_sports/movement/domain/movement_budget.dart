// lib/features/sports/movement/domain/movement_budget.dart

import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_event.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';
import 'package:shamsi_date/shamsi_date.dart';

class MovementBudgetSnapshot {
  const MovementBudgetSnapshot({
    required this.weeklyMetMinutesTarget,
    required this.achievedMetMinutes,
    required this.activeDays,
    required this.targetActiveDays,
    required this.byFamily,
    required this.byKind,
    required this.daysRemaining,
    required this.projectedTotal,
    required this.events,
  });

  final double weeklyMetMinutesTarget;
  final double achievedMetMinutes;
  final int activeDays;
  final int targetActiveDays;
  final Map<MovementFamily, double> byFamily;
  final Map<String, double> byKind;
  final int daysRemaining;
  final double projectedTotal;
  final List<MovementEvent> events;

  double get progressRatio => weeklyMetMinutesTarget > 0
      ? (achievedMetMinutes / weeklyMetMinutesTarget).clamp(0.0, 2.0)
      : 0.0;

  bool get isGoalMet => achievedMetMinutes >= weeklyMetMinutesTarget;
}

class MovementBudgetService {
  MovementBudgetService._();
  static final instance = MovementBudgetService._();

  /// Calculate the current week's movement budget snapshot (Persian week starting Saturday).
  Future<MovementBudgetSnapshot> getCurrentWeekSnapshot() async {
    final db = await DatabaseHelper.instance.database;

    // Load budget target configuration (default 500 MET-min, 4 active days)
    double targetMetMinutes = 500.0;
    int targetActiveDays = 4;

    try {
      final bRows = await db.query('movement_budget', where: "id = 'default'", limit: 1);
      if (bRows.isNotEmpty) {
        targetMetMinutes = (bRows.first['weeklyMetMinutesTarget'] as num? ?? 500.0).toDouble();
        targetActiveDays = (bRows.first['weeklyActiveDaysTarget'] as num? ?? 4).toInt();
      } else {
        await db.insert('movement_budget', {
          'id': 'default',
          'weeklyMetMinutesTarget': 500.0,
          'weeklyActiveDaysTarget': 4,
          'isAutoAdjusted': 1,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (_) {}

    // Calculate Persian week start (Saturday)
    final now = DateTime.now();
    final jalali = Jalali.fromDateTime(now);
    final dayOfWeekIndex = jalali.weekDay - 1; // Jalali weekDay: 1=Shanbe (0 offset) to 7=Jomeh (6 offset)

    final startOfWeekDate = now.subtract(Duration(days: dayOfWeekIndex));
    final startOfWeek = DateTime(startOfWeekDate.year, startOfWeekDate.month, startOfWeekDate.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final events = await MovementRepository.instance.eventsBetween(startOfWeek, endOfWeek);

    double totalMetMins = 0.0;
    final byFamily = <MovementFamily, double>{};
    final byKind = <String, double>{};
    final activeDates = <String>{};

    for (final e in events) {
      totalMetMins += e.metMinutes;
      byKind[e.kindCode] = (byKind[e.kindCode] ?? 0.0) + e.metMinutes;

      final kind = await MovementRepository.instance.getKind(e.kindCode);
      final family = kind?.family ?? MovementFamily.endurance;
      byFamily[family] = (byFamily[family] ?? 0.0) + e.metMinutes;

      final dt = DateTime.fromMillisecondsSinceEpoch(e.loggedAt);
      activeDates.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
    }

    final daysPassed = (dayOfWeekIndex + 1).clamp(1, 7);
    final daysRemaining = (7 - daysPassed).clamp(0, 6);
    final dailyPace = totalMetMins / daysPassed;
    final projectedTotal = totalMetMins + (dailyPace * daysRemaining);

    return MovementBudgetSnapshot(
      weeklyMetMinutesTarget: targetMetMinutes,
      achievedMetMinutes: totalMetMins,
      activeDays: activeDates.length,
      targetActiveDays: targetActiveDays,
      byFamily: byFamily,
      byKind: byKind,
      daysRemaining: daysRemaining,
      projectedTotal: projectedTotal,
      events: events,
    );
  }
}
