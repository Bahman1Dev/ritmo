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
    this.isInferred = false,
    this.reasonFa = '',
  });

  final String wakeTime;
  final ValueChanged<String> onWakeTimeChanged;
  final String sleepTime;
  final ValueChanged<String> onSleepTimeChanged;
  final bool isInferred;
  final String reasonFa;

  @override
  State<StepDayArc> createState() => _StepDayArcState();
}

class _StepDayArcState extends State<StepDayArc> {
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

  String _activeHandle = 'NONE';

  Offset _getHandleOffset(double hour, double radius, Offset center) {
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
    var adjustedAngle = angle + pi / 2.0;
    if (adjustedAngle < 0) {
      adjustedAngle += 2.0 * pi;
    }
    final timeFraction = adjustedAngle / (2.0 * pi);
    var hours = timeFraction * 24.0;
    hours = (hours * 2.0).round() / 2.0;
    if (hours >= 24.0) {
      hours = 0.0;
    }
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final wakeVal = _parseTimeToDouble(widget.wakeTime);
    final sleepVal = _parseTimeToDouble(widget.sleepTime);

    double activeHours;
    if (sleepVal >= wakeVal) {
      activeHours = sleepVal - wakeVal;
    } else {
      activeHours = (24.0 - wakeVal) + sleepVal;
    }

    final activeHoursInt = activeHours.toInt();
    final activeMinutesInt = ((activeHours - activeHoursInt) * 60).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'قوس روز شما',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ساعات بیداری و خواب خود را تنظیم کنید تا ریتم برنامه‌های شما به‌درستی شکل گیرد.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),

        if (widget.reasonFa.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isInferred
                  ? const Color(0xff9B89FF).withValues(alpha: 0.12)
                  : colors.textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isInferred
                    ? const Color(0xff9B89FF).withValues(alpha: 0.3)
                    : colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              widget.reasonFa,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 24-Hour Circular Drag Dial
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = min(constraints.maxWidth, constraints.maxHeight);
              final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
              final radius = size / 2 - 24;

              final wakeOffset = _getHandleOffset(wakeVal, radius, center);
              final sleepOffset = _getHandleOffset(sleepVal, radius, center);

              return GestureDetector(
                onPanStart: (details) {
                  final pos = details.localPosition;
                  final dWake = (pos - wakeOffset).distance;
                  final dSleep = (pos - sleepOffset).distance;

                  if (dWake < 30) {
                    _activeHandle = 'WAKE';
                  } else if (dSleep < 30) {
                    _activeHandle = 'SLEEP';
                  } else {
                    _activeHandle = 'NONE';
                  }
                },
                onPanUpdate: (details) {
                  if (_activeHandle == 'NONE') return;

                  final pos = details.localPosition;
                  final newHour = _getHourFromOffset(pos, center);
                  final timeStr = _formatDoubleToTime(newHour);

                  HapticFeedback.selectionClick();

                  if (_activeHandle == 'WAKE') {
                    widget.onWakeTimeChanged(timeStr);
                  } else if (_activeHandle == 'SLEEP') {
                    widget.onSleepTimeChanged(timeStr);
                  }
                },
                onPanEnd: (_) {
                  _activeHandle = 'NONE';
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _DayArcClockPainter(
                    wakeVal: wakeVal,
                    sleepVal: sleepVal,
                    colors: colors,
                    radius: radius,
                    center: center,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Readout Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatTile(
              title: 'ساعت بیداری',
              value: _toPersianDigits(widget.wakeTime),
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xffF59E0B),
            ),
            _StatTile(
              title: 'مدت بیداری',
              value: _toPersianDigits('$activeHoursInt س $activeMinutesInt د'),
              icon: Icons.timelapse_rounded,
              color: const Color(0xff9B89FF),
            ),
            _StatTile(
              title: 'ساعت خواب',
              value: _toPersianDigits(widget.sleepTime),
              icon: Icons.nightlight_round,
              color: const Color(0xff3B82F6),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}

class _DayArcClockPainter extends CustomPainter {
  _DayArcClockPainter({
    required this.wakeVal,
    required this.sleepVal,
    required this.colors,
    required this.radius,
    required this.center,
  });

  final double wakeVal;
  final double sleepVal;
  final RitmoColors colors;
  final double radius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final bgArcPaint = Paint()
      ..color = colors.textPrimary.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgArcPaint);

    final activeArcPaint = Paint()
      ..color = const Color(0xff9B89FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final startAngle = (wakeVal / 24.0) * 2.0 * pi - pi / 2.0;
    double sweepAngle;
    if (sleepVal >= wakeVal) {
      sweepAngle = ((sleepVal - wakeVal) / 24.0) * 2.0 * pi;
    } else {
      sweepAngle = (((24.0 - wakeVal) + sleepVal) / 24.0) * 2.0 * pi;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activeArcPaint,
    );

    final wakeAngle = (wakeVal / 24.0) * 2.0 * pi - pi / 2.0;
    final wakePos = Offset(
      center.dx + radius * cos(wakeAngle),
      center.dy + radius * sin(wakeAngle),
    );

    final sleepAngle = (sleepVal / 24.0) * 2.0 * pi - pi / 2.0;
    final sleepPos = Offset(
      center.dx + radius * cos(sleepAngle),
      center.dy + radius * sin(sleepAngle),
    );

    final handleBg = Paint()..color = Colors.white;
    final wakeBorder = Paint()..color = const Color(0xffF59E0B);
    final sleepBorder = Paint()..color = const Color(0xff3B82F6);

    canvas.drawCircle(wakePos, 14, wakeBorder);
    canvas.drawCircle(wakePos, 10, handleBg);

    canvas.drawCircle(sleepPos, 14, sleepBorder);
    canvas.drawCircle(sleepPos, 10, handleBg);
  }

  @override
  bool shouldRepaint(covariant _DayArcClockPainter oldDelegate) => true;
}
