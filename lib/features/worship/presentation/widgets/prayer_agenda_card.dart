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
    this.onToggle,
    this.onSnooze,
    this.onSkip,
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

  final ValueChanged<bool>? onToggle;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final VoidCallback? onReminderSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    var cardBg = Colors.transparent;
    var borderCol = Colors.transparent;

    if (!isDone && !isSkipped) {
      if (isExpired) {
        cardBg = colors.medicalRed.withValues(alpha: 0.08);
        borderCol = colors.medicalRed.withValues(alpha: 0.2);
      } else if (isExpiringSoon) {
        cardBg = colors.warning.withValues(alpha: 0.08);
        borderCol = colors.warning.withValues(alpha: 0.2);
      }
    }

    final actualDisable = disableControls || isSkipped;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 2),
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
              // Checkbox Done
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
                  activeColor: const Color(0xffD4A843),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Text & Time
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
                            : (isSkipped ? colors.textSecondary.withValues(alpha: 0.5) : colors.textPrimary),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontFamily: 'Vazirmatn',
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
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        if (snoozeText != null && !isDone && !isSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.textSecondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              snoozeText!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xffD4A843),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                        if (isSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.medicalRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'رد شده (قضا)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (!isDone && !isSkipped && !disableControls) ...[
                // Snooze Button
                IconButton(
                  icon: Icon(
                    isSnoozed ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
                    color: deferCount >= 3 
                        ? colors.textSecondary.withValues(alpha: 0.2) 
                        : (isSnoozed ? const Color(0xffD4A843) : colors.textSecondary.withValues(alpha: 0.6)),
                    size: 19,
                  ),
                  tooltip: deferCount >= 3 ? 'حداکثر تعویق' : 'تعویق',
                  onPressed: deferCount >= 3 ? null : onSnooze,
                ),

                // Skip Button
                IconButton(
                  icon: Icon(
                    CupertinoIcons.clear_circled,
                    color: isExpired 
                        ? colors.medicalRed 
                        : colors.textSecondary.withValues(alpha: 0.6),
                    size: 19,
                  ),
                  tooltip: 'رد کردن و افزودن به قضا',
                  onPressed: onSkip,
                ),
              ],

            ],
          ),
          if (isExpired && !isDone && !isSkipped) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.medicalRed, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'وقت نماز گذشته است. مایلید آن را به قضا منتقل کنید؟',
                    style: TextStyle(
                      color: colors.medicalRed,
                      fontSize: 11,
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
