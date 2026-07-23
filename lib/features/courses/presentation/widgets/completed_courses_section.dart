import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class CompletedCoursesSection extends StatelessWidget {

  const CompletedCoursesSection({
    super.key,
    required this.completedCourses,
    required this.courseSessionsMap,
    required this.onRefresh,
  });
  final List<Course> completedCourses;
  final Map<String, List<CourseSession>> courseSessionsMap;
  final VoidCallback onRefresh;

  Future<void> _restoreCourse(BuildContext context, Course course) async {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xff12141C) : Colors.white,
          title: const Text(
            'بازیابی دوره',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'آیا می‌خواهید دوره "${course.title}" را مجدداً به وضعیت فعال بازگردانید تا جلسات آن را پیگیری کنید؟',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: const Text('بازیابی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm ?? false) {
      await CoursesRepository.instance.updateCourseStatus(course.id, CourseStatus.active);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('دوره "${course.title}" دوباره فعال شد. 📚'),
            backgroundColor: colors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (completedCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دوره‌های تکمیل‌شده (تالار افتخارات)',
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
          itemCount: completedCourses.length,
          itemBuilder: (context, index) {
            final course = completedCourses[index];
            final sessions = courseSessionsMap[course.id] ?? [];
            final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s.actualDurationMinutes ?? 0));

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: RitmoTheme.glassCardLight(
                borderRadius: 20,
                color: isDarkMode
                    ? colors.card.withValues(alpha: 0.35)
                    : colors.card.withValues(alpha: 0.5),
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
                                  color: colors.textPrimary.withValues(alpha: 0.8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xff10A37F).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xff10A37F), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'تکمیل‌شده 🏆',
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعداد کل جلسات: ${toPersianDigits(course.totalSessions)} جلسه',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'مدت کل زمان مطالعه: ${toPersianDigits(totalMinutes)} دقیقه',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _restoreCourse(context, course),
                            icon: const Icon(CupertinoIcons.refresh, size: 14),
                            label: const Text(
                              'بازیابی دوره',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
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
