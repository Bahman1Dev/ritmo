import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class SleepPatternsSection extends StatelessWidget {

  const SleepPatternsSection({
    super.key,
    required this.consistencyScore,
    required this.avgDurationMinutes,
    required this.sleepDebtMinutes,
    required this.bestBedtimeWindow,
    required this.totalLogsCount,
  });
  final int consistencyScore;
  final double avgDurationMinutes;
  final int sleepDebtMinutes;
  final String bestBedtimeWindow;
  final int totalLogsCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Show learning state if we have less than 3 logs
    if (totalLogsCount < 3) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🌙 هنوز در حالِ یادگیریِ الگوی خوابتم',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.cardTitle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لطفاً حداقل خواب ۳ شب اخیر خود را ثبت کنید تا الگوهای نظم، بدهی خواب و بهترین زمان استراحت شما تحلیل شوند.',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final avgHours = avgDurationMinutes ~/ 60;
    final avgMins = (avgDurationMinutes % 60).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Consistency Score Card (Nzm-e Khab)
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'نمره نظم و ثبات خواب شما',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 110,
                        width: 110,
                        child: CircularProgressIndicator(
                          value: consistencyScore / 100,
                          strokeWidth: 8,
                          backgroundColor: colors.inputBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff8B5CF6)),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$consistencyScore٪',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: colors.cardTitle,
                            ),
                          ),
                          Text(
                            _getConsistencyLabel(consistencyScore),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ثبات ساعت خواب و بیداری، ریتم شبانه‌روزی (Circadian Rhythm) را منظم نگه داشته و کیفیت انرژی روزانه را ارتقا می‌دهد.',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Average Duration Card
          _buildInfoCard(
            title: 'میانگین مدت خواب اخیر',
            value: '$avgHours ساعت و $avgMins دقیقه',
            icon: CupertinoIcons.time_solid,
            subtitle: 'میانگین ساعت خواب ثبت‌شده در روزهای اخیر',
            colors: colors,
          ),
          const SizedBox(height: 16),

          // 3. Sleep Debt Card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sleepDebtMinutes > 0
                          ? colors.warning.withValues(alpha: 0.1)
                          : colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: sleepDebtMinutes > 0 ? colors.warning : colors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بدهی خواب انباشته',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.cardTitle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sleepDebtMinutes > 0
                              ? '$sleepDebtMinutes دقیقه کمبود خواب'
                              : 'بدون بدهی خواب (عالی!)',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sleepDebtMinutes > 0 ? colors.warning : colors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'کمبود خواب تجمعی نسبت به هدف خواب شما',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Best Bedtime Window Card
          _buildInfoCard(
            title: 'بهترین بازه ساعت خوابیدن',
            value: bestBedtimeWindow != 'نامشخص' ? bestBedtimeWindow : 'در حال تخمین بازه طلایی...',
            icon: CupertinoIcons.sparkles,
            subtitle: 'ساعت خوابی که در روزهای بعد بالاترین سطح انرژی و کیفیت حال را رقم زده است.',
            colors: colors,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getConsistencyLabel(int score) {
    if (score >= 90) return 'بسیار عالی';
    if (score >= 75) return 'خوب و منظم';
    if (score >= 50) return 'متوسط';
    return 'نامنظم';
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
    required RitmoColors colors,
  }) {
    return RitmoTheme.glassCardLight(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xff8B5CF6), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.cardSubtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
