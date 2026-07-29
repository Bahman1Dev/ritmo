import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Native Channel Contract Parity Tests', () {
    late File dartContractFile;
    late File kotlinContractFile;

    setUpAll(() {
      dartContractFile = File('lib/core/platform/native_channel_contract.dart');
      kotlinContractFile = File('android/app/src/main/kotlin/ir/ritmo/app/NativeChannelContract.kt');
    });

    test('both contract files exist', () {
      expect(dartContractFile.existsSync(), isTrue, reason: 'Dart contract file missing!');
      expect(kotlinContractFile.existsSync(), isTrue, reason: 'Kotlin contract file missing!');
    });

    test('channel names and method constants match 100% between Dart and Kotlin', () {
      final dartContent = dartContractFile.readAsStringSync();
      final kotlinContent = kotlinContractFile.readAsStringSync();

      // Extract string constants from Dart contract file
      final dartConstants = _extractStringConstants(dartContent);
      final kotlinConstants = _extractStringConstants(kotlinContent);

      expect(dartConstants, isNotEmpty);
      expect(kotlinConstants, isNotEmpty);

      // Check Dart constants exist in Kotlin
      for (final entry in dartConstants.entries) {
        expect(
          kotlinConstants.containsValue(entry.value),
          isTrue,
          reason: 'Channel contract mismatch! Constant "${entry.key}" with value "${entry.value}" exists in Dart (native_channel_contract.dart) but NOT in Kotlin (NativeChannelContract.kt).',
        );
      }

      // Check Kotlin constants exist in Dart
      for (final entry in kotlinConstants.entries) {
        expect(
          dartConstants.containsValue(entry.value),
          isTrue,
          reason: 'Channel contract mismatch! Constant "${entry.key}" with value "${entry.value}" exists in Kotlin (NativeChannelContract.kt) but NOT in Dart (native_channel_contract.dart).',
        );
      }
    });
  });
}

Map<String, String> _extractStringConstants(String content) {
  final map = <String, String>{};
  final regExp = RegExp(r"static\s+const\s+(\w+)\s*=\s*'([^']+)'|const\s+val\s+(\w+)\s*=\s*([^\s\n]+)");

  for (final match in regExp.allMatches(content)) {
    final dartName = match.group(1);
    final dartVal = match.group(2);
    final ktName = match.group(3);
    final ktVal = match.group(4)?.replaceAll('"', '');

    if (dartName != null && dartVal != null) {
      map[dartName] = dartVal;
    } else if (ktName != null && ktVal != null) {
      map[ktName] = ktVal;
    }
  }

  return map;
}
