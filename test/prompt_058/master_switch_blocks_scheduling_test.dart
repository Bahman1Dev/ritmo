import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('Master switch setting notif_master_enabled can be toggled via SettingsService', () async {
    final s = SettingsService.instance;
    await s.set('notif_master_enabled', false);
    expect(s.get<bool>('notif_master_enabled'), isFalse);

    await s.set('notif_master_enabled', true);
    expect(s.get<bool>('notif_master_enabled'), isTrue);
  });
}
