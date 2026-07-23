import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/logic/cycle_correlation.dart';
import 'package:ritmo/features/cycle/models/cycle_models.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_mood_chart.dart';

class CycleTrendsSection extends StatefulWidget {

  const CycleTrendsSection({
    required this.engineOutput, super.key,
  });
  final CycleEngineOutput engineOutput;

  @override
  State<CycleTrendsSection> createState() => _CycleTrendsSectionState();
}

class _CycleTrendsSectionState extends State<CycleTrendsSection> {
  bool _loading = true;
  List<SymptomStat> _symptomStats = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final stats = await CycleCorrelationAnalyzer.analyzeSymptomStats(db);
      if (mounted) {
        setState(() {
          _symptomStats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _translateSymptom(String key) {
    final lowerKey = key.toLowerCase();
    switch (lowerKey) {
      case 'cramps':
        return 'دل‌درد و انقباض';
      case 'headache':
        return 'سردرد';
      case 'bloating':
        return 'نفخ شکم';
      case 'fatigue':
        return 'خستگی بدنی';
      case 'backache':
        return 'کمردرد';
      case 'mood_swings':
        return 'نوسانات خُلق';
      default:
        if (key.length > 1) {
          return key[0].toUpperCase() + key.substring(1).toLowerCase();
        }
        return key;
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendPoints = widget.engineOutput.trendPoints;

    if (trendPoints.length < 2) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 36),
              const SizedBox(height: 12),
              Text(
                'هنوز در حالِ یادگیریِ الگوی بدنتم 🌸',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای مشاهده نمودارهای روند و نظم چرخه، باید حداقل اطلاعات ۲ دوره قبلی را ثبت کرده باشید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Regularity Score Card
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وضعیت نظم چرخه بدنی',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.engineOutput.regularityLabel == 'نامنظم'
                            ? 'بر اساس تحلیل داده‌های شما، طول چرخه‌ها دارای پراکندگی است. این یک تشخیص پزشکی نیست، اما روتین منظم‌تر به پایداری ریتم بدنی کمک می‌کند.'
                            : widget.engineOutput.regularityLabel == 'نسبتاً منظم'
                                ? 'بر اساس تحلیل داده‌های شما، طول چرخه‌های اخیر به هم نزدیک بوده و ریتم بدنی منظم است 🌸'
                                : 'برای محاسبه وضعیت نظم چرخه، نیاز به ثبت دوره‌های بیشتری است.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffEC4899), width: 1.2),
                    color: const Color(0xffEC4899).withValues(alpha: 0.1),
                  ),
                  child: Text(
                    widget.engineOutput.regularityLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xffEC4899),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Trend Line Chart Card
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نمودار روند طول چرخه‌های اخیر',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    painter: _CycleTrendPainter(trendPoints: trendPoints, isDark: isDark),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendDot(const Color(0xffEC4899), 'طول چرخه بدنی (روز)'),
                    const SizedBox(width: 24),
                    _buildLegendDot(const Color(0xffF43F5E), 'طول دوره (روز)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        CycleMoodChart(
          averageCycleLength: widget.engineOutput.stats.avgCycleLength.round(),
        ),
        const SizedBox(height: 16),

        // 3. Symptom Stats Card
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بیشترین علائم فیزیکی گزارش‌شده',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading) const Center(child: CircularProgressIndicator(color: Color(0xffEC4899))) else _symptomStats.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'علائمی ثبت نشده است.',
                                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Vazirmatn'),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _symptomStats.take(5).length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final maxCount = _symptomStats.first.count;
                              final item = _symptomStats[index];
                              final pct = maxCount > 0 ? (item.count / maxCount) : 0.0;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Left: Symptom Name
                                      Text(
                                        _translateSymptom(item.key),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : colors.textPrimary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                      // Right: Badge / stats
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffEC4899).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.2), width: 0.5),
                                        ),
                                        child: Text(
                                          _toPersianDigits('روزِ شایع: ${item.typicalCycleDay} · ${item.count} بار'),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xffEC4899),
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Visual relative frequency bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xffEC4899)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ],
            ),
          ),
        ),

        // 4. Symptom Timeline Card
        if (!_loading && _symptomStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقشه زمانی توزیع علائم در طول چرخه',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'روزهای شایع بروز هر یک از علائم شما بر روی خط زمان دوره:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SymptomTimelinePainter(
                        stats: _symptomStats,
                        cycleLength: widget.engineOutput.stats.avgCycleLength.round(),
                        textColor: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.7),
                        trackColor: isDark ? Colors.white.withValues(alpha: 0.08) : colors.border.withValues(alpha: 0.2),
                        translator: _translateSymptom,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
      ],
    );
  }
}

class _CycleTrendPainter extends CustomPainter {

