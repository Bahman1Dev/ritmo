import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/reflection/presentation/widgets/reflection_correlation_section.dart';

class ReflectionTrendsSection extends StatelessWidget {

  const ReflectionTrendsSection({
    super.key,
    required this.stats,
    required this.moodTrend,
    required this.themeFrequency,
    this.energyCorrelation,
    this.moodCorrelation,
    required this.correlationInsight,
  });
  final ReflectionStats stats;
  final List<double> moodTrend;
  final Map<String, int> themeFrequency;
  final double? energyCorrelation;
  final double? moodCorrelation;
  final String correlationInsight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'میانگین حالِ روحی',
                  value: stats.avgMoodScore > 0 ? stats.avgMoodScore.toStringAsFixed(1) : '—',
                  subtitle: 'از ۵ امتیاز',
                  icon: CupertinoIcons.heart_fill,
                  iconColor: Colors.redAccent,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'نرخ تکمیل بازتاب‌ها',
                  value: '${(stats.completionRate * 100).toStringAsFixed(0)}٪',
                  subtitle: 'در ۱۴ روز اخیر',
                  icon: CupertinoIcons.percent,
                  iconColor: colors.primary,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mood chart card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '📈 روند حال روحی شما',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نمودار نوسانات خلق‌وخوی ثبت‌شده در روزهای اخیر',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: moodTrend.isEmpty
                        ? Center(
                            child: Text(
                              'داده‌های کافی برای رسم نمودار وجود ندارد. بازتاب‌های بیشتری ثبت کنید.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          )
                        : CustomPaint(
                            painter: MoodTrendPainter(
                              scores: moodTrend,
                              lineColor: colors.primary,
                              gridColor: colors.border.withValues(alpha: 0.15),
                              labelColor: colors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Correlation Section (R8)
          ReflectionCorrelationSection(
            energyCorrelation: energyCorrelation,
            moodCorrelation: moodCorrelation,
            insight: correlationInsight,
          ),
          const SizedBox(height: 16),

          // Theme frequency card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🏷️ کلمات و مفاهیم پرتکرار',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تمرکزهای ذهنی و موضوعاتی که در بازتاب‌های خود بیشتر یادداشت کرده‌اید',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (themeFrequency.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'هنوز متنی برای استخراج تم‌های روزانه ثبت نشده است.',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: themeFrequency.entries.map((entry) {
                        final count = entry.value;
                        final size = 10.0 + (count * 1.5).clamp(1.0, 10.0);
                        return Chip(
                          label: Text(
                            entry.key,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: size,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: colors.primary.withValues(alpha: 0.08),
                          side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required RitmoColors colors,
  }) {
    return RitmoTheme.glassCardLight(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                Icon(icon, color: iconColor, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
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
    );
  }
}

class MoodTrendPainter extends CustomPainter {

  MoodTrendPainter({
    required this.scores,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });
  final List<double> scores;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    // 1. Draw horizontal grid lines (for scores 1 to 5)
    final stepY = size.height / 4;
    for (var i = 0; i < 5; i++) {
      final y = size.height - (i * stepY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Draw score numbers
      textPainter.text = TextSpan(
        text: (i + 1).toString(),
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 9,
          color: labelColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-12, y - 6));
    }

    if (scores.isEmpty) return;

    // 2. Draw line/area
    final stepX = scores.length > 1 ? size.width / (scores.length - 1) : size.width;
    final points = <Offset>[];

    for (var i = 0; i < scores.length; i++) {
      final x = i * stepX;
      // Score ranges 1..5. Map to height: 5 maps to 0, 1 maps to size.height
      final scoreVal = scores[i].clamp(1.0, 5.0);
      final y = size.height - ((scoreVal - 1.0) / 4.0 * size.height);
      points.add(Offset(x, y));
    }

    if (scores.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      // Area fill
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // 3. Draw dots on top
    for (final pt in points) {
      canvas.drawCircle(pt, 4, dotPaint);
      canvas.drawCircle(pt, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant MoodTrendPainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
