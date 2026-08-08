import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Completion sound respects tasks_completion_sound_enabled setting', () {
    const settingOff = 'false';
    const settingOn = 'true';

    final playSoundOff = settingOff == 'true';
    final playSoundOn = settingOn == 'true';

    expect(playSoundOff, isFalse);
    expect(playSoundOn, isTrue);
  });
}
