import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('Quiet hours settings are properly stored in cache and updated', () async {
    final s = SettingsService.instance;
    await s.set('notif_quiet_enabled', true);
    await s.set('notif_quiet_start', '23:30');
    await s.set('notif_quiet_end', '06:30');

    expect(s.get<bool>('notif_quiet_enabled'), isTrue);
    expect(s.get<String>('notif_quiet_start'), equals('23:30'));
    expect(s.get<String>('notif_quiet_end'), equals('06:30'));
  });
}
