import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/ai/ai_endpoint_normalizer.dart';

void main() {
  group('AiEndpointNormalizer Tests', () {
    test('https://api.openai.com/v1 -> https://api.openai.com/v1/chat/completions', () {
      expect(
        AiEndpointNormalizer.normalize('https://api.openai.com/v1'),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('https://api.openai.com/v1/ -> https://api.openai.com/v1/chat/completions', () {
      expect(
        AiEndpointNormalizer.normalize('https://api.openai.com/v1/'),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('api.groq.com -> https://api.groq.com/v1/chat/completions', () {
      expect(
        AiEndpointNormalizer.normalize('api.groq.com'),
        'https://api.groq.com/v1/chat/completions',
      );
    });

    test('https://open.bigmodel.cn/api/paas/v4/chat/completions -> unchanged', () {
      expect(
        AiEndpointNormalizer.normalize('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      );
    });

    test('https://x.com/v1 -> https://x.com/v1/chat/completions', () {
      expect(
        AiEndpointNormalizer.normalize('https://x.com/v1'),
        'https://x.com/v1/chat/completions',
      );
    });

    test('http://10.0.2.2:11434/v1 with allowHttp: true -> http://10.0.2.2:11434/v1/chat/completions', () {
      expect(
        AiEndpointNormalizer.normalize('http://10.0.2.2:11434/v1', allowHttp: true),
        'http://10.0.2.2:11434/v1/chat/completions',
      );
    });

    test('http://evil.com/v1 with allowHttp: false -> validate returns error', () {
      final err = AiEndpointNormalizer.validate('http://evil.com/v1', allowHttp: false);
      expect(err, isNotNull);
      expect(err, contains('فقط آدرس امن (https) پذیرفته می‌شود'));
    });

    test('empty string -> validate returns error', () {
      final err = AiEndpointNormalizer.validate('');
      expect(err, isNotNull);
      expect(err, contains('آدرس سرویس‌دهنده را وارد کنید'));
    });
  });
}
