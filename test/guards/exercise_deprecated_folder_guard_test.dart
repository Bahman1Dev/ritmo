import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Deprecated Exercise/Sports Module Guards', () {
    test('lib/features/sports folder does NOT exist physically', () {
      final oldSportsFolder = Directory('lib/features/sports');
      expect(
        oldSportsFolder.existsSync(),
        isFalse,
        reason: 'The deprecated lib/features/sports directory must be completely removed.',
      );
    });

    test('No dart file imports from package:ritmo/features/sports', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final offendingFiles = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('package:ritmo/features/sports')) {
          offendingFiles.add(file.path);
        }
      }

      expect(
        offendingFiles,
        isEmpty,
        reason: 'No files should import from the deprecated package:ritmo/features/sports. Offending files: $offendingFiles',
      );
    });
  });
}
