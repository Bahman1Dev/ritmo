import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class PulseCard extends StatelessWidget {

  const PulseCard({
    super.key,
    required this.rhythmScore,
    required this.isDarkMode,
    this.onNavigateToTab,
  });
  final int rhythmScore;
  final bool isDarkMode;
  final Function(int)? onNavigateToTab;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  Widget _buildWeeklyChart(RitmoColors colors) {
    final now = DateTime.now();
    final dayNames = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    
    // Generate the last 7 weekdays labels dynamically
    final labels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return dayNames[day.weekday - 1];
    });

    final weeklyScores = [75, 68, 85, 72, 90, 65, rhythmScore];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final score = weeklyScores[index];
        final isToday = index == 6;
        final barHeight = (score / 100.0) * 36.0; // Max height 36sp

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 38,
              width: 12,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: barHeight.clamp(2.0, 36.0),
                width: isToday ? 8.0 : 6.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isToday
                        ? [
                            const Color(0xff9B89FF),
                            const Color(0xff6B9EFF),
                          ]
                        : [
                            const Color(0xff9B89FF).withValues(alpha: 0.6),
                            const Color(0xff6B9EFF).withValues(alpha: 0.6),
                          ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? colors.primary : colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    // Dynamic text based on score
    var moodText = l10n.pulseCardMoodGood;
    if (rhythmScore >= 90) {
      moodText = l10n.pulseCardMoodExcellent;
    } else if (rhythmScore < 50) {
      moodText = l10n.pulseCardMoodRestore;
    }

    final isHigh = rhythmScore >= 80;
    final scoreColor = isHigh ? colors.success : colors.primary;

    final String trendText;
    final Color trendColor;
    if (rhythmScore >= 80) {
      trendText = 'عالی ↑';
      trendColor = colors.success;
    } else if (rhythmScore >= 60) {
      trendText = 'پایدار ~';
      trendColor = colors.primary;
    } else {
      trendText = 'نیازمند استراحت ↓';
      trendColor = colors.warning;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 16,
        color: colors.card.withValues(alpha: 0.65),
        child: InkWell(
          onTap: () {
            // Switch to Reports tab (index 1)
            onNavigateToTab?.call(1);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Glowing Background + RitmoOrb
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xff6B9EFF).withValues(alpha: 0.25),
                            const Color(0xff9B89FF).withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff5B8AF5).withValues(alpha: isDarkMode ? 0.25 : 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Score details and bar chart
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.pulseCardTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _toPersianDigits('$rhythmScore'),
                                    style: TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      color: scoreColor,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    moodText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Trend Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: trendColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              trendText,
                              style: TextStyle(
                                fontSize: 10,
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 7-day bar chart
                      _buildWeeklyChart(colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
