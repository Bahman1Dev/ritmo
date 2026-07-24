import 'package:flutter/material.dart';

import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class NowPill extends StatelessWidget {
  const NowPill({
    super.key,
    required this.viewModel,
    this.onTapPill,
    this.onTapComplete,
    this.onTapJumpNow,
  });

  final NowPillViewModel viewModel;
  final VoidCallback? onTapPill;
  final VoidCallback? onTapComplete;
  final VoidCallback? onTapJumpNow;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isVisible || viewModel.targetItem == null) {
      return const SizedBox.shrink();
    }

    final item = viewModel.targetItem!;
    final isCurrent = viewModel.isCurrent;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final badgeColor = isCurrent ? theme.colorScheme.primary : Colors.amber.shade700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapPill,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
          child: Container(
            height: 44.0,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.40),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing/Live indicator dot
                RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, opacity, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor.withValues(alpha: isCurrent ? opacity : 1.0),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: CalendarTokens.spacingS),

                // Content
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCurrent ? 'الان: ' : 'بعدی: ',
                        style: TextStyle(
                          fontSize: CalendarTokens.textBody,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: CalendarTokens.textBody,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      Text(
                        ' · ${viewModel.timeLabel}',
                        style: TextStyle(
                          fontSize: CalendarTokens.textMeta,
                          fontWeight: FontWeight.w400,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.60),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: CalendarTokens.spacingS),

                if (onTapJumpNow != null)
                  IconButton(
                    icon: Icon(Icons.my_location_rounded, size: 18, color: badgeColor),
                    onPressed: onTapJumpNow,
                    tooltip: 'پرش به زمان فعلی',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),

                if (onTapComplete != null && !item.isCompleted)
                  IconButton(
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onTapComplete,
                    tooltip: 'تکمیل رویداد',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
