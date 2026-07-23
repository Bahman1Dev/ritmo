import 'package:flutter/material.dart';
// Just in case, but let's build our own to be safe.
import 'package:ritmo/core/analytics/konkur_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurHero extends StatelessWidget {

  const KonkurHero({
    super.key,
    required this.data,
    required this.onSetDateTap,
  });
  final KonkurEngineOutput data;
  final VoidCallback onSetDateTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // A beautiful purple-to-violet gradient for the background
    final gradient = LinearGradient(
      colors: isDarkMode
          ? [
              const Color(0xFF7C3AED).withValues(alpha: 0.35),
              const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            ]
          : [
              const Color(0xFF8B5CF6).withValues(alpha: 0.85),
              const Color(0xFFA78BFA).withValues(alpha: 0.95),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final textColor = isDarkMode ? colors.textPrimary : Colors.white;
    final subtitleColor = isDarkMode ? colors.textSecondary : Colors.white.withValues(alpha: 0.85);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDarkMode ? 0.15 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: isDarkMode ? 0.3 : 0.5),
          width: 1.5,
        ),
      ),
      child: RitmoGlassCardLight(
        color: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        shadows: const [],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'روزشمار کنکور',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (data.daysUntilExam >= 0) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                toPersianDigits(data.daysUntilExam),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'روز تا آزمون سرنوشت‌ساز',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: onSetDateTap,
                            child: Row(
                              children: [
                                Text(
                                  'تاریخ کنکور را تعیین کنید',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? const Color(0xFFA78BFA) : Colors.yellowAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: isDarkMode ? const Color(0xFFA78BFA) : Colors.yellowAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildReadinessIndicator(data.overallReadiness, textColor),
                ],
              ),
              const Divider(color: Colors.white24, height: 24, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    icon: Icons.timer,
                    label: 'مطالعه این هفته',
                    value: formatDuration(data.studyMinutesThisWeek),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _buildMetricItem(
                    icon: Icons.local_fire_department,
                    label: 'استریک استمرار',
                    value: data.studyStreakDays > 0
                        ? '${toPersianDigits(data.studyStreakDays)} روز 🔥'
                        : 'شروع کن 💪',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessIndicator(double readiness, Color textColor) {
    final percent = (readiness * 100).toInt();
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: readiness,
                backgroundColor: Colors.white24,
                color: const Color(0xFF10B981),
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${toPersianDigits(percent)}٪',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'آمادگی کل',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: textColor.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: subtitleColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
