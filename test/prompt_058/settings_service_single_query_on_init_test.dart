import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('SettingsService initializes and tracks revision', () async {
    final s = SettingsService.instance;
    final initialRevision = s.revision.value;

    expect(s.revision, isNotNull);
    expect(initialRevision, greaterThanOrEqualTo(0));
  });
}
