import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/registry/domain/delete_impact_report.dart';

void main() {
  group('DeleteImpactReport Tests', () {
    test('toFaSentence formats completions, streak, reminders and dependents correctly', () {
      const report = DeleteImpactReport(
        completionCount: 42,
        occurrenceCount: 5,
        activeReminderCount: 3,
        longestStreakDays: 12,
        orphanedDependents: ['گام هدف: مطالعه کنکور'],
      );

      final sentence = report.toFaSentence();
      expect(sentence, contains('۴۲ ثبت انجام'));
      expect(sentence, contains('زنجیرهٔ ۱۲ روزه'));
      expect(sentence, contains('۳ یادآور فعال'));
      expect(sentence, contains('۱ مورد وابسته بی‌سرپرست می‌شود'));
    });
  });
}
