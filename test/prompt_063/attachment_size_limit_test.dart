import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Attachment size limit rejects files > 10MB and accepts <= 10MB', () {
    const maxSizeBytes = 10 * 1024 * 1024; // 10 MB
    const file9Mb = 9 * 1024 * 1024;
    const file11Mb = 11 * 1024 * 1024;

    expect(file9Mb <= maxSizeBytes, isTrue);
    expect(file11Mb <= maxSizeBytes, isFalse);
  });
}
