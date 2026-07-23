import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/l10n/app_localizations.dart';

/// کارت هیروی داشبورد: ادغام «نبض زندگی» و «خلاصه‌ی امروز» در یک کارت پرمیوم.
/// فقط لایه‌ی نمایش — همان داده‌های PulseCard و TodaySummaryCard قبلی.
/// نمودار هفتگی فقط وقتی نمایش داده می‌شود که داده‌ی واقعی (weeklyScores) پاس شود.
class PulseHeroCard extends StatelessWidget {

  const PulseHeroCard({
    super.key,
    required this.rhythmScore,
    required this.totalTasks,
    required this.completedTasks,
    this.nextTaskTitle,
    this.nextTaskTime,
    required this.onStartNext,
    this.onNavigateToTab,
    this.weeklyScores,
  });
  final int rhythmScore;
  final int totalTasks;
  final int completedTasks;
  final String? nextTaskTitle;
  final String? nextTaskTime;
  final VoidCallback onStartNext;
  final Function(int)? onNavigateToTab;

  /// امتیاز ۷ روز اخیر (قدیم → امروز). اگر null باشد نمودار مخفی می‌ماند
  /// تا داده‌ی ساختگی نمایش داده نشود.
  final List<int>? weeklyScores;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = RitmoMotion.reduceMotion(context);

    // متن حال‌وهوا بر اساس امتیاز (بدون سرزنش)
    var moodText = l10n.pulseCardMoodGood;
    if (rhythmScore >= 90) {
      moodText = l10n.pulseCardMoodExcellent;
    } else if (rhythmScore < 50) {
      moodText = l10n.pulseCardMoodRestore;
    }
    final scoreColor = rhythmScore >= 80 ? colors.success : colors.primary;

    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final remainingTasks = totalTasks - completedTasks;
    final allCompleted = totalTasks > 0 && remainingTasks == 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: RitmoRadius.cardLarge,
        color: colors.card.withValues(alpha: 0.65),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── بخش نبض (لمس → تب بینش‌ها) ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  RitmoHaptics.tap();
                  onNavigateToTab?.call(1);
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(RitmoRadius.cardLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RitmoSpacing.lg, RitmoSpacing.lg, RitmoSpacing.lg, RitmoSpacing.md),
                  child: Row(
                    children: [
                      _buildOrb(context),
                      const SizedBox(width: RitmoSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.pulseCardTitle,
                              style: RitmoTextStyles.caption(colors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                // شمارنده‌ی انیمیتی امتیاز (یک‌بار هنگام ورود)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: reduceMotion ? rhythmScore.toDouble() : 0,
                                    end: rhythmScore.toDouble(),
                                  ),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 700),
                                  curve: RitmoMotion.standard,
                                  builder: (context, value, _) => Text(
                                    toPersianDigits('${value.round()}'),
                                    style: RitmoTextStyles.heroNumber(scoreColor),
                                  ),
                                ),
                                const SizedBox(width: RitmoSpacing.sm),
                                Text(
                                  moodText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                            if (weeklyScores != null && weeklyScores!.isNotEmpty) ...[
                              const SizedBox(height: RitmoSpacing.md),
                              _buildWeeklyChart(colors),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── جداکننده‌ی ظریف ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RitmoSpacing.lg),
              child: Divider(height: 1, color: colors.border),
            ),

            // ── بخش خلاصه‌ی امروز ──
            Padding(
              padding: const EdgeInsets.all(RitmoSpacing.lg),
              child: Row(
                children: [
                  // حلقه‌ی پیشرفت
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: reduceMotion ? progress : 0,
                            end: progress,
                          ),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 700),
                          curve: RitmoMotion.standard,
                          builder: (context, value, _) => CustomPaint(
                            size: const Size(56, 56),
                            painter: _RingPainter(
                              progress: value,
                              backgroundColor:
                                  colors.textPrimary.withValues(alpha: 0.07),
                              gradientColors: colors.energyGradient,
                            ),
                          ),
                        ),
                        Text(
                          toPersianDigits('$completedTasks/$totalTasks'),
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
                  const SizedBox(width: RitmoSpacing.lg),

                  // متن وضعیت + گام بعدی
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalTasks == 0
                              ? 'امروز روتینی برنامه‌ریزی نشده'
                              : allCompleted
                                  ? 'امروزت کامل شد. عالی بودی! ✨'
                                  : '${toPersianDigits('$completedTasks')} از ${toPersianDigits('$totalTasks')} کار انجام شد · ${toPersianDigits('$remainingTasks')} مانده',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: allCompleted
                                ? colors.success
                                : colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        if (!allCompleted && nextTaskTitle != null) ...[
                          const SizedBox(height: RitmoSpacing.xs),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'گام بعدی: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                TextSpan(
                                  text: nextTaskTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                if (nextTaskTime != null)
                                  TextSpan(
                                    text:
                                        ' · ${toPersianDigits(nextTaskTime!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // دکمه‌ی شروع
                  if (!allCompleted && nextTaskTitle != null) ...[
                    const SizedBox(width: RitmoSpacing.md),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          RitmoHaptics.confirm();
                          onStartNext();
                        },
                        borderRadius: BorderRadius.circular(RitmoRadius.chip),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors.energyGradient
                                  .map((c) => c.withValues(alpha: 0.16))
                                  .toList(),
                            ),
                            borderRadius:
                                BorderRadius.circular(RitmoRadius.chip),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.play_arrow_solid,
                                  size: 11, color: colors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'شروع',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (allCompleted)
                    Icon(CupertinoIcons.checkmark_seal_fill,
                        color: colors.success, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// لوگوی اپ با هاله‌ی گرادیانِ انرژی (همان orb قبلی، پرداخت‌شده)
  Widget _buildOrb(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.energyGradient.first.withValues(alpha: 0.28),
                colors.energyGradient.last.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            boxShadow: [
              BoxShadow(
                color: colors.primary
                    .withValues(alpha: isDarkMode ? 0.3 : 0.12),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  /// نمودار میله‌ای ۷ روزه — فقط با داده‌ی واقعی
  Widget _buildWeeklyChart(RitmoColors colors) {
    final scores = weeklyScores!;
    final now = DateTime.now();
    const dayNames = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    final count = scores.length.clamp(0, 7);
    final labels = List.generate(count, (i) {
      final day = now.subtract(Duration(days: count - 1 - i));
      return dayNames[day.weekday - 1];
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (index) {
        final score = scores[scores.length - count + index];
        final isToday = index == count - 1;
        final barHeight = (score / 100.0) * 32.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              width: 12,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                height: barHeight.clamp(2.0, 32.0),
                width: isToday ? 8.0 : 6.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isToday
                        ? colors.energyGradient
                        : colors.energyGradient
                            .map((c) => c.withValues(alpha: 0.55))
                            .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: RitmoSpacing.xs),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? colors.primary : colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RingPainter extends CustomPainter {

  _RingPainter({
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

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (progress > 0) {
      final rect =
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          stops: const [0.0, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
