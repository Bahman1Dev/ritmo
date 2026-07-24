import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class TimelineHourAxis extends StatelessWidget {
  const TimelineHourAxis({
    super.key,
    required this.pxPerMinute,
    this.axisWidth = CalendarTokens.hourAxisWidth,
  });

  final double pxPerMinute;
  final double axisWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nowHour = DateTime.now().hour;

    return SizedBox(
      width: axisWidth,
      height: 1440 * pxPerMinute,
      child: Stack(
        children: [
          for (var h = 0; h <= 24; h++)
            Positioned(
              top: (h * 60 * pxPerMinute) - 7,
              left: CalendarTokens.spacingXs,
              right: CalendarTokens.spacingS,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  toPersianDigits('${h.toString().padLeft(2, '0')}:00'),
                  style: TextStyle(
                    fontSize: CalendarTokens.textLabel,
                    fontWeight: h == nowHour ? FontWeight.w700 : FontWeight.w500,
                    color: h == nowHour
                        ? theme.colorScheme.primary
                        : (h < nowHour
                            ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.25)
                            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.40)),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TimelineGridLines extends StatelessWidget {
  const TimelineGridLines({
    super.key,
    required this.pxPerMinute,
  });

  final double pxPerMinute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 1440 * pxPerMinute,
      child: CustomPaint(
        size: Size(double.infinity, 1440 * pxPerMinute),
        painter: _GridLinesPainter(
          pxPerMinute: pxPerMinute,
          lineColor: theme.dividerColor.withValues(alpha: 0.08),
          halfHourLineColor: theme.dividerColor.withValues(alpha: 0.04),
        ),
      ),
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  _GridLinesPainter({
    required this.pxPerMinute,
    required this.lineColor,
    required this.halfHourLineColor,
  });

  final double pxPerMinute;
  final Color lineColor;
  final Color halfHourLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final halfPaint = Paint()
      ..color = halfHourLineColor
      ..strokeWidth = 0.3;

    for (var h = 0; h <= 24; h++) {
      final y = h * 60 * pxPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mainPaint);

      if (h < 24) {
        final halfY = y + (30 * pxPerMinute);
        canvas.drawLine(Offset(0, halfY), Offset(size.width, halfY), halfPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) =>
      oldDelegate.pxPerMinute != pxPerMinute ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.halfHourLineColor != halfHourLineColor;
}
