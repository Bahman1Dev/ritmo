import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';

void main() {
  group('PrivacyErrorSink Redaction Unit Tests', () {
    test('redacts health parameters cleanly', () {
      const raw = 'Log entry blood_sugar: 120 and systolic: 130 diastolic: 85';
      final sanitized = PrivacyErrorSink.sanitize(raw);
      expect(sanitized.contains('120'), isFalse);
      expect(sanitized.contains('130'), isFalse);
      expect(sanitized.contains('[REDACTED_HEALTH_DATA]'), isTrue);
    });

    test('redacts long Persian personal user text from log output', () {
      const raw = 'عامل خطای ثبت اطلاعات: برنامه روزانه من برای مطالعه و یادگیری در بعد از ظهر بسیار طولانی است و خسته شدم';
      final sanitized = PrivacyErrorSink.sanitize(raw);
      expect(sanitized.contains('[REDACTED_TEXT]'), isTrue);
    });
  });
}
