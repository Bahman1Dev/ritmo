import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/core/ai/ai_shared_rules.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';

void main() {
  group('AI Prompts Upgrade - Unit Tests', () {
    test('Task 1: Shared Core Analytical Rules exist and contain key elements', () {
      expect(AnalyticsPromptRules.core, isNotEmpty);
      expect(AnalyticsPromptRules.core, contains('Farsi'));
      expect(AnalyticsPromptRules.core, contains('STRICTLY NO CAUSAL LANGUAGE'));
      expect(AnalyticsPromptRules.core, contains('STRICTLY NO MEDICAL INTERPRETATION'));
      expect(AnalyticsPromptRules.core, contains('NO cycle/menstrual/pregnancy/hormonal concepts'));
      expect(AnalyticsPromptRules.core, contains('evidence_level'));
    });

    test('Task 6: AIResponseProcessor.processRawJson parses and strips fences correctly', () {
      const rawWithFences = '''
```json
{
  "key1": "value1",
  "key2": 42
}
```
''';
      final parsed = AIResponseProcessor.processRawJson(rawWithFences);
      expect(parsed, isNotNull);
      expect(parsed!['key1'], equals('value1'));
      expect(parsed['key2'], equals(42));

      // Test with plain JSON
      const plainJson = '{"foo": "bar"}';
      final parsedPlain = AIResponseProcessor.processRawJson(plainJson);
      expect(parsedPlain, isNotNull);
      expect(parsedPlain!['foo'], equals('bar'));

      // Test with invalid JSON
      const invalidJson = '{"foo": }';
      final parsedInvalid = AIResponseProcessor.processRawJson(invalidJson);
      expect(parsedInvalid, isNull);
    });

    test('Task 2: EnergyAnalyticsEngine getFarsiWeekday mappings', () {
      expect(EnergyAnalyticsEngine.getFarsiWeekday(DateTime.saturday), equals('شنبه'));
      expect(EnergyAnalyticsEngine.getFarsiWeekday(DateTime.friday), equals('جمعه'));
      expect(EnergyAnalyticsEngine.getFarsiWeekday(DateTime.wednesday), equals('چهارشنبه'));
    });
  });
}
