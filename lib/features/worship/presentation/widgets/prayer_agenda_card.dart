import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class PrayerAgendaCard extends StatelessWidget {
  const PrayerAgendaCard({
    super.key,
    required this.title,
    required this.timeStr,
    required this.isDone,
    required this.isSkipped,
    required this.isSnoozed,
    this.snoozeText,
    required this.deferCount,
    required this.hasReminder,
    this.disableControls = false,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isExempt = false,
    this.expiredTimeDetail,
    this.onToggle,
    this.onSnooze,
    this.onSkip,
    this.onLogAsQada,
    this.onReminderSettings,
  });

  final String title;
  final String timeStr;
  final bool isDone;
  final bool isSkipped;
  final bool isSnoozed;
  final String? snoozeText;
  final int deferCount;
  final bool hasReminder;
  final bool disableControls;
  final bool isExpiringSoon;
  final bool isExpired;
  final bool isExempt;
  final String? expiredTimeDetail;

  final ValueChanged<bool>? onToggle;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final VoidCallback? onLogAsQada;
  final VoidCallback? onReminderSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    var cardBg = Colors.transparent;
    var borderCol = Colors.transparent;

    if (!isDone && !isSkipped && !isExempt) {
      if (isExpired) {
        cardBg = colors.error.withValues(alpha: 0.08);
        borderCol = colors.error.withValues(alpha: 0.25);
      } else if (isExpiringSoon) {
        cardBg = colors.warning.withValues(alpha: 0.08);
        borderCol = colors.warning.withValues(alpha: 0.25);
      }
    }

    final actualDisable = disableControls || isSkipped || isExempt;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: borderCol == Colors.transparent ? null : Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Checkbox / State Indicator
              if (isExempt)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    CupertinoIcons.minus_circle,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                )
              else
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isDone,
                    onChanged: actualDisable
                        ? null
                        : (val) {
                            if (val != null && onToggle != null) {
                              onToggle!(val);
                            }
                          },
                    activeColor: colors.primary,
                    checkColor: colors.onPrimary,
                    side: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Title & Time Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? colors.textSecondary.withValues(alpha: 0.7)
                            : (isSkipped || isExempt
                                ? colors.textSecondary.withValues(alpha: 0.5)
                                : colors.textPrimary),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (snoozeText != null && !isDone && !isSkipped && !isExempt) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              snoozeText!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'رد شده (قضا)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isExempt) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surfaceSunken,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'معاف',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!isDone && !isSkipped && !isExempt && !disableControls) ...[
                // Snooze Button
                Semantics(
                  label: 'تعویق یادآور',
                  button: true,
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      isSnoozed ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
                      color: deferCount >= 2
                          ? colors.textTertiary.withValues(alpha: 0.3)
                          : (isSnoozed ? colors.accent : colors.textSecondary),
                      size: 19,
                    ),
                    tooltip: deferCount >= 2 ? 'حداکثر تعویق' : 'تعویق',
                    onPressed: deferCount >= 2 ? null : onSnooze,
                  ),
                ),

                // Skip Button
                Semantics(
                  label: 'رد کردن و افزودن به قضا',
                  button: true,
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      CupertinoIcons.clear_circled,
                      color: isExpired ? colors.error : colors.textSecondary,
                      size: 19,
                    ),
                    tooltip: 'رد کردن و افزودن به قضا',
                    onPressed: onSkip,
                  ),
                ),
              ],
            ],
          ),

          // Expired Banner Action
          if (isExpired && !isDone && !isSkipped && !isExempt) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle, color: colors.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      expiredTimeDetail ?? 'وقت این نماز گذشته است.',
                      style: TextStyle(
                        color: colors.error,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onLogAsQada != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: onLogAsQada,
                      child: const Text(
                        'خواندم (قضا)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
