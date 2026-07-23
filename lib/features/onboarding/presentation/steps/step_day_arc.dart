import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class StepDayArc extends StatefulWidget {

  const StepDayArc({
    super.key,
    required this.wakeTime,
    required this.onWakeTimeChanged,
    required this.sleepTime,
    required this.onSleepTimeChanged,
  });
  final String wakeTime;
  final ValueChanged<String> onWakeTimeChanged;
  final String sleepTime;
  final ValueChanged<String> onSleepTimeChanged;

  @override
  State<StepDayArc> createState() => _StepDayArcState();
}

class _StepDayArcState extends State<StepDayArc> {
  // Parsing helpers
  double _parseTimeToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = double.parse(parts[0]);
      final m = double.parse(parts[1]);
      return h + m / 60.0;
    } catch (_) {
      return 7;
    }
  }

  String _formatDoubleToTime(double val) {
    final h = val.toInt();
    final m = ((val - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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

  // Active dragging handle: 'NONE', 'WAKE', 'SLEEP'
  String _activeHandle = 'NONE';

  // Clock calculations (Clockwise rotation, 00:00 starts at the TOP)
  Offset _getHandleOffset(double hour, double radius, Offset center) {
    // 00:00 is at the top (angle = -pi/2), clockwise rotation
    final angle = (hour / 24.0) * 2.0 * pi - pi / 2.0;
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }

  double _getHourFromOffset(Offset localPos, Offset center) {
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final angle = atan2(dy, dx);
    // Adjust angle to start from top (-pi/2) and increase clockwise
    var adjustedAngle = angle + pi / 2.0;
    if (adjustedAngle < 0) {
      adjustedAngle += 2.0 * pi;
    }
    final timeFraction = adjustedAngle / (2.0 * pi);
    var hours = timeFraction * 24.0;
    // Snap to 30 mins (0.5 hours)
    hours = (hours * 2.0).round() / 2.0;
    if (hours >= 24.0) {
      hours -= 24.0;
    }
    return hours;
  }

  double _getWakefulnessDuration() {
    final w = _parseTimeToDouble(widget.wakeTime);
    var s = _parseTimeToDouble(widget.sleepTime);
    if (s < w) {
      s += 24.0;
    }
    return s - w;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wakeHour = _parseTimeToDouble(widget.wakeTime);
    final sleepHour = _parseTimeToDouble(widget.sleepTime);
    final wakeDuration = _getWakefulnessDuration();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ریتم بیداری و خواب شما',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'با جابجا کردن خورشید ☀️ و ماه 🌙 ساعت بیداری و خواب را تنظیم کنید.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                const radius = 100.0;

                final wakeOffset = _getHandleOffset(wakeHour, radius, center);
                final sleepOffset = _getHandleOffset(sleepHour, radius, center);

                return GestureDetector(
                  onPanStart: (details) {
                    final pos = details.localPosition;
                    final distToWake = (pos - wakeOffset).distance;
                    final distToSleep = (pos - sleepOffset).distance;

                    if (distToWake < distToSleep && distToWake < 35) {
                      _activeHandle = 'WAKE';
                      HapticFeedback.selectionClick();
                    } else if (distToSleep < distToWake && distToSleep < 35) {
                      _activeHandle = 'SLEEP';
                      HapticFeedback.selectionClick();
                    } else {
                      _activeHandle = 'NONE';
                    }
                  },
                  onPanUpdate: (details) {
                    if (_activeHandle == 'NONE') return;

                    final hours = _getHourFromOffset(details.localPosition, center);
                    final timeStr = _formatDoubleToTime(hours);

                    if (_activeHandle == 'WAKE') {
                      if (timeStr != widget.wakeTime) {
                        widget.onWakeTimeChanged(timeStr);
                        HapticFeedback.lightImpact();
                      }
                    } else if (_activeHandle == 'SLEEP') {
                      if (timeStr != widget.sleepTime) {
                        widget.onSleepTimeChanged(timeStr);
                        HapticFeedback.lightImpact();
                      }
                    }
                  },
                  onPanEnd: (_) {
                    _activeHandle = 'NONE';
                  },
                  child: Stack(
                    children: [
                      // Arc Ring custom paint
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DayArcPainter(
                            wakeHour: wakeHour,
                            sleepHour: sleepHour,
                            radius: radius,
                            colors: colors,
                          ),
                        ),
                      ),
                      // Center Live Text
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _toPersianDigits('${(24.0 - wakeDuration).toStringAsFixed((24.0 - wakeDuration) % 1 == 0 ? 0 : 1)} ساعت خواب'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff9B89FF),
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _toPersianDigits('${wakeDuration.toStringAsFixed(wakeDuration % 1 == 0 ? 0 : 1)} ساعت بیداری'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Wake Handle (Sun)
                      Positioned(
                        left: wakeOffset.dx - 18,
                        top: wakeOffset.dy - 18,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('☀️', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                      // Sleep Handle (Moon)
                      Positioned(
                        left: sleepOffset.dx - 18,
                        top: sleepOffset.dy - 18,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xff5C6BC0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff5C6BC0).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌙', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTimeInfoCard(context, 'ساعت بیداری', _toPersianDigits(widget.wakeTime), Colors.orange),
            _buildTimeInfoCard(context, 'ساعت خواب', _toPersianDigits(widget.sleepTime), const Color(0xff9B89FF)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInfoCard(BuildContext context, String label, String value, Color color) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}

class DayArcPainter extends CustomPainter {

  DayArcPainter({
    required this.wakeHour,
    required this.sleepHour,
    required this.radius,
    required this.colors,
  });
  final double wakeHour;
  final double sleepHour;
  final double radius;
  final RitmoColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Night arc paint (from sleep to wake) - styled in deep purple/indigo
    final nightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff5C6BC0).withValues(alpha: 0.35);

    // Thin guide ring for background
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = colors.textPrimary.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius, guidePaint);

    // Angles: 00:00 starts at top (-pi/2)
    final startAngle = (wakeHour / 24.0) * 2.0 * pi - pi / 2.0;
    final endAngle = (sleepHour / 24.0) * 2.0 * pi - pi / 2.0;

    // Draw Sleep arc (night, from sleep to wake)
    var sleepSweepAngle = startAngle - endAngle;
    if (sleepSweepAngle < 0) {
      sleepSweepAngle += 2.0 * pi;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      endAngle,
      sleepSweepAngle,
      false,
      nightPaint,
    );

    // Draw Day arc (wakefulness, from wake to sleep) - styled in orange/yellow daylight
    var daySweepAngle = endAngle - startAngle;
    if (daySweepAngle < 0) {
      daySweepAngle += 2.0 * pi;
    }

    final dayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.orange,
          Color(0xffF57C00),
          Colors.orange,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      daySweepAngle,
      false,
      dayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DayArcPainter oldDelegate) {
    return oldDelegate.wakeHour != wakeHour ||
        oldDelegate.sleepHour != sleepHour ||
        oldDelegate.radius != radius;
  }
}
