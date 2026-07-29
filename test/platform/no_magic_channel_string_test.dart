import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no magic channel string literals matching com.ritmo.app/ outside contract files', () {
    final pattern = RegExp(r'''['"]com\.ritmo\.app\/[a-zA-Z0-9_]+['"]''');

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('native_channel_contract.dart'))
        .toList();

    final kotlinFiles = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.kt') && !f.path.contains('NativeChannelContract.kt'))
        .toList();

    for (final file in [...dartFiles, ...kotlinFiles]) {
      final content = file.readAsStringSync();
      final matches = pattern.allMatches(content);
      expect(
        matches.isEmpty,
        isTrue,
        reason: 'Magic channel string literal found in ${file.path}: ${matches.map((m) => m.group(0)).toList()}. All channel names must use NativeChannels constants.',
      );
    }
  });
}
