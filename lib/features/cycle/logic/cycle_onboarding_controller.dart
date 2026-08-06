import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/domain/models.dart';

enum CyclePeriodStatusChoice {
  currentlyInPeriod,
  endedWithKnownStart,
  dontKnow,
  currentlyPregnant,
}

class CycleOnboardingData {
  CycleOnboardingData({
    this.periodStatus = CyclePeriodStatusChoice.endedWithKnownStart,
    this.cycleLength = 28,
    this.periodDuration = 6,
    DateTime? startDate,
    this.worshipConsent = false,
    this.energyConsent = false,
    this.remindersConsent = false,
    this.dashboardConsent = false,
    this.enableLock = false,
  }) : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 10));

  CyclePeriodStatusChoice periodStatus;
  int cycleLength;
  int periodDuration;
  DateTime startDate;
  bool worshipConsent;
  bool energyConsent;
  bool remindersConsent;
  bool dashboardConsent;
  bool enableLock;

  CycleOnboardingData copyWith({
    CyclePeriodStatusChoice? periodStatus,
    int? cycleLength,
    int? periodDuration,
    DateTime? startDate,
    bool? worshipConsent,
    bool? energyConsent,
    bool? remindersConsent,
    bool? dashboardConsent,
    bool? enableLock,
  }) {
    return CycleOnboardingData(
      periodStatus: periodStatus ?? this.periodStatus,
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      startDate: startDate ?? this.startDate,
      worshipConsent: worshipConsent ?? this.worshipConsent,
      energyConsent: energyConsent ?? this.energyConsent,
      remindersConsent: remindersConsent ?? this.remindersConsent,
      dashboardConsent: dashboardConsent ?? this.dashboardConsent,
      enableLock: enableLock ?? this.enableLock,
    );
  }
}

class CycleOnboardingController {
  static final CycleOnboardingController instance = CycleOnboardingController._();
  CycleOnboardingController._();

  /// Loads current onboarding configuration if already present (for Edit Mode),
  /// otherwise returns safe default data.
  Future<CycleOnboardingData> loadInitialData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settingsList = await db.query('app_settings');
      final settingsMap = {
        for (final s in settingsList)
          if (s['key'] != null) s['key'].toString(): s['value']?.toString() ?? ''
      };

      final avgLength = int.tryParse(settingsMap['cycle_avg_length'] ?? '') ??
          int.tryParse(settingsMap['user_cycle_length'] ?? '') ??
          28;
      final avgPeriod = int.tryParse(settingsMap['cycle_avg_period'] ?? '') ??
          int.tryParse(settingsMap['user_period_length'] ?? '') ??
          6;

      final worship = settingsMap['cycle_consent_worship'] == 'true';
      final energy = settingsMap['cycle_consent_energy'] == 'true';
      final reminders = settingsMap['cycle_consent_reminders'] == 'true';
      final dashboard = settingsMap['cycle_consent_dashboard'] == 'true';
      final lockEnabled = settingsMap['cycle_pin_enabled'] == 'true' ||
          settingsMap['cycle_biometric_enabled'] == 'true';

      // Query latest period to infer start date if available
      final periods = await db.query('cycle_periods', orderBy: 'startDate DESC', limit: 1);
      DateTime startDate = DateTime.now().subtract(const Duration(days: 10));
      CyclePeriodStatusChoice statusChoice = CyclePeriodStatusChoice.endedWithKnownStart;

      if (settingsMap['cycle_is_pregnant'] == 'true') {
        statusChoice = CyclePeriodStatusChoice.currentlyPregnant;
      } else if (periods.isNotEmpty) {
        final p = periods.first;
        final startStr = p['startDate'] as String?;
        if (startStr != null) {
          final dt = DateTime.tryParse(startStr);
          if (dt != null) startDate = dt;
        }
        if (p['endDate'] == null) {
          statusChoice = CyclePeriodStatusChoice.currentlyInPeriod;
        } else {
          statusChoice = CyclePeriodStatusChoice.endedWithKnownStart;
        }
      }

