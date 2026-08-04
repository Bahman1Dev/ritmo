import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GLOSSARY Terminology Guard Test (F-14)', () {
    test('UI strings do not contain banned terms from GLOSSARY.md', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final bannedTerms = <String, String>{
        'استریک': 'استمرار',
        'نوتیفیکیشن': 'یادآور / پیام',
      };

      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          for (final entry in bannedTerms.entries) {
            if (content.contains(entry.key)) {
              violations.add('${entity.path}: contains banned term "${entry.key}" (use "${entry.value}")');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found terminology violations:\n${violations.join('\n')}');
    });
  });
}
