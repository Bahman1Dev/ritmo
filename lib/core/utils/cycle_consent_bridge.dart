import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/features/cycle/models/cycle_models.dart';

class CycleConsentBridge {
  /// Checks if the user is menstruating today (general biological status).
  static Future<bool> isUserMenstruating() async {
    final db = await DatabaseHelper.instance.database;
    
    // Load app settings
    final settingsList = await db.query('app_settings');
    final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

    final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
    final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
    final pregnancyMode = settingsMap['cycle_pregnancy_mode'] == 'true';

    if (!isFemale || !cycleEnabled || pregnancyMode) {
      return false;
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final today = DateTime.now();

    // Query all periods starting on or before today
    final periods = await db.query(
      'cycle_periods',
      where: 'startDate <= ?',
      whereArgs: [todayStr],
      orderBy: 'startDate DESC',
    );

    if (periods.isEmpty) {
      return false;
    }

    // Check if today falls within the latest period
    final latestPeriod = periods.first;
    final start = DateTime.parse(latestPeriod['startDate']! as String);
    final endStr = latestPeriod['endDate'] as String?;

    if (endStr != null) {
      final end = DateTime.parse(endStr);
      return !today.isAfter(end);
    } else {
      final avgPeriod = int.tryParse(settingsMap['cycle_avg_period'] ?? '6') ?? 6;
      final daysDiff = today.difference(start).inDays;
      return daysDiff >= 0 && daysDiff < avgPeriod;
    }
  }

  /// Checks if energy level tuning is consented by the user.
  static Future<bool> isEnergyTuned() async {
    final db = await DatabaseHelper.instance.database;
    
    final settingsList = await db.query('app_settings');
    final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

    final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
    final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
    final energyConsent = settingsMap['cycle_consent_energy'] == 'true';

    return isFemale && cycleEnabled && energyConsent;
  }

  /// Checks if worship should be suspended based on consent and active menstruation.
  static Future<bool> isWorshipSuspended() async {
    final db = await DatabaseHelper.instance.database;
    final settingsList = await db.query('app_settings');
    final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

    final worshipConsent = settingsMap['cycle_consent_worship'] == 'true';
    if (!worshipConsent) return false;

    return isUserMenstruating();
  }

  /// Exposes indirect body rhythm information to outer systems.
  static Future<BodyRhythmInfluence?> bodyRhythmInfluence({required String forSystem}) async {
    final db = await DatabaseHelper.instance.database;
    final settingsList = await db.query('app_settings');
    final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

    final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
    final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
    if (!isFemale || !cycleEnabled) return null;

    final menstruating = await isUserMenstruating();
    if (!menstruating) return null;

    if (forSystem == 'energy') {
      final consent = settingsMap['cycle_consent_energy'] == 'true';
      if (!consent) return null;
      return BodyRhythmInfluence(
        energyDelta: -15,
        indirectMessage: 'بر اساس ریتم طبیعی بدنتان در این روزها، سطح انرژی شما تحت تأثیر نوسانات زیستی قرار دارد و استراحت بیشتری پیشنهاد می‌شود.',
      );
    }

    if (forSystem == 'sleep') {
      final consent = settingsMap['cycle_consent_sleep'] == 'true';
      if (!consent) return null;
      return BodyRhythmInfluence(
        energyDelta: -10,
        indirectMessage: 'بر اساس ریتم طبیعی بدنتان، کیفیت خواب ممکن است با تغییرات زیستی مواجه شود. تلاش کنید خواب منظم‌تری داشته باشید.',
      );
    }

    return null;
  }

  /// Fasting Debt CRUD - Fetch all debts
  static Future<List<FastingDebt>> getFastingDebts() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> rows = await db.query('fasting_debt', orderBy: 'dateIso DESC');
    return rows.map(FastingDebt.fromMap).toList();
  }

  /// Fasting Debt CRUD - Update resolution status
  static Future<void> resolveFastingDebt(String id, bool isResolved) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'fasting_debt',
      {
        'isResolved': isResolved ? 1 : 0,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Also update worship_debts for bidirectional sync
    final worshipDebtId = 'debt_cycle_fast_$id';
    final existing = await db.query(
      'worship_debts',
      where: 'id = ?',
      whereArgs: [worshipDebtId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final totalCount = existing.first['totalCount'] as int? ?? 1;
      await db.update(
        'worship_debts',
        {
          'remainingCount': isResolved ? 0 : totalCount,
          'isArchived': isResolved ? 1 : 0,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [worshipDebtId],
      );
    }
  }
}
