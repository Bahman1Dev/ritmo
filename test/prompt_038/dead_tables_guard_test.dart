import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/schema/schema_manager.dart';

void main() {
  test('all database schema tables have registered schemas and defined contracts', () {
    final tables = SchemaManager.getTables();
    expect(tables, isNotEmpty);

    for (final table in tables) {
      expect(table.name, isNotEmpty);
      expect(table.columns, isNotEmpty);
    }
  });
}
