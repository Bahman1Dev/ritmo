import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Single Writer Guard Test for active_timers (Section 5)', () {
    test('No file other than ritmo_timer_service.dart writes directly to active_timers', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final allowedWriterFiles = [
        'ritmo_timer_service.dart',
        'system_tables.dart',
        'migrations_registry.dart',
      ];

      final violations = <String>[];

      final writeRegex = RegExp(r"active_timers.*(?:insert|update|delete)|(?:insert|update|delete).*active_timers");

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final filename = entity.path.split(Platform.pathSeparator).last;
          if (allowedWriterFiles.contains(filename)) continue;

          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (writeRegex.hasMatch(lines[i])) {
              violations.add('${entity.path}:${i + 1} performs direct DB write on active_timers table: "${lines[i].trim()}"');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found unauthorized active_timers table writers:\n${violations.join('\n')}');
    });
  });
}
