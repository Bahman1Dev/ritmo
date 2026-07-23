import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class ActiveCoursesSection extends StatelessWidget {

  const ActiveCoursesSection({
    super.key,
    required this.courses,
    required this.courseSessionsMap,
    required this.onCourseTap,
  });
  final List<Course> courses;
  final Map<String, List<CourseSession>> courseSessionsMap;
  final Function(Course) onCourseTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Text(
                '📚 هنوز دوره‌ای تعریف نکرده‌اید.',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'با زدن دکمه «+» اولین دوره مطالعاتی خود را شروع کنید!',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دوره‌های در حال یادگیری',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final sessions = courseSessionsMap[course.id] ?? [];

            final completedCount = sessions.where((s) => s.isCompleted).length;
            final progress = course.totalSessions > 0
                ? (completedCount / course.totalSessions).clamp(0.0, 1.0)
                : 0.0;
            final progressPercent = (progress * 100).round();

            final behindCount = CourseScheduler.daysBehind(
              sessions: sessions,
              today: DateTime.now(),
            );

            final isPaused = course.status == CourseStatus.paused;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: RitmoTheme.glassCardLight(
                borderRadius: 20,
                color: isDarkMode
                    ? colors.card.withValues(alpha: 0.55)
                    : colors.card.withValues(alpha: 0.8),
                child: InkWell(
                  onTap: () => onCourseTap(course),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  course.emojiResolved,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  course.title,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (isPaused)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.textSecondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'متوقف‌شده',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              )
                            else if (behindCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.clock_fill, size: 10, color: colors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${toPersianDigits(behindCount)} جلسه عقب، جبران می‌کنی 💪',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: colors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.check_mark_circled_solid, size: 10, color: colors.success),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'روی برنامه',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff10A37F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'پیشرفت: ${toPersianDigits(completedCount)} از ${toPersianDigits(course.totalSessions)} ${course.unitLabelResolved}',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '${toPersianDigits(progressPercent)}٪',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: colors.border.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (course.colorHex != null)
                                  ? Color(int.parse('0xff${course.colorHex}'))
                                  : colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