      return CycleOnboardingData(
        periodStatus: statusChoice,
        cycleLength: avgLength.clamp(21, 45),
        periodDuration: avgPeriod.clamp(3, 10),
        startDate: startDate,
        worshipConsent: worship,
        energyConsent: energy,
        remindersConsent: reminders,
        dashboardConsent: dashboard,
        enableLock: lockEnabled,
      );
    } catch (e) {
      debugPrint('Error loading cycle onboarding initial data: $e');
      return CycleOnboardingData();
    }
  }

  /// Saves onboarding data idempotently into SQLite.
  /// Dual-writes to new and old settings keys, guarantees module enablement,
  /// and calculates exact period end dates without unended period bugs.
  Future<void> saveOnboarding(CycleOnboardingData data, {bool isEditMode = false}) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final batch = db.batch();

    // 1. Unconditionally enable cycle module & save setup flags
    final settingsToSave = <String, String>{
      'module_cycle_enabled': 'true',
      'cycle_setup_done': 'true',
      'cycle_avg_length': data.cycleLength.toString(),
      'cycle_avg_period': data.periodDuration.toString(),
      // Mirroring to legacy engine keys (Bug چ-۵ resolution)
      'user_cycle_length': data.cycleLength.toString(),
      'user_period_length': data.periodDuration.toString(),
      // Privacy Consents
      'cycle_consent_worship': data.worshipConsent.toString(),
      'cycle_consent_energy': data.energyConsent.toString(),
      'cycle_consent_reminders': data.remindersConsent.toString(),
      'cycle_consent_dashboard': data.dashboardConsent.toString(),
      // One-time landing guidance flag (Bug چ-۱۸)
      'cycle_onboarding_just_completed': 'true',
    };

    if (data.periodStatus == CyclePeriodStatusChoice.currentlyPregnant) {
      settingsToSave['cycle_is_pregnant'] = 'true';
    } else {
      settingsToSave['cycle_is_pregnant'] = 'false';
    }

    for (final entry in settingsToSave.entries) {
      batch.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value, 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Handle Lock Preference (Bug چ-۱۰)
    if (data.enableLock) {
      batch.insert(
        'app_settings',
        {'key': 'cycle_biometric_enabled', 'value': 'true', 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 3. Handle Period Insertion / Update idempotently (Bug چ-۱, چ-۳, چ-۶)
    final cleanStartStr = data.startDate.toIso8601String().substring(0, 10);

    if (data.periodStatus == CyclePeriodStatusChoice.currentlyInPeriod) {
      // Check if an initial setup period already exists to update idempotently
      final existing = await db.query(
        'cycle_periods',
        where: 'note LIKE ? OR startDate = ?',
        whereArgs: ['%ثبت اولیه%', cleanStartStr],
      );

      if (existing.isNotEmpty && isEditMode) {
        batch.update(
          'cycle_periods',
          {
            'startDate': cleanStartStr,
            'endDate': null,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        batch.insert('cycle_periods', {
          'id': 'period_$nowMs',
          'startDate': cleanStartStr,
          'endDate': null,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
          'note': 'ثبت اولیه در راه‌اندازی',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
      }
    } else if (data.periodStatus == CyclePeriodStatusChoice.endedWithKnownStart) {
      // Calculate end date based on bleeding duration
      final calcEndDate = data.startDate.add(Duration(days: data.periodDuration - 1));
      final today = DateTime.now();
      final cleanToday = DateTime(today.year, today.month, today.day);

      // Ensure end date does not spill into the future
      final safeEnd = calcEndDate.isAfter(cleanToday) ? cleanToday : calcEndDate;
      final cleanEndStr = safeEnd.toIso8601String().substring(0, 10);

      final existing = await db.query(
        'cycle_periods',
        where: 'note LIKE ? OR startDate = ?',
        whereArgs: ['%ثبت اولیه%', cleanStartStr],
      );

      if (existing.isNotEmpty && isEditMode) {
        batch.update(
          'cycle_periods',
          {
            'startDate': cleanStartStr,
            'endDate': cleanEndStr,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        batch.insert('cycle_periods', {
          'id': 'period_$nowMs',
          'startDate': cleanStartStr,
          'endDate': cleanEndStr,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
          'note': 'ثبت اولیه در راه‌اندازی',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
      }
    }
    // If status == dontKnow or currentlyPregnant, NO period row is added (Bug چ-۱, چ-۶, چ-۱۱).

    await batch.commit(noResult: true);
    await ModuleManagementService.instance.setModuleEnabled('module_cycle_enabled', true);
    RitmoEvents.notifyRoutineChanged();
  }
}
