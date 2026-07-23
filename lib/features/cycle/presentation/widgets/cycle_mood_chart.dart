import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class CycleMoodChart extends StatefulWidget {

  const CycleMoodChart({
    super.key,
    required this.averageCycleLength,
  });
  final int averageCycleLength;

  @override
  State<CycleMoodChart> createState() => _CycleMoodChartState();
}

class _CycleMoodChartState extends State<CycleMoodChart> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];
  Map<int, double> _dayMoodAverages = {};
  int _maxAnxietyDay = -1;
  int _maxEnergyDay = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch periods to calculate dayOfCycle
      final List<Map<String, dynamic>> periods = await db.query(
        'cycle_periods',
        orderBy: 'startDate ASC',
      );

      // 2. Fetch day logs
      final List<Map<String, dynamic>> logsRows = await db.query(
        'cycle_day_logs',
        orderBy: 'logDate ASC',
      );

      if (logsRows.isEmpty || periods.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _logs = [];
          });
        }
        return;
      }

      final L = widget.averageCycleLength;
      final moodValuesByDay = <int, List<double>>{};
      final energyValuesByDay = <int, List<double>>{};
      
      final anxietyCounts = <int, int>{};
      final highEnergyCounts = <int, int>{};

      for (final row in logsRows) {
        final logDateStr = row['logDate'] as String;
        final logDate = DateTime.parse(logDateStr);

        // Find the latest period that started on or before logDate
        Map<String, dynamic>? currentPeriod;
        for (var i = 0; i < periods.length; i++) {
          final start = DateTime.parse(periods[i]['startDate'] as String);
          if (!start.isAfter(logDate)) {
            currentPeriod = periods[i];
          }
        }

        if (currentPeriod == null) continue;

        final periodStart = DateTime.parse(currentPeriod['startDate'] as String);
        final diff = logDate.difference(periodStart).inDays;

        final dayOfCycle = diff + 1;
        if (dayOfCycle < 1 || dayOfCycle > L) continue;

        // Extract Mood
        final mood = row['mood'] as String?;
        if (mood != null) {
          var score = 3.0; // NEUTRAL default
          if (mood == 'HAPPY') score = 4.0;
          if (mood == 'NEUTRAL') score = 3.0;
          if (mood == 'SAD') score = 2.0;
          if (mood == 'ANXIOUS') score = 1.0;
          if (mood == 'IRRITABLE') score = 0.0;

          moodValuesByDay.putIfAbsent(dayOfCycle, () => []).add(score);

          if (mood == 'ANXIOUS' || mood == 'IRRITABLE') {
            anxietyCounts[dayOfCycle] = (anxietyCounts[dayOfCycle] ?? 0) + 1;
          }
        }

        // Extract Energy
        final energy = row['energyTag'] as String?;
        if (energy != null) {
          var score = 2.0; // MEDIUM default
          if (energy == 'HIGH') score = 3.0;
          if (energy == 'MEDIUM') score = 2.0;
          if (energy == 'LOW') score = 1.0;

          energyValuesByDay.putIfAbsent(dayOfCycle, () => []).add(score);

          if (energy == 'HIGH') {
            highEnergyCounts[dayOfCycle] = (highEnergyCounts[dayOfCycle] ?? 0) + 1;
          }
        }
      }

      // Compute Averages
      final moodAverages = <int, double>{};
      final energyAverages = <int, double>{};

      moodValuesByDay.forEach((day, list) {
        moodAverages[day] = list.reduce((a, b) => a + b) / list.length;
      });

      energyValuesByDay.forEach((day, list) {
        energyAverages[day] = list.reduce((a, b) => a + b) / list.length;
      });

      // Find Critical Anxiety Day
      var maxAnxietyDay = -1;
      var maxAnxietyCount = 0;
      anxietyCounts.forEach((day, count) {
        if (count > maxAnxietyCount) {
          maxAnxietyCount = count;
          maxAnxietyDay = day;
        }
      });

      if (maxAnxietyDay == -1) {
        var lowestAvgMood = 5.0;
        var minMoodDay = -1;
        moodAverages.forEach((day, avg) {
          if (avg < lowestAvgMood) {
            lowestAvgMood = avg;
            minMoodDay = day;
          }
        });
        if (lowestAvgMood < 3.0) {
          maxAnxietyDay = minMoodDay;
        }
      }

      // Find Critical Energy Day
      var maxEnergyDay = -1;
      var maxEnergyCount = 0;
      highEnergyCounts.forEach((day, count) {
        if (count > maxEnergyCount) {
          maxEnergyCount = count;
          maxEnergyDay = day;
        }
      });

      if (maxEnergyDay == -1) {
        var highestAvgEnergy = 0.0;
        var bestEnergyDay = -1;
        energyAverages.forEach((day, avg) {
          if (avg > highestAvgEnergy) {
            highestAvgEnergy = avg;
            bestEnergyDay = day;
          }
        });
        if (highestAvgEnergy > 2.0) {
          maxEnergyDay = bestEnergyDay;
        }
      }

      // Check for variations to prevent fake peaks on flat lines
      var hasMoodVariation = false;
      if (moodAverages.isNotEmpty) {
        final firstVal = moodAverages.values.first;
        hasMoodVariation = moodAverages.values.any((v) => v != firstVal);
      }
      if (!hasMoodVariation) {
        maxAnxietyDay = -1;
      }

      var hasEnergyVariation = false;
      if (energyAverages.isNotEmpty) {
        final firstVal = energyAverages.values.first;
        hasEnergyVariation = energyAverages.values.any((v) => v != firstVal);
      }
      if (!hasEnergyVariation) {
        maxEnergyDay = -1;
      }

      if (mounted) {
        setState(() {
          _dayMoodAverages = moodAverages;
          _maxAnxietyDay = maxAnxietyDay;
          _maxEnergyDay = maxEnergyDay;
          _logs = logsRows;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return RitmoTheme.glassCardLight(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xffEC4899)),
          ),
        ),
      );
    }

    if (_logs.length < 5) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(CupertinoIcons.heart_circle, color: Color(0xffEC4899), size: 36),
              const SizedBox(height: 12),
              Text(
                'هنوز در حالِ یادگیریِ الگوی احساست هستم 🌸',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'با ثبتِ روزانهی احوال، نمودار دقیقتر میشود.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'روند تغییرات خلق‌وخو در طول چرخه بدنی',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'این نمودار نوسانات خلق‌وخوی شما را در روزهای چرخه نشان می‌دهد (محور افقی روزهای دوره و محور عمودی سطح احوال است).',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white60 : colors.textSecondary,
                fontFamily: 'Vazirmatn',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              child: SizedBox(
                height: 160,
                child: CustomPaint(
                  painter: _MoodChartPainter(
                    moodAverages: _dayMoodAverages,
                    cycleLength: widget.averageCycleLength,
                    maxAnxietyDay: _maxAnxietyDay,
                    maxEnergyDay: _maxEnergyDay,
                    textColor: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.7),
                    gridColor: isDark ? Colors.white.withValues(alpha: 0.05) : colors.border.withValues(alpha: 0.1),
                    criticalTextColor: isDark ? Colors.white70 : colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendDot(const Color(0xffEC4899), 'میانگین خلق‌وخو (عالی تا کلافه)', isDark, colors),
                if (_maxAnxietyDay != -1)
                  _buildLegendDot(const Color(0xffF43F5E), 'نقطه اوج اضطراب/بی‌حوصلگی (روز ${_toPersianDigits(_maxAnxietyDay.toString())})', isDark, colors),
                if (_maxEnergyDay != -1)
                  _buildLegendDot(const Color(0xff4ADE80), 'نقطه اوج انرژی بالا (روز ${_toPersianDigits(_maxEnergyDay.toString())})', isDark, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark, RitmoColors colors) {
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
          style: TextStyle(
            fontSize: 10.5, 
            color: isDark ? Colors.white60 : colors.textSecondary, 
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}

class _MoodChartPainter extends CustomPainter {

  _MoodChartPainter({
    required this.moodAverages,
    required this.cycleLength,
    required this.maxAnxietyDay,
    required this.maxEnergyDay,
    required this.textColor,
    required this.gridColor,
    required this.criticalTextColor,
  });
  final Map<int, double> moodAverages;
  final int cycleLength;
  final int maxAnxietyDay;
  final int maxEnergyDay;
  final Color textColor;
  final Color gridColor;
  final Color criticalTextColor;

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
    const paddingLeft = 60.0; // Increased padding to prevent clipping of Farsi/Emoji labels
    const paddingBottom = 20.0;
    const paddingTop = 12.0;
    const paddingRight = 12.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final linePaint = Paint()
      ..color = const Color(0xffEC4899)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    // Emojis and labels for mood values
    final yLabels = {
      4.0: '😃 عالی',
      3.0: '🙂 خوب',
      2.0: '😐 بی‌حوصله',
      1.0: '😰 مضطرب',
      0.0: '😡 کلافه',
    };

    yLabels.forEach((val, label) {
      final y = paddingTop + chartHeight - (val / 4.0) * chartHeight;
      // Draw grid line
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Draw label on the left space
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(fontSize: 8.5, color: textColor, fontFamily: 'Vazirmatn'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - 6));
    });

    // Draw X-axis labels (Days)
    final xDays = [1, (cycleLength / 4).round(), (cycleLength / 2).round(), (3 * cycleLength / 4).round(), cycleLength];
    for (final day in xDays) {
      final x = paddingLeft + ((day - 1) / (cycleLength - 1)) * chartWidth;
      // Draw vertical tick
      canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartHeight), gridPaint);

      // Label
      textPainter.text = TextSpan(
        text: _toPersianDigits('روز $day'),
        style: TextStyle(fontSize: 8.5, color: textColor, fontFamily: 'Vazirmatn'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, paddingTop + chartHeight + 4));
    }

    // Prepare line points
    final points = <Offset>[];
    final sortedAverages = moodAverages.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedAverages) {
      final day = entry.key;
      final val = entry.value;
      if (day < 1 || day > cycleLength) continue;

      final x = paddingLeft + ((day - 1) / (cycleLength - 1)) * chartWidth;
      final y = paddingTop + chartHeight - (val / 4.0) * chartHeight;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      // Draw filled area underneath the curve
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      for (final pt in points) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xffEC4899).withValues(alpha: 0.18),
          const Color(0xffEC4899).withValues(alpha: 0),
        ],
      );
      fillPaint.shader = gradient.createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      // Draw the line
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Draw dots for each data point
      for (final pt in points) {
        dotPaint.color = const Color(0xffEC4899);
        canvas.drawCircle(pt, 3.5, dotPaint);
      }

      // Highlight Critical Points
      // 1. Max Anxiety Point
      if (maxAnxietyDay != -1 && moodAverages.containsKey(maxAnxietyDay)) {
        final val = moodAverages[maxAnxietyDay]!;
        final x = paddingLeft + ((maxAnxietyDay - 1) / (cycleLength - 1)) * chartWidth;
        final y = paddingTop + chartHeight - (val / 4.0) * chartHeight;

        // Draw Highlight Outer Ring
        dotPaint.color = const Color(0xffF43F5E).withValues(alpha: 0.25);
        canvas.drawCircle(Offset(x, y), 8, dotPaint);
        dotPaint.color = const Color(0xffF43F5E);
        canvas.drawCircle(Offset(x, y), 4.5, dotPaint);

        // Draw Label text above
        textPainter.text = const TextSpan(
          text: 'اوج بی‌حوصلگی 😰',
          style: TextStyle(fontSize: 8.5, color: Color(0xffF43F5E), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
        );
        textPainter.layout();
        final textX = x - textPainter.width / 2;
        const minX = paddingLeft + 4.0;
        final maxX = size.width - textPainter.width - 4.0;
        
        var labelY = y - 18;
        if (labelY < 2.0) {
          labelY = y + 8.0;
        }

        textPainter.paint(canvas, Offset(textX.clamp(minX, maxX), labelY));
      }

      // 2. Max Energy Point
      if (maxEnergyDay != -1 && moodAverages.containsKey(maxEnergyDay)) {
        final val = moodAverages[maxEnergyDay]!;
        final x = paddingLeft + ((maxEnergyDay - 1) / (cycleLength - 1)) * chartWidth;
        final y = paddingTop + chartHeight - (val / 4.0) * chartHeight;

        // Draw Highlight Outer Ring
        dotPaint.color = const Color(0xff4ADE80).withValues(alpha: 0.25);
        canvas.drawCircle(Offset(x, y), 8, dotPaint);
        dotPaint.color = const Color(0xff4ADE80);
        canvas.drawCircle(Offset(x, y), 4.5, dotPaint);

        // Draw Label text above or below (avoid overlap if same day)
        final isOverlap = (maxAnxietyDay == maxEnergyDay);
        var labelY = isOverlap ? y + 10.0 : y - 18;
        if (labelY < 2.0) {
          labelY = y + 8.0;
        }

        textPainter.text = const TextSpan(
          text: 'اوج انرژی ⚡',
          style: TextStyle(fontSize: 8.5, color: Color(0xff4ADE80), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
        );
        textPainter.layout();
        final textX = x - textPainter.width / 2;
        const minX = paddingLeft + 4.0;
        final maxX = size.width - textPainter.width - 4.0;

        textPainter.paint(canvas, Offset(textX.clamp(minX, maxX), labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
