import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every CachedEngine implementation has a unique class name', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final names = <String, String>{}; // className -> filePath
    final re = RegExp(r'class\s+(\w+)\s+implements\s+CachedEngine');
    for (final f in files) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        final name = m.group(1)!;
        expect(names.containsKey(name), isFalse,
            reason:
                'Duplicate engine class "$name" in ${f.path} and ${names[name]}');
        names[name] = f.path;
      }
    }
  });
}
