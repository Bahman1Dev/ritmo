import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_registry.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('SettingsService returns defaultValue when key is missing or not yet in cache', () {
    final s = SettingsService.instance;
    final defaultUserName = s.get<String>('user_name');
    expect(defaultUserName, isNotEmpty);
    expect(defaultUserName, equals('بهمن'));

    final defaultMaster = s.get<bool>('notif_master_enabled');
    expect(defaultMaster, isTrue);

    final defaultCapacity = s.get<int>('daily_capacity_minutes');
    expect(defaultCapacity, equals(480));
  });
}
