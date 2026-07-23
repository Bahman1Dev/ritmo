import 'package:flutter/cupertino.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class SleepTrendsSection extends StatelessWidget {

  const SleepTrendsSection({
    super.key,
    required this.durationTrend,
    required this.qualityTrend,
    this.sleepEnergyCorrelation,
    this.sleepMoodCorrelation,
    required this.correlationInsight,
  });
  final List<double> durationTrend; // in minutes
  final List<double> qualityTrend;  // 1..5
  final double? sleepEnergyCorrelation;
  final double? sleepMoodCorrelation;
  final String correlationInsight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Chart Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'نمودار روند خواب',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.cardTitle,
              ),
            ),
          ),

          // 2. Trend Line Chart Card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'روند خواب و کیفیت روزهای اخیر',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textPrimary),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xff8B5CF6), 'مدت خواب', colors),
                          const SizedBox(width: 12),
                          _buildLegendDot(const Color(0xffF59E0B), 'کیفیت', colors),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (durationTrend.isEmpty || durationTrend.length < 2)
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      child: Text(
                        'داده‌های کافی برای رسم نمودار وجود ندارد 📊',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                      ),
                    )
                  else
                    SizedBox(
                      height: 160,
                      child: CustomPaint(
                        painter: SleepTrendPainter(
                          durations: durationTrend,
                          qualities: qualityTrend,
                          gridColor: colors.glassBorder,
                          dotOuterColor: colors.card,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Correlation section title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'تحلیل همبستگی خواب با روز بعد',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.cardTitle,
              ),
            ),
          ),

          // 4. Correlation Cards
          Row(
            children: [
              Expanded(
                child: _buildCorrelationCard(
                  title: 'همبستگی با انرژی',
                  value: sleepEnergyCorrelation,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCorrelationCard(
                  title: 'همبستگی با روحیه',
                  value: sleepMoodCorrelation,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Correlation Insight Card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.lightbulb, color: Color(0xffF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'تحلیل ارتباط خواب و عملکرد',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    correlationInsight,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      height: 1.5,
                      color: colors.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'توضیح علمی: ضریب همبستگی عددی بین ۱- (همبستگی معکوس کامل) تا ۱+ (همبستگی مستقیم کامل) است. مقادیر نزدیک به صفر نشان‌دهنده نبود ارتباط مستقیم است.',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 9,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text, RitmoColors colors) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCorrelationCard({
    required String title,
    required double? value,
    required RitmoColors colors,
  }) {
    final val = value;
    var displayValue = 'کمبود داده';
    var valColor = colors.textSecondary;
    
    if (val != null) {
      displayValue = val >= 0 ? '+${val.toStringAsFixed(2)}' : val.toStringAsFixed(2);
      if (val.abs() >= 0.3) {
        valColor = const Color(0xff8B5CF6);
      } else {
        valColor = colors.cardTitle;
      }
    }

    return RitmoTheme.glassCardLight(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: valColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val != null ? _getCorrelationStrengthLabel(val) : 'حداقل ۳ ثبت نیاز است',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _getCorrelationStrengthLabel(double val) {
    final absVal = val.abs();
    if (absVal >= 0.7) return 'همبستگی بسیار قوی';
    if (absVal >= 0.3) return 'همبستگی متوسط';
    if (absVal >= 0.1) return 'همبستگی ضعیف';
    return 'بدون همبستگی';
  }
}

class SleepTrendPainter extends CustomPainter {

  SleepTrendPainter({
    required this.durations,
    required this.qualities,
    required this.gridColor,
    required this.dotOuterColor,
  });
  final List<double> durations; // in minutes
  final List<double> qualities; // 1..5
  final Color gridColor;
  final Color dotOuterColor;

  @override
  void paint(Canvas canvas, Size size) {
    final count = durations.length;
    if (count < 2) return;

    // 1. Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = (size.height / gridLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Find min/max values for scaling
    // We scale durations between 0 and 12 hours (720 mins)
    const maxDuration = 720; // 12 hours
    const maxQuality = 5;

    final stepX = size.width / (count - 1);

    // 3. Draw Duration Trend Line (Purple)
    final durationPaint = Paint()
      ..color = const Color(0xff8B5CF6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final durationFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff8B5CF6).withValues(alpha: 0.3),
          const Color(0xff8B5CF6).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final durationPath = Path();
    final durationFillPath = Path();

    // 4. Draw Quality Trend Line (Amber)
    final qualityPaint = Paint()
      ..color = const Color(0xffF59E0B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final qualityPath = Path();

    // Plotting
    for (var i = 0; i < count; i++) {
      final x = stepX * i;
      
      // Mapped Y for duration
      final dVal = durations[i].clamp(0.0, maxDuration);
      final yD = size.height - (dVal / maxDuration) * size.height;

      // Mapped Y for quality
      final qVal = qualities[i].clamp(1.0, maxQuality);
      final yQ = size.height - ((qVal - 1) / (maxQuality - 1)) * size.height;

      if (i == 0) {
        durationPath.moveTo(x, yD);
        durationFillPath.moveTo(x, size.height);
        durationFillPath.lineTo(x, yD);
        
        qualityPath.moveTo(x, yQ);
      } else {
        durationPath.lineTo(x, yD);
        durationFillPath.lineTo(x, yD);
        
        qualityPath.lineTo(x, yQ);
      }

      if (i == count - 1) {
        durationFillPath.lineTo(x, size.height);
        durationFillPath.close();
      }
    }

    // Paint paths
    canvas.drawPath(durationFillPath, durationFillPaint);
    canvas.drawPath(durationPath, durationPaint);
    canvas.drawPath(qualityPath, qualityPaint);

    // Draw dots at points
    final dotPaintPurple = Paint()..color = const Color(0xff8B5CF6);
    final dotPaintAmber = Paint()..color = const Color(0xffF59E0B);
    final dotOuterPaint = Paint()..color = dotOuterColor;

    for (var i = 0; i < count; i++) {
      final x = stepX * i;
      
      final dVal = durations[i].clamp(0.0, maxDuration);
      final yD = size.height - (dVal / maxDuration) * size.height;

      final qVal = qualities[i].clamp(1.0, maxQuality);
      final yQ = size.height - ((qVal - 1) / (maxQuality - 1)) * size.height;

      // Duration dot
      canvas.drawCircle(Offset(x, yD), 5, dotOuterPaint);
      canvas.drawCircle(Offset(x, yD), 3, dotPaintPurple);

      // Quality dot
      canvas.drawCircle(Offset(x, yQ), 4, dotOuterPaint);
      canvas.drawCircle(Offset(x, yQ), 2.5, dotPaintAmber);
    }
  }

  @override
  bool shouldRepaint(covariant SleepTrendPainter oldDelegate) {
    return oldDelegate.durations != durations || oldDelegate.qualities != qualities;
  }
}
