import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no inline recurrence jsonEncode with weekdays key outside routine_recurrence.dart', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final violations = <String>[];

    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      if (file.path.endsWith('routine_recurrence.dart')) continue;

      final content = file.readAsStringSync();
      if (content.contains("jsonEncode") && content.contains("'weekdays'")) {
        violations.add(file.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Found inline jsonEncode with weekdays in: $violations. Use encodeRecurrenceRule in routine_recurrence.dart instead.',
    );
  });
}
