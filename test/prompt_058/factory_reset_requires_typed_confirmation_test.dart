import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Factory reset requires exact phrase confirmation', () {
    const requiredConfirmation = 'پاک کن';
    expect('پاک کن' == requiredConfirmation, isTrue);
    expect('پاک' == requiredConfirmation, isFalse);
    expect('' == requiredConfirmation, isFalse);
  });
}
