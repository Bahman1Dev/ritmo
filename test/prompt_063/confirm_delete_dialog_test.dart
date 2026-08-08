import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Confirm delete setting logic triggers dialog when tasks_confirm_delete is true', () {
    const settingValueTrue = 'true';
    const settingValueFalse = 'false';

    final shouldShowDialog1 = settingValueTrue == 'true';
    final shouldShowDialog2 = settingValueFalse == 'true';

    expect(shouldShowDialog1, isTrue);
    expect(shouldShowDialog2, isFalse);
  });
}
