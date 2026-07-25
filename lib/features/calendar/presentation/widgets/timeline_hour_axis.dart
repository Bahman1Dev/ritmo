import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

enum HourAxisSide { leading, trailing }

class TimelineHourAxis extends StatelessWidget {
  const TimelineHourAxis({
    super.key,
    required this.pxPerMinute,
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
    this.width = CalendarTokens.hourAxisWidth,
    this.side = HourAxisSide.leading,
    this.labelFontSize = CalendarTokens.textLabel,
  });

  final double pxPerMinute;
  final int rangeStartMinutes;
  final int rangeEndMinutes;
  final double width;
  final HourAxisSide side;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nowHour = DateTime.now().hour;
    final startHour = (rangeStartMinutes / 60.0).ceil();
    final endHour = (rangeEndMinutes / 60.0).floor();
    final rangeHeight = (rangeEndMinutes - rangeStartMinutes) * pxPerMinute;

    final isLeading = side == HourAxisSide.leading;

    return SizedBox(
      width: width,
      height: rangeHeight,
      child: Stack(
        children: [
          for (var h = startHour; h <= endHour; h++)
            Positioned(
              top: ((h * 60) - rangeStartMinutes) * pxPerMinute - 7,
              left: isLeading ? CalendarTokens.spacingXs : 0,
              right: isLeading ? 0 : CalendarTokens.spacingXs,
              child: Align(
                alignment: isLeading ? Alignment.centerLeft : Alignment.centerRight,
                child: Text(
                  toPersianDigits('${h.toString().padLeft(2, '0')}:00'),
                  style: TextStyle(
                    fontSize: labelFontSize,
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
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
  });

  final double pxPerMinute;
  final int rangeStartMinutes;
  final int rangeEndMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeHeight = (rangeEndMinutes - rangeStartMinutes) * pxPerMinute;

    return SizedBox(
      height: rangeHeight,
      child: CustomPaint(
        size: Size(double.infinity, rangeHeight),
        painter: _GridLinesPainter(
          pxPerMinute: pxPerMinute,
          rangeStartMinutes: rangeStartMinutes,
          rangeEndMinutes: rangeEndMinutes,
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
    required this.rangeStartMinutes,
    required this.rangeEndMinutes,
    required this.lineColor,
    required this.halfHourLineColor,
  });

  final double pxPerMinute;
  final int rangeStartMinutes;
  final int rangeEndMinutes;
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

    final startHour = (rangeStartMinutes / 60.0).ceil();
    final endHour = (rangeEndMinutes / 60.0).floor();

    for (var h = startHour; h <= endHour; h++) {
      final y = ((h * 60) - rangeStartMinutes) * pxPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mainPaint);

      if (h < endHour) {
        final halfY = y + (30 * pxPerMinute);
        if (halfY <= size.height) {
          canvas.drawLine(Offset(0, halfY), Offset(size.width, halfY), halfPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) =>
      oldDelegate.pxPerMinute != pxPerMinute ||
      oldDelegate.rangeStartMinutes != rangeStartMinutes ||
      oldDelegate.rangeEndMinutes != rangeEndMinutes ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.halfHourLineColor != halfHourLineColor;
}
