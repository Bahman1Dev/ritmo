import 'package:ritmo/core/domain/models.dart';

class NotificationDecider {
  static DecisionOutcome decide({
    required Routine routine,
    required Map<String, String> appSettings,
    required bool isCurrentZoneBlocked,
    bool isMenstruating = false,
  }) {
    // 1. Node Zero: Check if the module corresponding to this routine's category is enabled.
    if (!_isModuleEnabled(routine.category, appSettings)) {
      return DecisionOutcome.ignore;
    }

    // 2. Menstruation Suspension (تعلیق حیض):
    final worshipConsent = appSettings['cycle_consent_worship'] != 'false';
    if (isMenstruating && routine.category == Category.religious && worshipConsent) {
      return DecisionOutcome.ignore;
    }

    // 3. Essential bypass check. Essential routines (e.g., life-saving medicine, mandatory prayers)
    // bypass blocked zones.
    if (routine.isEssential) {
      return DecisionOutcome.sendStandard;
    }

    // 4. Blocked Zone check.
    if (isCurrentZoneBlocked) {
      return DecisionOutcome.deferOrCancel;
    }

    // Since human battery / energy logic is removed, all non-blocked routines are standard.
    return DecisionOutcome.sendStandard;
  }

  static bool _isModuleEnabled(Category category, Map<String, String> settings) {
    switch (category) {
      case Category.religious:
        return settings['module_religion_enabled'] == 'true';
      case Category.medical:
        return settings['module_medicine_enabled'] == 'true';
      case Category.learning:
        return settings['module_courses_enabled'] == 'true';
      case Category.konkur:
        return settings['module_study_enabled'] == 'true';
      case Category.custom:
        return true;
      case Category.work:
      case Category.personal:
      case Category.fitness:
      case Category.free:
        return true;
    }
  }
}
