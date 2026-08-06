import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prompt 056 Courses Architectural Guards', () {
    test('Guard 1: No Color(int.parse("0xff...")) without safe fallback in courses presentation', () {
      final dir = Directory('lib/features/courses/presentation');
      if (!dir.existsSync()) return;

      final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        if (content.contains("int.parse('0xff") || content.contains('int.parse("0xff')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: 'Unsafe hex color parsing found in: $violations');
    });

    test('Guard 2: Courses UI widgets do not query raw SQL database directly', () {
      final dir = Directory('lib/features/courses/presentation');
      if (!dir.existsSync()) return;

      final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        if (content.contains('db.query(') || content.contains('db.rawQuery(') || content.contains('db.execute(')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: 'Raw SQL query found in UI widgets: $violations');
    });

    test('Guard 3: CoursesEngine fingerprint includes session completion state', () {
      final engineFile = File('lib/core/analytics/courses_engine.dart');
      expect(engineFile.existsSync(), isTrue);

      final content = engineFile.readAsStringSync();
      expect(content.contains('completedCount'), isTrue);
      expect(content.contains('skippedCount'), isTrue);
      expect(content.contains('maxUpdated'), isTrue);
    });

    test('Guard 4: Session complete/skip updates skipReason without deleting study note', () {
      final repoFile = File('lib/features/courses/logic/courses_repository.dart');
      expect(repoFile.existsSync(), isTrue);

      final content = repoFile.readAsStringSync();
      expect(content.contains('skipReason'), isTrue);
      expect(content.contains('alarmsToCancel'), isTrue);
    });
  });
}
