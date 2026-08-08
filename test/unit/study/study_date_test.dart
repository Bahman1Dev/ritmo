import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/study/domain/study_stats.dart';

void main() {
  group('StudyDate Jalali Relative Formatter Tests', () {
    test('Formats null or empty date as ثبت نشده', () {
      expect(StudyDate.formatRelative(null), equals('ثبت نشده'));
      expect(StudyDate.formatRelative(''), equals('ثبت نشده'));
    });

    test('Formats today ISO date as امروز', () {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(StudyDate.formatRelative(todayStr), equals('امروز'));
    });

    test('Formats yesterday ISO date as دیروز', () {
      final yestStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      expect(StudyDate.formatRelative(yestStr), equals('دیروز'));
    });

    test('Formats 3 days ago as ۳ روز پیش', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
      expect(StudyDate.formatRelative(threeDaysAgo), equals('۳ روز پیش'));
    });
  });
}
