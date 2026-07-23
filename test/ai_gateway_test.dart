import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/ai/ai_cache_manager.dart';
import 'package:ritmo/core/ai/ai_context_builder.dart';
import 'package:ritmo/core/ai/ai_fallback_engine.dart';
import 'package:ritmo/core/ai/ai_prompt_engine.dart';
import 'package:ritmo/core/ai/ai_rate_limiter.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';

void main() {
  group('Ritmo AI Gateway Layered Architecture Tests', () {

    test('Layer 5: Fallback Engine returns the exact policy fallback response', () {
      final fallback = AIFallbackEngine.getFallbackResponse();
      expect(fallback['response'], AIFallbackEngine.aiPolicyFallbackResponse);
      expect(fallback['evidence_level'], 'LOW');
      expect(fallback['used_data_categories'], isEmpty);
    });

    test('Layer 2: Context Builder detects cycle keywords and returns out_of_scope status', () async {
      // Test query containing forbidden Farsi cycle word
      final context1 = await AIContextBuilder.buildContext(
        query: 'چرخه قاعدگی من چگونه است؟',
        consent: const ConsentProfile(),
      );
      expect(context1['user_state']['status'], 'out_of_scope');
      expect(context1['relevant_data'], isEmpty);

      // Test query containing forbidden English cycle word
      final context2 = await AIContextBuilder.buildContext(
        query: 'tell me about my hormonal cycle patterns',
        consent: const ConsentProfile(),
      );
      expect(context2['user_state']['status'], 'out_of_scope');
      expect(context2['relevant_data'], isEmpty);
    });

    test('Layer 3: Prompt Engine constructs prompts with strict instructions', () {
      final systemPrompt = AIPromptEngine.buildSystemPrompt(PromptType.insight);
      expect(systemPrompt, contains('llama-3.1-8b' == 'llama-3.1-8b' ? 'type": "insight"' : ''));
      expect(systemPrompt, contains('routines'));
      expect(systemPrompt, contains('Absolutely NO menstrual, cycle, pregnancy, or hormonal keywords'));

      final userPrompt = AIPromptEngine.buildUserPrompt(
        query: 'انرژی امروز من چطور است؟',
        context: {'query': 'test', 'relevant_data': {}},
      );
      expect(userPrompt, contains('User Query: انرژی امروز من چطور است؟'));
      expect(userPrompt, contains('Context:'));
    });

    test('Layer 4: Response Processor validates output JSON schema', () {
      // Valid JSON output from LLM
      const rawLlmOutput = '''
```json
{
  "response": "امروز روتین‌ها با موفقیت سپری شد.",
  "type": "insight",
  "evidence_level": "HIGH",
  "used_data_categories": ["routines", "energy"],
  "query_scope": "narrow"
}
```
''';
      final processed = AIResponseProcessor.process(rawLlmOutput);
      expect(processed['response'], 'امروز روتین‌ها با موفقیت سپری شد.');
      expect(processed['evidence_level'], 'HIGH');
      expect(processed['used_data_categories'], containsAll(['routines', 'energy']));
    });

    test('Layer 4: Response Processor triggers fallback on cycle keyword leakage', () {
      // LLM trying to leak cycle/menstrual keyword (Rule 0)
      const rawLeakingLlmOutput = '''
{
  "response": "می‌توانم در مورد پریود شما نظر بدهم.",
  "type": "insight",
  "evidence_level": "HIGH",
  "used_data_categories": ["cycle"],
  "query_scope": "narrow"
}
''';
      final processed = AIResponseProcessor.process(rawLeakingLlmOutput);
      expect(processed['response'], AIFallbackEngine.aiPolicyFallbackResponse);
      expect(processed['evidence_level'], 'LOW');
      expect(processed['used_data_categories'], isEmpty);
    });

    test('Layer 6: Cache Manager caches and returns entries within TTL', () {
      final cacheManager = AICacheManager.instance;
      cacheManager.clear();

      const mockQuery = 'روتین‌های من چیست؟';
      final mockContext = {'query': mockQuery};
      final mockResponse = {'response': 'امروز ۵ روتین داری', 'evidence_level': 'HIGH'};

      // Should be null initially
      expect(cacheManager.get(mockQuery, mockContext), isNull);

      // Store and retrieve
      cacheManager.set(mockQuery, mockContext, mockResponse, ttlMinutes: 5);
      final cached = cacheManager.get(mockQuery, mockContext);
      expect(cached, isNotNull);
      expect(cached!['response'], 'امروز ۵ روتین داری');
    });

    test('Layer 7: Rate Limiter triggers limit when request count is exceeded', () {
      final rateLimiter = AIRateLimiter.instance;
      rateLimiter.reset();

      // Fire 20 requests (which is the limit per minute)
      for (var i = 0; i < 20; i++) {
        expect(rateLimiter.isRateLimited(), isFalse);
      }

      // 21st request must trigger rate limit
      expect(rateLimiter.isRateLimited(), isTrue);
    });

    group('QuickAddParser & Prompt Tests', () {
      test('QuickAddParser parses REMINDER with hourly interval', () {
        final result = QuickAddParser.parse('یادآور خوردن قرص هر ۸ ساعت');
        expect(result.itemType, 'REMINDER');
        expect(result.recurrenceType, 'INTERVAL_HOURS');
        expect(result.intervalHours, 8);
      });

      test('QuickAddParser parses TASK with time', () {
        final result = QuickAddParser.parse('کار جلسه کاری ساعت ۱۵:۳۰');
        expect(result.itemType, 'TASK');
        expect(result.timeOfDay?.hour, 15);
        expect(result.timeOfDay?.minute, 30);
      });

      test('QuickAddParser parses ROUTINE with weekdays', () {
        final result = QuickAddParser.parse('روال ورزش صبحگاهی شنبه و دوشنبه');
        expect(result.itemType, 'ROUTINE');
        expect(result.recurrenceType, 'CUSTOM_DAYS');
        expect(result.weekdays, containsAll([6, 1])); // Saturday=6, Monday=1
      });

      test('AIPromptEngine.buildQuickAddPrompt includes required rules', () {
        final prompt = AIPromptEngine.buildQuickAddPrompt('تست ورودی');
        expect(prompt, contains('Absolutely NO menstrual, cycle, pregnancy, or hormonal keywords'));
        expect(prompt, contains('ROUTINE'));
        expect(prompt, contains('REMINDER'));
        expect(prompt, contains('TASK'));
      });
    });

  });
}
