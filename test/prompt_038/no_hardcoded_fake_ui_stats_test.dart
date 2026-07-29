import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation widgets contain no hardcoded fake trend percentages', () {
    final dir = Directory('lib');
    final presentationFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/presentation/'))
        .toList();

    final fakePatterns = [
      RegExp(r"'\+\d+%'"),
      RegExp(r'"\+\d+%"'),
      RegExp(r"'\+12%'"),
    ];

    for (final file in presentationFiles) {
      final content = file.readAsStringSync();
      for (final pattern in fakePatterns) {
        expect(
          pattern.hasMatch(content),
          isFalse,
          reason: 'Hardcoded fake stat pattern found in ${file.path}',
        );
      }
    }
  });
}
