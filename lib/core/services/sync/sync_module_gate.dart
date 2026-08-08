import 'package:ritmo/core/domain/models.dart';

class SyncModuleGate {
  static bool isModuleEnabled(Category category, Map<String, String> settings) {
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
      default:
        return true;
    }
  }
}
