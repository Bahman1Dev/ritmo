import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Worship Hero Architectural Guards (Prompt 052 §14.2)', () {
    test('G-1: No Timer.periodic in worship presentation layer', () {
      final dir = Directory('lib/features/worship/presentation');
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true).whereType<File>();
        for (final file in files) {
          if (file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            expect(content.contains('Timer.periodic'), isFalse,
                reason: 'Timer.periodic found in ${file.path}');
          }
        }
      }
    });

    test('G-2: No DatabaseHelper or raw SQL in worship presentation layer', () {
      final dir = Directory('lib/features/worship/presentation');
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true).whereType<File>();
        for (final file in files) {
          if (file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            expect(content.contains('DatabaseHelper') || content.contains('rawQuery'), isFalse,
                reason: 'Database query found in presentation layer ${file.path}');
          }
        }
      }
    });

    test('G-3: Locked geometry values present in prayer_arc_hero.dart', () {
      final file = File('lib/features/worship/presentation/widgets/prayer_arc_hero.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('210'), isTrue, reason: 'Hub width/height 210 constraint missing');
      expect(content.contains('54.0'), isTrue, reason: 'Circle diameter 54.0 constraint missing');
      expect(content.contains('3.5'), isTrue, reason: 'Orbit strokeWidth 3.5 constraint missing');
    });

    test('G-4: No context.colors used for sky palette in prayer_arc_hero.dart', () {
      final file = File('lib/features/worship/presentation/widgets/prayer_arc_hero.dart');
      final content = file.readAsStringSync();
      expect(content.contains('context.colors'), isFalse,
          reason: 'context.colors found in prayer_arc_hero.dart (Constraint 2 violation)');
    });

    test('G-5: Dead prayer_times_hero.dart does not exist', () {
      final deadFile = File('lib/features/worship/presentation/widgets/prayer_times_hero.dart');
      expect(deadFile.existsSync(), isFalse);
    });

    test('G-6: No deprecated withOpacity in lib/features/worship/', () {
      final dir = Directory('lib/features/worship');
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true).whereType<File>();
        for (final file in files) {
          if (file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            expect(content.contains('.withOpacity('), isFalse,
                reason: 'withOpacity found in ${file.path}');
          }
        }
      }
    });
  });
}
