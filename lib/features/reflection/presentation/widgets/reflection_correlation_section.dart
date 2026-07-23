import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class ReflectionCorrelationSection extends StatelessWidget {

  const ReflectionCorrelationSection({
    super.key,
    required this.energyCorrelation,
    required this.moodCorrelation,
    required this.insight,
  });
  final double? energyCorrelation;
  final double? moodCorrelation;
  final String insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasData = energyCorrelation != null || moodCorrelation != null;

    return RitmoTheme.glassCardLight(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🧠 تحلیل همبستگی خودآگاهی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'رابطه آماری بین دفعات ژورنال‌نویسی با سطح انرژی و خلق‌وخوی شما',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasData) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar,
                        size: 32,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'داده‌های همبستگی هنوز کافی نیست 📊',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'حداقل به ثبت ۳ روز تأمل عصرگاهی و ثبت انرژی/خلق‌وخو در طول روز نیاز دارید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              if (moodCorrelation != null) ...[
                _buildCorrelationRow(
                  label: 'همبستگی بازتاب ↔ روحیه روزانه',
                  value: moodCorrelation!,
                  colors: colors,
                ),
                const SizedBox(height: 16),
              ],
              if (energyCorrelation != null) ...[
                _buildCorrelationRow(
                  label: 'همبستگی بازتاب ↔ سطح انرژی',
                  value: energyCorrelation!,
                  colors: colors,
                ),
                const SizedBox(height: 20),
              ],

              // Insight block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧐',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفسیر الگوها:',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              color: colors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '* توجه: این همبستگی ریاضی است و نشان‌دهنده رابطه علّی قطعی نیست؛ ممکن است ثبت بازتاب به بهبود روحیه کمک کند یا در روزهای خوب تمایل بیشتری به نوشتن داشته باشید.',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationRow({
    required String label,
    required double value,
    required RitmoColors colors,
  }) {
    // Pearson coefficient ranges from -1 to +1
    // Translate -1..1 to 0..1 percentage for the progress/slider
    final normalizedVal = (value + 1.0) / 2.0;

    var barColor = colors.textSecondary;
    var strengthText = 'بی‌ارتباط';
    if (value > 0.6) {
      barColor = colors.success;
      strengthText = 'همبستگی مثبت قوی';
    } else if (value > 0.2) {
      barColor = colors.primary;
      strengthText = 'همبستگی مثبت ملایم';
    } else if (value < -0.6) {
      barColor = Colors.redAccent;
      strengthText = 'همبستگی منفی قوی';
    } else if (value < -0.2) {
      barColor = Colors.orangeAccent;
      strengthText = 'همبستگی منفی ملایم';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${value > 0 ? "+" : ""}${value.toStringAsFixed(2)} ($strengthText)',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Middle zero indicator
            Align(
              child: Container(
                width: 2,
                height: 8,
                color: colors.border.withValues(alpha: 0.5),
              ),
            ),
            // The value line
            FractionallySizedBox(
              widthFactor: normalizedVal,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '-۱.۰ (منفی)',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '۰.۰',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '+۱.۰ (مثبت)',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
