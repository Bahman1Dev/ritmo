import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/observability/ritmo_logger.dart';

void main() {
  group('RitmoLogger & Redaction Tests (R-3)', () {
    test('redact replaces Persian text with [REDACTED_TEXT]', () {
      const rawText = 'عنوان روتین: مطالعه کتاب حافظ';
      final redacted = LogRedactor.redact(rawText);
      expect(redacted.contains('کتاب'), false);
      expect(redacted.contains('مطالعه'), false);
      expect(redacted.contains('[REDACTED_TEXT]'), true);
    });

    test('sanitizeContext redacts String values in context map', () {
      final context = {
        'routineId': 'rot_123',
        'title': 'پیاده‌روی صبحگاهی',
        'count': 5,
      };
      final clean = LogRedactor.sanitizeContext(context);
      expect(clean['routineId'], 'rot_123');
      expect((clean['title'] as String).contains('صبحگاهی'), false);
      expect(clean['count'], 5);
    });

    test('RingBufferLogSink records log lines without leaking sensitive Persian text', () {
      final sink = RingBufferLogSink(capacity: 10);
      sink.write(
        LogLevel.error,
        'خطا در ثبت روتین جدید',
        error: 'مقدار ورودی نامعتبر است',
        context: {'userNote': 'یادداشت شخصی محرمانه'},
      );

      final logs = sink.getLogs();
      expect(logs.length, 1);
      final logLine = logs.first;
      expect(logLine.contains('[ERROR]'), true);
      expect(logLine.contains('یادداشت'), false);
      expect(logLine.contains('[REDACTED_TEXT]'), true);
    });
  });
}
