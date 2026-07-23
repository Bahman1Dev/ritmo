import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class CoursesWeeklyHero extends StatelessWidget {

  const CoursesWeeklyHero({
    super.key,
    required this.weeklyDoneSessions,
    required this.weeklyTargetSessions,
    required this.weeklyStudyMinutes,
    required this.studyStreakDays,
  });
  final int weeklyDoneSessions;
  final int weeklyTargetSessions;
  final int weeklyStudyMinutes;
  final int studyStreakDays;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final progress = weeklyTargetSessions > 0
        ? (weeklyDoneSessions / weeklyTargetSessions).clamp(0.0, 1.0)
        : 0.0;

    return RitmoTheme.glassCardLight(
      color: isDarkMode
          ? const Color(0xff1D4ED8).withValues(alpha: 0.15)
          : const Color(0xff3B82F6).withValues(alpha: 0.1),
      border: Border.all(
        color: const Color(0xff3B82F6).withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xff1E3A8A).withValues(alpha: 0.4),
                    const Color(0xff3B82F6).withValues(alpha: 0.1),
                  ]
                : [
                    const Color(0xffEFF6FF).withValues(alpha: 0.9),
                    const Color(0xffDBEAFE).withValues(alpha: 0.9),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xff3B82F6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.book_fill,
                        color: Color(0xff3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'خلاصه وضعیت هفته',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff10A37F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.flame_fill,
                        color: Color(0xff10A37F),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${toPersianDigits(studyStreakDays)} روز استریک',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff10A37F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پیشرفت هدف هفتگی',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        textBaseline: TextBaseline.alphabetic,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Text(
                            toPersianDigits(weeklyDoneSessions),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            ' / ${toPersianDigits(weeklyTargetSessions)} جلسه',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: colors.border.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'کل زمان مطالعه',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        textBaseline: TextBaseline.alphabetic,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Text(
                            toPersianDigits(weeklyStudyMinutes),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            ' دقیقه',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colors.border.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff3B82F6)),
              ),
            ),
            if (weeklyDoneSessions >= weeklyTargetSessions && weeklyTargetSessions > 0) ...[
              const SizedBox(height: 10),
              Text(
                'هدف هفتگی محقق شد! عالیه 🎉💪',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
