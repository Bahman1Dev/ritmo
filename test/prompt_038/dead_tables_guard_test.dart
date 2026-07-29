import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/schema/schema_manager.dart';

void main() {
  test('all database schema tables createAll contract is defined', () {
    expect(SchemaManager.createAll, isNotNull);
  });
}
