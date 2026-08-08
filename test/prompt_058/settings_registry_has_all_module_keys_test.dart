import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/modules/module_registry.dart';
import 'package:ritmo/core/settings/settings_registry.dart';

void main() {
  test('SettingsRegistry registers all ModuleRegistry module keys', () {
    for (final mod in ModuleRegistry.modules) {
      final desc = SettingsRegistry.find(mod.key);
      expect(desc, isNotNull, reason: 'Module key ${mod.key} must exist in SettingsRegistry');
      expect(desc!.type, equals(SettingType.boolean));
      expect(desc.group, equals(SettingsGroup.modules));
    }
  });
}
