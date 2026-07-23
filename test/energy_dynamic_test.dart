import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';

void main() {
  group('Energy Dynamic Calculation Tests', () {
    test('Default base energy is applied when no manual logs are present', () {
      final explanations = <String>[];
      final percent = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'MEDIUM',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 18), // 18:00 (Circadian: 0%)
        sleepDiagList: [],
        recentCompletions: [],
        explanationList: explanations,
      );

      expect(percent, 60.0);
      expect(explanations, contains(contains('سطح پایه پیش‌فرض: 60٪')));
      expect(explanations, contains(contains('ساعت زیستی (تثبیت غروب): ۰٪')));
    });

    test('Manual base energy is applied when manual log is present', () {
      final explanations = <String>[];
      final now = DateTime(2026, 6, 22, 18);
      final percent = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'HIGH',
        lastManualTime: now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch, // 15 mins ago (no decay)
        validityMinutes: 180,
        now: now,
        sleepDiagList: [],
        recentCompletions: [],
        explanationList: explanations,
      );

      expect(percent, 90.0);
      expect(explanations, contains(contains('سطح پایه ثبت دستی: 90٪')));
      expect(explanations, contains(contains('وزن ثبت دستی: ۱۰۰٪')));
    });

    test('Sleep modifier penalty is applied for poor sleep', () {
      final explanations = <String>[];
      final percent = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'MEDIUM',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 18), // 18:00 (Circadian: 0%)
        sleepDiagList: [
          {'reason': 'Late sleep due to exam prep', 'note': 'restless sleep', 'createdAt': DateTime.now().millisecondsSinceEpoch}
        ],
        recentCompletions: [],
        explanationList: explanations,
      );

      expect(percent, 45.0); // 60 (base) - 15 (sleep penalty)
      expect(explanations, contains(contains('جریمه کیفیت خواب ضعیف: ۱۵٪-')));
    });

    test('Circadian rhythm modifications are applied correctly at peak and dip hours', () {
      // Morning Peak (9:00 - 12:00) -> +15%
      final explanationsPeak = <String>[];
      final percentPeak = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'MEDIUM',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 10), // 10:00 AM
        sleepDiagList: [],
        recentCompletions: [],
        explanationList: explanationsPeak,
      );
      expect(percentPeak, 75.0); // 60 + 15
      expect(explanationsPeak, contains(contains('ساعت زیستی (اوج صبحگاهی): ۱۵٪+')));

      // Afternoon Dip (12:00 - 15:00) -> -10%
      final explanationsDip = <String>[];
      final percentDip = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'MEDIUM',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 13), // 13:00
        sleepDiagList: [],
        recentCompletions: [],
        explanationList: explanationsDip,
      );
      expect(percentDip, 50.0); // 60 - 10
      expect(explanationsDip, contains(contains('ساعت زیستی (افت بعد از ظهر): ۱۰٪-')));
    });

    test('Recent activity completions modify energy correctly', () {
      final explanations = <String>[];
      final percent = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'MEDIUM',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 18), // 18:00
        sleepDiagList: [],
        recentCompletions: [
          {'resultType': 'FULL', 'category': 'fitness'}, // +5%
          {'resultType': 'FULL', 'category': 'work'},    // -3%
          {'resultType': 'SNOOZED', 'category': 'personal'}, // -5%
        ],
        explanationList: explanations,
      );

      // 60 (base) + 5 (fitness) - 3 (work) - 5 (missed) = 57
      expect(percent, 57.0);
      expect(explanations, contains(contains('تقویت انرژی (ورزش اخیر): 5٪+')));
      expect(explanations, contains(contains('خستگی کار/تحصیل اخیر: 3٪-')));
      expect(explanations, contains(contains('جریمه روتین‌های معوق/از دست رفته: 5٪-')));
    });

    test('Time decay correctly interpolates manual log towards baseline', () {
      final explanations = <String>[];
      final now = DateTime(2026, 6, 22, 18);
      final lastManualTime = now.subtract(const Duration(minutes: 105)).millisecondsSinceEpoch; // halfway decay (30 + 75 min out of 180)
      
      // Manual base: HIGH (90%)
      // Circadian: 0%
      // Sleep Penalty: 0%
      // Default base: 80% (baseline is 80% + 0%)
      // Manual Total is 90% + 0% = 90%
      // At 105 mins, weight is 1 - (105-30)/(180-30) = 1 - 75/150 = 50%
      // Expected = 0.5 * 90% + 0.5 * 80% = 85%
      
      final percent = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'HIGH',
        lastManualTime: lastManualTime,
        validityMinutes: 180,
        now: now,
        sleepDiagList: [],
        recentCompletions: [],
        explanationList: explanations,
      );

      expect(percent, 85.0);
      expect(explanations, contains(contains('وزن‌دهی زوال ثبت دستی: سپری شده 105 دقیقه (وزن اثر: 50٪)')));
    });

    test('Final energy is clamped within 10% and 100%', () {
      // Check lower bound
      final explanationsLow = <String>[];
      final percentLow = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'LOW',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 2), // 02:00 AM (Circadian: -30%)
        sleepDiagList: [
          {'reason': 'Poor', 'note': 'poor', 'createdAt': DateTime.now().millisecondsSinceEpoch} // -15%
        ],
        recentCompletions: [
          {'resultType': 'SNOOZED', 'category': 'personal'}, // -5%
          {'resultType': 'SNOOZED', 'category': 'work'}, // -5%
          {'resultType': 'SNOOZED', 'category': 'fitness'}, // -5%
        ],
        explanationList: explanationsLow,
      );
      // 40 (default low base) - 30 (circadian) - 15 (sleep penalty) - 15 (activity missed) = -20% -> clamped to 10%
      expect(percentLow, 10.0);

      // Check upper bound
      final explanationsHigh = <String>[];
      final percentHigh = EnergyAnalyticsEngine.calculateDynamicEnergy(
        baseLevel: 'HIGH',
        lastManualTime: null,
        validityMinutes: 180,
        now: DateTime(2026, 6, 22, 10), // 10:00 AM (Circadian: +15%)
        sleepDiagList: [],
        recentCompletions: [
          {'resultType': 'FULL', 'category': 'fitness'}, // +5%
          {'resultType': 'FULL', 'category': 'fitness'}, // +5%
          {'resultType': 'FULL', 'category': 'fitness'}, // +5%
          {'resultType': 'FULL', 'category': 'fitness'}, // +5% (capped to +15% total)
        ],
        explanationList: explanationsHigh,
      );
      // 80 (default high base) + 15 (circadian) + 15 (activity fitness) = 110% -> clamped to 100%
      expect(percentHigh, 100.0);
    });
  });
}
