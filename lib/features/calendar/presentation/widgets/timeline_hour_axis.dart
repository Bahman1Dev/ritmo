import 'package:flutter/material.dart';

class TimelineHourAxis extends StatelessWidget {
  const TimelineHourAxis({
    super.key,
    required this.pxPerMinute,
    this.axisWidth = 56.0,
  });

  final double pxPerMinute;
  final double axisWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axisWidth,
      height: 1440 * pxPerMinute,
      child: Stack(
        children: [
          for (var h = 0; h <= 24; h++)
            Positioned(
              top: (h * 60 * pxPerMinute) - 8,
              left: 4,
              right: 8,
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? Colors.grey,
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
    return SizedBox(
      height: 1440 * pxPerMinute,
      child: CustomPaint(
        size: Size(double.infinity, 1440 * pxPerMinute),
        painter: _GridLinesPainter(
          pxPerMinute: pxPerMinute,
          lineColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  _GridLinesPainter({
    required this.pxPerMinute,
    required this.lineColor,
  });

  final double pxPerMinute;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (var h = 0; h <= 24; h++) {
      final y = h * 60 * pxPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) =>
      oldDelegate.pxPerMinute != pxPerMinute || oldDelegate.lineColor != lineColor;
}