  _CycleTrendPainter({required this.trendPoints, required this.isDark});
  final List<CycleTrendPoint> trendPoints;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine1 = Paint()
      ..color = const Color(0xffEC4899)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintLine2 = Paint()
      ..color = const Color(0xffF43F5E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot1 = Paint()
      ..color = const Color(0xffEC4899)
      ..style = PaintingStyle.fill;

    final paintDot2 = Paint()
      ..color = const Color(0xffF43F5E)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    final count = trendPoints.length;
    final stepX = size.width / (count - 1).clamp(1, count);
    
    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    
    for (double y = 0; y <= size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathCycle = Path();
    final pathPeriod = Path();

    // Map Y: Cycle length max 45, min 15
    // Map Y: Period duration max 12, min 0
    double mapCycleY(int val) {
      final ratio = (val - 15) / (45 - 15);
      return size.height - (ratio.clamp(0.0, 1.0) * size.height);
    }

    double mapPeriodY(int val) {
      final ratio = val / 12;
      return size.height - (ratio.clamp(0.0, 1.0) * size.height);
    }

    for (var i = 0; i < count; i++) {
      final x = i * stepX;
      final yCycle = mapCycleY(trendPoints[i].lengthDays);
      final yPeriod = mapPeriodY(trendPoints[i].periodDays);

      if (i == 0) {
        pathCycle.moveTo(x, yCycle);
        pathPeriod.moveTo(x, yPeriod);
      } else {
        pathCycle.lineTo(x, yCycle);
        pathPeriod.lineTo(x, yPeriod);
      }

      // Draw Dots
      canvas.drawCircle(Offset(x, yCycle), 5, paintDot1);
      canvas.drawCircle(Offset(x, yPeriod), 4, paintDot2);

      // Draw value text
      textPainter.text = TextSpan(
        text: _toPersianDigits(trendPoints[i].lengthDays.toString()),
        style: TextStyle(fontSize: 9, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Vazirmatn'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 6, yCycle - 16));
    }

    canvas.drawPath(pathCycle, paintLine1);
    canvas.drawPath(pathPeriod, paintLine2);
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SymptomTimelinePainter extends CustomPainter {

  _SymptomTimelinePainter({
    required this.stats,
    required this.cycleLength,
    required this.textColor,
    required this.trackColor,
    required this.translator,
  });
  final List<SymptomStat> stats;
  final int cycleLength;
  final Color textColor;
  final Color trackColor;
  final Function(String) translator;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 24.0;
    const paddingRight = 24.0;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final centerY = size.height / 2;

    // Draw main timeline track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(paddingLeft, centerY), Offset(size.width - paddingRight, centerY), trackPaint);

    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    // Draw start and end day ticks
    final tickPaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Tick at Day 1 (On the right in RTL)
    final startX = size.width - paddingRight;
    canvas.drawLine(Offset(startX, centerY - 6), Offset(startX, centerY + 6), tickPaint);
    textPainter.text = const TextSpan(
      text: 'روز ۱',
      style: TextStyle(fontSize: 8.5, color: Colors.grey, fontFamily: 'Vazirmatn'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX - textPainter.width / 2, centerY + 10));

    // Tick at Day L (On the left in RTL)
    const endX = paddingLeft;
    canvas.drawLine(Offset(endX, centerY - 6), Offset(endX, centerY + 6), tickPaint);
    textPainter.text = TextSpan(
      text: _toPersianDigits('روز $cycleLength'),
      style: TextStyle(fontSize: 8.5, color: textColor, fontFamily: 'Vazirmatn'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(endX - textPainter.width / 2, centerY + 10));

    // Plot symptoms (Alternating top and bottom offsets, starting from right)
    final visibleStats = stats.take(4).toList();
    for (var i = 0; i < visibleStats.length; i++) {
      final stat = visibleStats[i];
      final day = stat.typicalCycleDay;
      if (day < 1 || day > cycleLength) continue;

      // Calculate x starting from the right (startX) towards the left
      final x = startX - ((day - 1) / (cycleLength - 1)) * chartWidth;
      final isTop = i % 2 == 0;
      final lineLen = isTop ? -35.0 : 35.0;
      final targetY = centerY + lineLen;

      final dashPaint = Paint()
        ..color = const Color(0xffEC4899).withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(x, centerY), Offset(x, targetY), dashPaint);

      final dotPaint = Paint()
        ..color = const Color(0xffEC4899)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, centerY), 4.5, dotPaint);

      final String farsiName = translator(stat.key);
      final labelSpan = TextSpan(
        text: _toPersianDigits('$farsiName (روز $day)'),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
      );

      textPainter.text = labelSpan;
      textPainter.layout();

      final badgeWidth = textPainter.width + 12;
      final badgeHeight = textPainter.height + 6;
      final badgeX = x - badgeWidth / 2;
      final badgeY = isTop ? targetY - badgeHeight : targetY;

      // Clamp badgeX to keep badge within view bounds
      final clampedBadgeX = badgeX.clamp(4.0, size.width - badgeWidth - 4.0);

      final badgePaint = Paint()
        ..color = const Color(0xffEC4899).withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clampedBadgeX, badgeY, badgeWidth, badgeHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, badgePaint);

      textPainter.paint(canvas, Offset(clampedBadgeX + 6, badgeY + 3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

