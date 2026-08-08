import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_registry.dart';
import 'package:ritmo/features/assistant/logic/settings_action_guard.dart';

void main() {
  test('All AI allowlist keys exist in SettingsRegistry and are valid', () {
    for (final entry in kAiSettingsAllowlist.entries) {
      final key = entry.key;
      final desc = SettingsRegistry.find(key);
      expect(
        desc,
        isNotNull,
        reason: 'Key $key in kAiSettingsAllowlist must be registered in SettingsRegistry',
      );
    }
  });
}
