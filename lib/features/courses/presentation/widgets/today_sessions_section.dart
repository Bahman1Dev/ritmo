import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';
import 'package:ritmo/features/courses/presentation/widgets/study_timer_sheet.dart';

class TodaySessionsSection extends StatelessWidget {

  const TodaySessionsSection({
    super.key,
    required this.todaySessions,
    required this.courses,
    required this.currentEnergyLevel,
    required this.onRefresh,
  });
  final List<CourseSession> todaySessions;
  final List<Course> courses;
  final String currentEnergyLevel; // 'LOW', 'MEDIUM', 'HIGH'
  final VoidCallback onRefresh;

  Course? _getCourse(String courseId) {
    try {
      return courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  void _showTimer(BuildContext context, Course course, CourseSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StudyTimerSheet(
        course: course,
        session: session,
        onTimerFinished: onRefresh,
      ),
    );
  }

  Future<void> _completeDirectly(BuildContext context, Course course, CourseSession session) async {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final duration = course.sessionDurationMinutes;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xff12141C) : Colors.white,
          title: const Text(
            'تکمیل مستقیم جلسه',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'آیا می‌خواهید این جلسه را بدون اجرا کردن تایمر و با مدت پیش‌فرض ${toPersianDigits(duration)} دقیقه به عنوان تکمیل‌شده علامت بزنید؟',
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
              child: const Text('بله، تکمیل کن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm ?? false) {
      await CoursesRepository.instance.completeSession(
        sessionId: session.id,
        actualDurationMinutes: duration,
      );
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جلسه "${session.sessionTitle ?? 'مطالعه'}" تکمیل شد! 🎉'),
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

    if (todaySessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جلسات برنامه امروز شما',
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
          itemCount: todaySessions.length,
          itemBuilder: (context, index) {
            final session = todaySessions[index];
            final course = _getCourse(session.courseId);
            if (course == null) return const SizedBox.shrink();

            final energyRule = course.energyRule;
            final isLowEnergy = currentEnergyLevel == 'LOW';

            var isDimmed = false;
            var hideStartButton = false;
            String? energyWarning;
            var customDuration = course.sessionDurationMinutes;

            if (isLowEnergy) {
              if (energyRule == 'skip') {
                isDimmed = true;
                energyWarning = 'تراز انرژی شما پایین است؛ برای هماهنگی با ریتم بدنی پیشنهاد می‌شود امروز از این جلسه عبور کنید.';
              } else if (energyRule == 'offerLight') {
                customDuration = (course.sessionDurationMinutes / 2).ceil();
                energyWarning = 'تراز انرژی شما پایین است؛ پیشنهاد می‌کنیم این جلسه را کوتاه‌تر و سبک‌تر (به مدت ${toPersianDigits(customDuration)} دقیقه) انجام دهید 💪';
              } else if (energyRule == 'highEnergyOnly') {
                isDimmed = true;
                hideStartButton = true;
                energyWarning = 'این کار نیاز به تمرکز بالا دارد. زمان مناسب‌تری برای آن برنامه‌ریزی کنید.';
              }
            }

            return Opacity(
              opacity: isDimmed ? 0.6 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: RitmoTheme.glassCardLight(
                  borderRadius: 20,
                  color: isDarkMode
                      ? colors.card.withValues(alpha: 0.55)
                      : colors.card.withValues(alpha: 0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (course.colorHex != null)
                                    ? Color(int.parse('0xff${course.colorHex}')).withValues(alpha: 0.12)
                                    : const Color(0xff3B82F6).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                course.emojiResolved,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.title,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.sessionTitle ?? '${course.unitLabelResolved} ${session.sessionNumber}'} • مدت زمان: ${toPersianDigits(customDuration)} دقیقه',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (course.provider != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.textSecondary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  course.provider!,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 9,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (energyWarning != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.warning.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 14, color: colors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    energyWarning,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 10.5,
                                      color: colors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!hideStartButton) ...[
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _completeDirectly(context, course, session),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                ),
                                child: Text(
                                  'تکمیل مستقیم',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11.5,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Start timer with potential custom (light) duration
                                  _showTimer(
                                    context,
                                    course.copyWith(sessionDurationMinutes: customDuration),
                                    session,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(CupertinoIcons.play_fill, size: 12),
                                label: Text(
                                  isLowEnergy && energyRule == 'offerLight' ? 'شروع نسخه سبک' : 'شروع تایمر',
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
