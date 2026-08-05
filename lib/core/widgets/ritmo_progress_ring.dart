import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';

class RitmoProgressRing extends StatelessWidget {
  const RitmoProgressRing({
    super.key,
    required this.value,
    this.confidence = 1.0,
    this.lowerBound,
    this.upperBound,
    this.size = 140.0,
    this.strokeWidth = 10.0,
    this.onTap,
  });

  final double? value;
  final double confidence;
  final double? lowerBound;
  final double? upperBound;
  final double size;
  final double strokeWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    final widgetContent = SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: value ?? 0.0),
        duration: disableAnim ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, _) {
          return CustomPaint(
            painter: _RingPainter(
              value: value == null ? null : animValue,
              confidence: confidence,
              lowerBound: lowerBound,
              upperBound: upperBound,
              strokeWidth: strokeWidth,
              trackColor: colors.surfaceSunken,
              activeColor: colors.primary,
              uncertaintyColor: colors.primary.withValues(alpha: 0.25),
              textColor: colors.textPrimary,
              subtitleColor: colors.textSecondary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value == null) ...[
                    Text(
                      '؟',
                      style: TextStyle(
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.w700,
                        color: colors.textTertiary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'نامشخص',
                      style: RitmoTextStyles.caption(colors.textSecondary),
                    ),
                  ] else ...[
                    Text(
                      RitmoNumber.faInt(animValue),
                      style: TextStyle(
                        fontSize: size * 0.26,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'از ۱۰۰',
                      style: RitmoTextStyles.caption(colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: widgetContent,
      );
    }
    return widgetContent;
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.confidence,
    required this.lowerBound,
    required this.upperBound,
    required this.strokeWidth,
    required this.trackColor,
    required this.activeColor,
    required this.uncertaintyColor,
    required this.textColor,
    required this.subtitleColor,
  });

  final double? value;
  final double confidence;
  final double? lowerBound;
  final double? upperBound;
  final double strokeWidth;
  final Color trackColor;
  final Color activeColor;
  final Color uncertaintyColor;
  final Color textColor;
  final Color subtitleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (value == null) return;

    // Draw uncertainty band P-3 behind main arc if confidence < 0.8
    if (confidence < 0.8 && lowerBound != null && upperBound != null) {
      final startAngle = -math.pi / 2 + (lowerBound! / 100.0) * 2 * math.pi;
      final sweepAngle = ((upperBound! - lowerBound!) / 100.0) * 2 * math.pi;

      final uncertaintyPaint = Paint()
        ..color = uncertaintyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, uncertaintyPaint);
    }

    // Draw main arc
    final mainSweep = (value! / 100.0) * 2 * math.pi;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, mainSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.confidence != confidence ||
        oldDelegate.lowerBound != lowerBound ||
        oldDelegate.upperBound != upperBound ||
        oldDelegate.activeColor != activeColor;
  }
}
