import 'package:ritmo/features/courses/models/course_models.dart';

class CourseValidationException implements Exception {
  CourseValidationException(this.code, this.messageFa);

  final String code;
  final String messageFa;

  @override
  String toString() => 'CourseValidationException($code): $messageFa';
}

class CourseValidator {
  static void validateCourse(Course c) {
    final title = c.title.trim();
    if (title.isEmpty) {
      throw CourseValidationException('INVALID_TITLE', 'عنوان دوره نمی‌تواند خالی باشد.');
    }
    if (title.length > 120) {
      throw CourseValidationException('TITLE_TOO_LONG', 'عنوان دوره نمی‌تواند بیش از ۱۲۰ کاراکتر باشد.');
    }
    if (c.totalSessions < 1 || c.totalSessions > 500) {
      throw CourseValidationException('INVALID_TOTAL_SESSIONS', 'تعداد جلسات باید بین ۱ تا ۵۰۰ باشد.');
    }
    if (c.sessionDurationMinutes < 1 || c.sessionDurationMinutes > 600) {
      throw CourseValidationException('INVALID_DURATION', 'مدت زمان هر جلسه باید بین ۱ تا ۶۰۰ دقیقه باشد.');
    }
    if (c.weeklyTargetSessions < 1 || c.weeklyTargetSessions > 21) {
      throw CourseValidationException('INVALID_WEEKLY_TARGET', 'هدف هفتگی باید بین ۱ تا ۲۱ جلسه باشد.');
    }

    if (c.reminderEnabled) {
      if (c.preferredTime == null || c.preferredTime!.trim().isEmpty) {
        throw CourseValidationException('INVALID_REMINDER_TIME', 'برای فعال‌سازی یادآور، زمان یادآوری باید مشخص شود.');
      }
      final parts = c.preferredTime!.split(':');
      if (parts.length != 2) {
        throw CourseValidationException('INVALID_REMINDER_TIME', 'فرمت زمان یادآوری باید HH:mm باشد.');
      }
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
        throw CourseValidationException('INVALID_REMINDER_TIME', 'ساعت یا دقیقه یادآوری نامعتبر است.');
      }
    }
  }

  static List<int> normalizePreferredDays(List<int> days) {
    final valid = days.where((d) => d >= 0 && d <= 6).toSet().toList()..sort();
    if (valid.isEmpty) {
      return [6, 1, 3]; // Default: Saturday, Monday, Wednesday
    }
    return valid;
  }
}
