import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linkify regex matches http, https, and www URLs in task notes', () {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)');
    const note = 'Check out https://ritmo.ir and www.google.com for details.';

    final matches = urlPattern.allMatches(note).map((m) => m.group(0)).toList();
    expect(matches, equals(['https://ritmo.ir', 'www.google.com']));
  });
}
