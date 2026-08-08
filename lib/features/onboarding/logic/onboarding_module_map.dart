import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/features/onboarding/models/focus_area.dart';

class OnboardingModuleMap {
  const OnboardingModuleMap._();

  static const Map<FocusArea, List<String>> moduleSuggestions = {
    FocusArea.health: ['module_medicine_enabled'],
    FocusArea.sport: ['module_supplementary_sports_enabled'],
    FocusArea.study: ['module_study_enabled'],
    FocusArea.skill: ['module_courses_enabled'],
    FocusArea.work: ['module_goals_enabled'],
    FocusArea.income: ['module_goals_enabled'],
    FocusArea.worship: ['module_religion_enabled'],
    FocusArea.sleep: ['module_sleep_enabled'],
    FocusArea.stress: ['module_energy_enabled'],
    FocusArea.family: ['module_progressive_habits_enabled'],
  };

  /// Computes final module enable states map ensuring every canonical key in
  /// [ModuleManagementService.allModuleKeys] is explicitly populated ('true'|'false').
  static Map<String, String> resolveModuleStates({
    required Set<FocusArea> chosenAreas,
    required bool isFemale,
    bool enableCycle = false,
    bool canUseCourses = true,
  }) {
    final activeKeys = <String>{};

    for (final area in chosenAreas) {
      final keys = moduleSuggestions[area];
      if (keys != null) {
        activeKeys.addAll(keys);
      }
    }

    if (isFemale && enableCycle) {
      activeKeys.add('module_cycle_enabled');
    }

    // Default assistant to enabled
    activeKeys.add('module_assistant_enabled');

    final result = <String, String>{};
    for (final key in ModuleManagementService.allModuleKeys) {
      if (key == 'module_courses_enabled' && !canUseCourses) {
        result[key] = 'false';
      } else {
        result[key] = activeKeys.contains(key) ? 'true' : 'false';
      }
    }

    return result;
  }
}
