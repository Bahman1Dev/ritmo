import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/modules/module_registry.dart';
import 'package:ritmo/core/services/module_management_service.dart';

void main() {
  group('ModuleRegistry Unit Tests', () {
    test('ModuleRegistry contains core and optional descriptors', () {
      final modules = ModuleRegistry.modules;
      expect(modules.length, greaterThanOrEqualTo(10));

      final todayMod = ModuleRegistry.findByKey('module_today_routines');
      expect(todayMod, isNotNull);
      expect(todayMod!.isCore, isTrue);
      expect(todayMod.defaultEnabled, isTrue);

      final cycleMod = ModuleRegistry.findByKey('module_cycle_enabled');
      expect(cycleMod, isNotNull);
      expect(cycleMod!.canBeSuggested, isFalse); // §2.2: Cycle never auto-suggested
    });

    test('ModuleManagementService.allModuleKeys reflects ModuleRegistry', () {
      final keys = ModuleManagementService.allModuleKeys;
      expect(keys, contains('module_today_routines'));
      expect(keys, contains('module_study_enabled'));
      expect(keys, contains('module_goals_enabled'));
    });
  });
}
