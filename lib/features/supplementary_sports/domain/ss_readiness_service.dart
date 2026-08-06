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
    this.hasData = true,
  });

  final SSReadinessTier tier;
  final String reasonFa;
  final String emoji;
  final int score; // 0..100 (0 means insufficient data)
  final int? sleepMinutes;
  final int recoveryLoad; // soreness + fatigue (0..6)
  final bool isMenstrualPhase;
  final bool hasData;
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
    bool hasRecoveryData = false;

    // 1. Load recovery log if available
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
        hasRecoveryData = true;
      }
    } catch (_) {}

    // 2. Load sleep data from bedtime_diagnostics (written by sleep module)
    try {
      final diagRows = await db.query(
        'bedtime_diagnostics',
        orderBy: 'createdAt DESC',
        limit: 1,
      );
      if (diagRows.isNotEmpty) {
        sleepMinutes = diagRows.first['durationMinutes'] as int?;
      }
    } catch (_) {}

    // Fallback to vital_signs_logs if bedtime_diagnostics is empty
    if (sleepMinutes == null) {
      try {
        final sleepRows = await db.query(
          'vital_signs_logs',
          where: "type = 'SLEEP'",
          orderBy: 'loggedAt DESC',
          limit: 1,
        );
        if (sleepRows.isNotEmpty) {
          sleepMinutes = (sleepRows.first['value'] as num?)?.toInt();
        }
      } catch (_) {}
    }

    // 3. Check menstrual cycle phase with consent guard
    bool isMenstrualPhase = false;
    try {
      final cycleConsent = await db.query(
        'app_settings',
        where: "key = 'share_cycle_with_sports'",
        limit: 1,
      );
      final hasConsent = cycleConsent.isNotEmpty && cycleConsent.first['value'] == 'true';

      if (hasConsent) {
        final cycleRows = await db.query(
          'cycle_logs',
          where: "phase = 'MENSTRUAL'",
          orderBy: 'date DESC',
          limit: 1,
        );
        if (cycleRows.isNotEmpty) {
          final lastDateStr = cycleRows.first['date'] as String?;
          if (lastDateStr != null) {
            final lastDate = DateTime.tryParse(lastDateStr);
            if (lastDate != null && today.difference(lastDate).inDays <= 5) {
              isMenstrualPhase = true;
            }
          }
        }
      }
    } catch (_) {}

    final recoveryLoad = soreness + fatigue;

    // If no sleep log and no recovery log exist, report insufficient data honestly
    if (sleepMinutes == null && !hasRecoveryData) {
      return SSReadinessVerdict(
        tier: SSReadinessTier.full,
        reasonFa: 'اطلاعات کافی نیست — خواب دیشب را ثبت کن 🌙',
        emoji: '📊',
        score: 0,
        sleepMinutes: null,
        recoveryLoad: recoveryLoad,
        isMenstrualPhase: isMenstrualPhase,
        hasData: false,
      );
    }

    if (isMenstrualPhase) {
      return SSReadinessVerdict(
        tier: SSReadinessTier.light,
        reasonFa: 'فاز قاعدگی — تمرینات ملایم و کششی پیشنهاد می‌شود 🌸',
        emoji: '🌸',
        score: 50,
        sleepMinutes: sleepMinutes,
        recoveryLoad: recoveryLoad,
        isMenstrualPhase: true,
      );
    }

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
      final hours = (sleepMinutes / 60.0).toStringAsFixed(1);
      return SSReadinessVerdict(
        tier: SSReadinessTier.light,
        reasonFa: 'دیشب کم خوابیدی ($hours ساعت) — نسخهٔ سبک پیشنهاد می‌شه 🔋',
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
