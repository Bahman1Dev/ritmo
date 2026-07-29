import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prompt 036 - Source Guard Tests (WU-36)', () {
    test('ritmo_sheet_scaffold.dart exists and provides unified modal entry', () {
      final file = File('lib/core/ux/ritmo_sheet_scaffold.dart');
      expect(file.existsSync(), isTrue, reason: 'RitmoSheetScaffold primitive must exist');
    });

    test('no_silent_catch_test verifies no raw catch (_) {} in newly added files', () {
      final filesToCheck = [
        'lib/core/ux/ritmo_sheet_scaffold.dart',
        'lib/core/widgets/action/ritmo_action_sheet.dart',
        'lib/core/widgets/sheet/ritmo_picker_sheet.dart',
        'lib/core/widgets/sheet/ritmo_form_sheet.dart',
      ];

      for (final path in filesToCheck) {
        final file = File(path);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          expect(
            content.contains('catch (_) {}'),
            isFalse,
            reason: 'Silent catch prohibited in $path',
          );
        }
      }
    });

    test('no_callback_sheets_guard_test verifies ActionBody does not take on... Function callbacks', () {
      final file = File('lib/core/widgets/action/action_sheet_registry.dart');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(content.contains('Function('), isFalse);
      }
    });
  });
}
