import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('Cycle PIN is independent from App PIN', () async {
    final s = SettingsService.instance;
    await SecureKeyStore.setKey('app_lock_password', '1234');
    await SecureKeyStore.setKey('cycle_lock_password', '5678');

    final appPin = await SecureKeyStore.getKey('app_lock_password');
    final cyclePin = await SecureKeyStore.getKey('cycle_lock_password');

    expect(appPin, equals('1234'));
    expect(cyclePin, equals('5678'));
    expect(appPin, isNot(equals(cyclePin)));
  });
}
