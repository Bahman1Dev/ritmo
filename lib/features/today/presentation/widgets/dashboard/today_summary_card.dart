import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class TodaySummaryCard extends StatelessWidget {

  const TodaySummaryCard({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    this.nextTaskTitle,
    this.nextTaskTime,
    required this.onStartNext,
  });
  final int totalTasks;
  final int completedTasks;
  final String? nextTaskTitle;
  final String? nextTaskTime;
  final VoidCallback onStartNext;

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


    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final remainingTasks = totalTasks - completedTasks;
    final allCompleted = totalTasks > 0 && remainingTasks == 0;

    var progressFractionText = _toPersianDigits('$completedTasks/$totalTasks');
    if (totalTasks == 0) {
      progressFractionText = _toPersianDigits('0/0');
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 16,
        color: colors.card.withValues(alpha: 0.65),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Row
              Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(60, 60),
                          painter: _CircularProgressPainter(
                            progress: progress,
                            backgroundColor: colors.textPrimary.withValues(alpha: 0.07),
                            gradientColors: const [
                              Color(0xff6B9EFF),
                              Color(0xff9B89FF),
                            ],
                          ),
                        ),
                        Text(
                          progressFractionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Progress Description Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خلاصه امروز',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalTasks == 0
                              ? 'هیچ روتینی برای امروز برنامه‌ریزی نشده است.'
                              : allCompleted
                                  ? 'همه کارها با موفقیت انجام شد! 🎉'
                                  : '${_toPersianDigits('$completedTasks')} از ${_toPersianDigits('$totalTasks')} کار انجام شد · ${_toPersianDigits('$remainingTasks')} کار مانده',
                          style: TextStyle(
                            fontSize: 12,
                            color: allCompleted ? colors.success : colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Conditional State (Congratulations or Next Step)
              if (totalTasks > 0) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Colors.transparent), // invisible divider just for spacing
                if (allCompleted)
                  // Congratulations panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.success.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_seal_fill, color: colors.success, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'امروزت کامل شد. عالی بودی! ✨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.success,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  )
                else if (nextTaskTitle != null)
                  // Next task preview panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.textPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'گام بعدی:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextTaskTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              if (nextTaskTime != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'ساعت ${_toPersianDigits(nextTaskTime!)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Glassmorphic start button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onStartNext,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.15), width: 1.2),
                              ),
                              child: Text(
                                'شروع',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.gradientColors,
  });
  final double progress;
  final Color backgroundColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 6.0;

    // Background circle paint
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Active progress arc paint
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          stops: const [0.0, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw the arc
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from the top
        progress * 2 * math.pi, // Sweep angle
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
