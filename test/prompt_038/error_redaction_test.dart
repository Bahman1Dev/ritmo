import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/diagnostics/privacy_error_sink.dart';

void main() {
  group('PrivacyErrorSink Redaction Tests', () {
    test('redacts sensitive user health and personal note fields', () {
      final rawError = 'Crash while parsing title: قرص آسپرین روزانه and note: یادداشت محرمانه سلامتی';

      final redacted = PrivacyErrorSink.redact(rawError);

      expect(redacted.contains('قرص آسپرین روزانه'), isFalse);
      expect(redacted.contains('یادداشت محرمانه سلامتی'), isFalse);
      expect(redacted, contains('[REDACTED]'));
    });
  });
}
