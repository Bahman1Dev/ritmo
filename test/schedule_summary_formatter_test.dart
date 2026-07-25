import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/registry/presentation/utils/schedule_summary_formatter.dart';

void main() {
  group('ScheduleSummaryFormatter Tests', () {
    test('formats all 7 days as هر روز', () {
      final summary = ScheduleSummaryFormatter.format(
        daysOfWeekStr: '6,7,1,2,3,4,5',
      );
      expect(summary, contains('هر روز'));
    });

    test('formats Saturday to Wednesday (6,7,1,2,3) as شنبه تا چهارشنبه', () {
      final summary = ScheduleSummaryFormatter.format(
        daysOfWeekStr: '6,7,1,2,3',
      );
      expect(summary, contains('شنبه تا چهارشنبه'));
    });

    test('formats null/empty as بدون زمان‌بندی', () {
      final summary = ScheduleSummaryFormatter.format();
      expect(summary, 'بدون زمان‌بندی');
    });
  });
}
