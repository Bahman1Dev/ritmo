import 'package:ritmo/core/utils/cycle_privacy_guard.dart';

enum ModuleStatus {
  active,
  setupRequired,
  locked,
  inactive,
}

class SystemsHubLogic {
  static bool isCycleVisible(String gender) {
    return CyclePrivacyGuard.isVisible({'user_gender': gender});
  }

  static ModuleStatus determineReligionStatus(bool enabled, String? cityId) {
    if (!enabled) return ModuleStatus.inactive;
    final configured = cityId != null && cityId.isNotEmpty && cityId != 'UNSET';
    return configured ? ModuleStatus.active : ModuleStatus.setupRequired;
  }

  static ModuleStatus determineKonkurStatus(bool enabled, bool hasSubjects) {
    if (!enabled) return ModuleStatus.inactive;
    return hasSubjects ? ModuleStatus.active : ModuleStatus.setupRequired;
  }

  static ModuleStatus determineGenericStatus(bool enabled) {
    return enabled ? ModuleStatus.active : ModuleStatus.inactive;
  }
}
