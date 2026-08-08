import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v78_settings_profile.dart';

void main() {
  test('MigrationV78SettingsProfile specifies version 78', () {
    final migration = MigrationV78SettingsProfile();
    expect(migration.version, equals(78));
  });
}
