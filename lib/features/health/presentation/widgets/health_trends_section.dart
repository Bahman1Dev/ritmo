import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';

class HealthTrendsSection extends StatefulWidget {

  const HealthTrendsSection({
    super.key,
    required this.trends,
  });
  final List<VitalTrend> trends;

  @override
  State<HealthTrendsSection> createState() => _HealthTrendsSectionState();
}

class _HealthTrendsSectionState extends State<HealthTrendsSection> {
  String _selectedMetricGroup = 'blood_sugar'; // 'blood_sugar' | 'blood_pressure' | 'weight' | 'spo2' | 'temperature'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Filter available metric groups based on trends present
    final hasSugar = widget.trends.any((t) => t.metric == 'blood_sugar');
    final hasBP = widget.trends.any((t) => t.metric.startsWith('blood_pressure'));
    final hasWeight = widget.trends.any((t) => t.metric == 'weight');
    final hasSpO2 = widget.trends.any((t) => t.metric == 'spo2');
    final hasTemp = widget.trends.any((t) => t.metric == 'temperature');

    if (widget.trends.isEmpty) {
      return Card(
        color: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.border)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'داده‌ای برای تحلیل روند علایم وجود ندارد.',
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    // Determine current group data
    var currentTrends = <VitalTrend>[];
    var rangeLabel = '';
    double? minTarget;
    double? maxTarget;

    if (_selectedMetricGroup == 'blood_sugar' && hasSugar) {
      currentTrends = [widget.trends.firstWhere((t) => t.metric == 'blood_sugar')];
      // Approximate range for display
      minTarget = 70;
      maxTarget = 140;
      rangeLabel = 'محدوده سالم: ۷۰ - ۱۴۰';
    } else if (_selectedMetricGroup == 'blood_pressure' && hasBP) {
      currentTrends = widget.trends.where((t) => t.metric.startsWith('blood_pressure')).toList();
      minTarget = 60; // diastolic lower boundary
      maxTarget = 120; // systolic upper boundary (ideal)
      rangeLabel = 'محدوده سالم: سیستولیک زیر ۱۲۰ و دیاستولیک زیر ۸۰';
    } else if (_selectedMetricGroup == 'weight' && hasWeight) {
      currentTrends = [widget.trends.firstWhere((t) => t.metric == 'weight')];
      rangeLabel = 'روند تغییرات وزن بدن';
    } else if (_selectedMetricGroup == 'spo2' && hasSpO2) {
      currentTrends = [widget.trends.firstWhere((t) => t.metric == 'spo2')];
      minTarget = 95;
      maxTarget = 100;
      rangeLabel = 'محدوده سالم: ۹۵٪ - ۱۰۰٪';
    } else if (_selectedMetricGroup == 'temperature' && hasTemp) {
      currentTrends = [widget.trends.firstWhere((t) => t.metric == 'temperature')];
      minTarget = 36.0;
      maxTarget = 37.5;
      rangeLabel = 'محدوده سالم: ۳۶.۰ - ۳۷.۵';
    } else {
      // Fallback to first available
      if (widget.trends.isNotEmpty) {
        currentTrends = [widget.trends.first];
      }
    }

    return Card(
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'روند تغییرات علائم حیاتی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            // Chips for selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (hasSugar)
                    _buildMetricChip('blood_sugar', 'قند خون', colors),
                  if (hasBP)
                    _buildMetricChip('blood_pressure', 'فشار خون', colors),
                  if (hasWeight)
                    _buildMetricChip('weight', 'وزن', colors),
                  if (hasSpO2)
                    _buildMetricChip('spo2', 'اکسیژن خون', colors),
                  if (hasTemp)
                    _buildMetricChip('temperature', 'دمای بدن', colors),
                ],
              ),
            ),
            const Divider(height: 24),
            if (currentTrends.isNotEmpty) ...[
              // Summary cards
              Row(
                children: currentTrends.map((trend) {
                  final isSystolic = trend.metric == 'blood_pressure_systolic';
                  final isDiastolic = trend.metric == 'blood_pressure_diastolic';
                  var subLabel = trend.metric == 'blood_sugar' ? 'قند ناشتا/میانگین' : trend.metric;
                  if (isSystolic) subLabel = 'سیستولیک';
                  if (isDiastolic) subLabel = 'دیاستولیک';
                  if (trend.metric == 'weight') subLabel = 'وزن بدن';
                  if (trend.metric == 'spo2') subLabel = 'اکسیژن خون';
                  if (trend.metric == 'temperature') subLabel = 'دمای بدن';

                  var unit = 'mg/dL';
                  if (trend.metric.startsWith('blood_pressure')) unit = 'mmHg';
                  if (trend.metric == 'weight') unit = 'kg';
                  if (trend.metric == 'spo2') unit = '%';
                  if (trend.metric == 'temperature') unit = '°C';

                  var directionText = 'ثابت';
                  var directionIcon = Icons.trending_flat;
                  var directionColor = colors.textSecondary;
                  if (trend.direction == 'up') {
                    directionText = 'صعودی';
                    directionIcon = Icons.trending_up;
                    directionColor = colors.medicalRed;
                  } else if (trend.direction == 'down') {
                    directionText = 'نزولی';
                    directionIcon = Icons.trending_down;
                    directionColor = colors.success;
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subLabel, style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _toPersianDigits(trend.average.toStringAsFixed(1)),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                              ),
                              const SizedBox(width: 4),
                              Text(unit, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(directionIcon, color: directionColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                directionText,
                                style: TextStyle(fontSize: 10, color: directionColor, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Range summary
              if (currentTrends.first.metric != 'weight')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: colors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_toPersianDigits(currentTrends.first.inRangePercent.toStringAsFixed(0))}% زمان‌ها در محدوده سالم قرار داشته است.',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (rangeLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(rangeLabel, style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                ),
              // Chart area
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 5, left: 5, right: 10),
                child: CustomPaint(
                  painter: LineChartPainter(
                    trends: currentTrends,
                    minTarget: minTarget,
                    maxTarget: maxTarget,
                    lineColors: [
                      colors.primary,
                      colors.warning,
                    ],
                    gridColor: colors.border,
                    textColor: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String value, String label, RitmoColors colors) {
    final isSelected = _selectedMetricGroup == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetricGroup = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
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
}

class LineChartPainter extends CustomPainter {

  LineChartPainter({
    required this.trends,
    this.minTarget,
    this.maxTarget,
    required this.lineColors,
    required this.gridColor,
    required this.textColor,
  });
  final List<VitalTrend> trends;
  final double? minTarget;
  final double? maxTarget;
  final List<Color> lineColors;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    // Collect all points to determine min/max scale
    final allLinesPoints = trends.map((t) => t.points).toList();
    final flatPoints = allLinesPoints.expand((x) => x).toList();

    if (flatPoints.isEmpty) return;

    var minY = flatPoints.map((p) => p.value).reduce(min);
    var maxY = flatPoints.map((p) => p.value).reduce(max);

    // Add target range to range calculations if specified
    if (minTarget != null) minY = min(minY, minTarget!);
    if (maxTarget != null) maxY = max(maxY, maxTarget!);

    // Give some padding on top and bottom
    final padding = (maxY - minY) * 0.15 + 1.0;
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxY = maxY + padding;

    final rangeY = maxY - minY;

    // Find maximum length of x values
    final maxPts = allLinesPoints.map((l) => l.length).reduce(max);
    if (maxPts < 1) return;

    // Draw horizontal grid lines and labels
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    const gridRows = 4;
    for (var i = 0; i <= gridRows; i++) {
      final yRatio = i / gridRows;
      final yPos = size.height * (1.0 - yRatio);
      final valueY = minY + (rangeY * yRatio);

      // Grid line
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paintGrid);

      // Label
      textPainter.text = TextSpan(
        text: _toPersianDigits(valueY.toStringAsFixed(0)),
        style: TextStyle(color: textColor, fontSize: 8, fontFamily: 'Vazirmatn'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 2, yPos - textPainter.height - 2));
    }

    // Draw target range shaded area if specified
    if (minTarget != null && maxTarget != null) {
      final yMinRatio = (minTarget! - minY) / rangeY;
      final yMaxRatio = (maxTarget! - minY) / rangeY;
      final yMinPos = size.height * (1.0 - yMinRatio);
      final yMaxPos = size.height * (1.0 - yMaxRatio);

      final targetPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(0, yMaxPos, size.width, yMinPos),
        targetPaint,
      );

      // Draw dashed border lines for target
      final targetBorderPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, yMinPos), Offset(size.width, yMinPos), targetBorderPaint);
      canvas.drawLine(Offset(0, yMaxPos), Offset(size.width, yMaxPos), targetBorderPaint);
    }

    // Plot each line
    for (var lIdx = 0; lIdx < trends.length; lIdx++) {
      final pts = trends[lIdx].points;
      if (pts.isEmpty) continue;

      final lineColor = lineColors[lIdx % lineColors.length];
      final paintLine = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final paintPoint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      final paintPointBg = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final path = Path();
      final drawOffsets = <Offset>[];

      for (var i = 0; i < pts.length; i++) {
        final xRatio = pts.length > 1 ? i / (pts.length - 1) : 0.5;
        final xPos = xRatio * size.width;
        final yRatio = (pts[i].value - minY) / rangeY;
        final yPos = size.height * (1.0 - yRatio);

        final offset = Offset(xPos, yPos);
        drawOffsets.add(offset);

        if (i == 0) {
          path.moveTo(xPos, yPos);
        } else {
          path.lineTo(xPos, yPos);
        }
      }

      // Draw line
      if (pts.length > 1) {
        canvas.drawPath(path, paintLine);
      }

      // Draw point markers
      for (final offset in drawOffsets) {
        canvas.drawCircle(offset, 4.5, paintPoint);
        canvas.drawCircle(offset, 2, paintPointBg);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.trends != trends ||
        oldDelegate.minTarget != minTarget ||
        oldDelegate.maxTarget != maxTarget;
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
}
