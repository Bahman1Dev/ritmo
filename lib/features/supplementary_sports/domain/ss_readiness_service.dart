// lib/features/supplementary_sports/domain/ss_readiness_service.dart

import 'package:ritmo/core/database/database_helper.dart';

enum SSReadinessTier { full, light, minimal, rest }

class SSReadinessVerdict {
  const SSReadinessVerdict({
    required this.tier,
    required this.reasonFa,
    required this.emoji,
    required this.score,
    this.sleepMinutes,
    required this.recoveryLoad,
    this.isMenstrualPhase = false,
  });

  final SSReadinessTier tier;
  final String reasonFa;
  final String emoji;
  final int score; // 0..100
  final int? sleepMinutes;
  final int recoveryLoad; // soreness + fatigue (0..6)
  final bool isMenstrualPhase;
}

class SSReadinessService {
  SSReadinessService._();
  static final instance = SSReadinessService._();

  Future<SSReadinessVerdict> evaluateToday() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    int? sleepMinutes;
    int soreness = 1;
    int fatigue = 1;

    // Load recovery log if available
    try {
      final recRows = await db.query(
        'workout_recovery_logs',
        where: 'date = ?',
        whereArgs: [dateKey],
        orderBy: 'loggedAt DESC',
        limit: 1,
      );
      if (recRows.isNotEmpty) {
        soreness = recRows.first['soreness'] as int? ?? 1;
        fatigue = recRows.first['fatigue'] as int? ?? 1;
      }
    } catch (_) {}

    // Load sleep data if available from sleep logs
    try {
      final sleepRows = await db.query('vital_signs_logs', where: "type = 'SLEEP'", orderBy: 'loggedAt DESC', limit: 1);
      if (sleepRows.isNotEmpty) {
        sleepMinutes = (sleepRows.first['value'] as num?)?.toInt();
      }
    } catch (_) {}

    final recoveryLoad = soreness + fatigue;

    if (sleepMinutes != null && sleepMinutes < 300) {
      final hours = (sleepMinutes / 60.0).toStringAsFixed(1);
      return SSReadinessVerdict(
        tier: SSReadinessTier.minimal,
        reasonFa: 'دیشب خیلی کم خوابیدی ($hours ساعت) — نسخهٔ حداقلی تا زنجیره نشکنه ⚡',
        emoji: '⚡',
        score: 40,
        sleepMinutes: sleepMinutes,
        recoveryLoad: recoveryLoad,
      );
    }

    if (sleepMinutes != null && sleepMinutes < 360) {
      return SSReadinessVerdict(
        tier: SSReadinessTier.light,
        reasonFa: 'دیشب کم خوابیدی — نسخهٔ سبک پیشنهاد می‌شه 🔋',
        emoji: '🔋',
        score: 60,
        sleepMinutes: sleepMinutes,
        recoveryLoad: recoveryLoad,
      );
    }

    if (recoveryLoad >= 4) {
      return SSReadinessVerdict(
        tier: SSReadinessTier.light,
        reasonFa: 'بدنت هنوز خسته/کوفته‌ست — نسخهٔ سبک 💤',
        emoji: '💤',
        score: 55,
        sleepMinutes: sleepMinutes,
        recoveryLoad: recoveryLoad,
      );
    }

    if (recoveryLoad >= 2) {
      return SSReadinessVerdict(
        tier: SSReadinessTier.light,
        reasonFa: 'کمی کوفتگی داری — ملایم تمرین کن 🟡',
        emoji: '🟡',
        score: 75,
        sleepMinutes: sleepMinutes,
        recoveryLoad: recoveryLoad,
      );
    }

    return SSReadinessVerdict(
      tier: SSReadinessTier.full,
      reasonFa: 'انرژی و ریکاوری خوبه — نسخهٔ کامل 🔥',
      emoji: '🔥',
      score: 95,
      sleepMinutes: sleepMinutes,
      recoveryLoad: recoveryLoad,
    );
  }
}
