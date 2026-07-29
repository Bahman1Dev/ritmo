import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no raw routine write (insert/update/delete) outside execution handlers', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final allowedPaths = [
      'lib/core/domain/execution/handlers/create_routine_handler.dart',
      'lib/core/domain/execution/handlers/edit_routine_handler.dart',
      'lib/core/domain/execution/handlers/delete_routine_handler.dart',
      'lib/core/domain/execution/handlers/archive_routine_handler.dart',
      'lib/core/domain/execution/handlers/complete_occurrence_handler.dart',
      'lib/core/database/seed/mock_data_seeder.dart',
      'lib/core/database/migration/migrations_registry.dart',
      'lib/core/services/module_management_service.dart',
      'lib/core/services/account_reset_service.dart',
    ];

    final violations = <String>[];

    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (allowedPaths.any((allowed) => normalizedPath.endsWith(allowed))) {
        continue;
      }

      final content = file.readAsStringSync();

      // Check for raw delete or update or insert on routines table
      final hasRawDelete = content.contains("delete('routines'") ||
          content.contains('delete("routines"') ||
          content.contains("DELETE FROM routines");

      final hasRawUpdate = content.contains("update('routines'") ||
          content.contains('update("routines"');

      final hasRawInsert = content.contains("insert('routines'") ||
          content.contains('insert("routines"');

      if (hasRawDelete || hasRawUpdate || hasRawInsert) {
        violations.add(normalizedPath);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Found raw routine writes in: $violations. All routine mutations MUST go through RitmoExecutionKernel commands.',
    );
  });
}
