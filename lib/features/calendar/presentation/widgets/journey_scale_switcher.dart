import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

/// K18 — Redesigned scale switcher: 3 primary tabs (برنامه · روز · ماه)
/// + overflow ⋯ button for week and year.
///
/// Design rules (from 067.md §8):
/// - Exactly 3 visible tabs; no scrollable/ellipsis text.
/// - Week and year live in the ⋯ overflow popup.
/// - When week or year is active, the 3-tab strip shows no selection
///   and the ⋯ button highlights with the active scale's label.
class JourneyScaleSwitcher extends StatelessWidget {
  const JourneyScaleSwitcher({
    super.key,
    required this.activeScale,
    required this.onScaleChanged,
  });

  final JourneyScale activeScale;
  final ValueChanged<JourneyScale> onScaleChanged;

  // The three primary scales shown inline
  static const List<JourneyScale> _primaryScales = [
    JourneyScale.agenda,
    JourneyScale.day,
    JourneyScale.month,
  ];

  // Overflow scales (week, year)
  static const List<JourneyScale> _overflowScales = [
    JourneyScale.week,
    JourneyScale.year,
  ];

  bool get _isOverflowActive => _overflowScales.contains(activeScale);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          // ─── 3-Tab Strip ───
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(CalendarTokens.spacingXs),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
                border: Border.all(
                  color:
                      theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
                ),
              ),
              child: Row(
                children: _primaryScales.map((scale) {
                  final isSelected = !_isOverflowActive && scale == activeScale;
                  final label = _primaryLabelFa(scale);
                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      label: 'نمای $label',
                      button: true,
                      child: GestureDetector(
                        onTap: () => onScaleChanged(scale),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: CalendarTokens.durationStandard,
                          curve: CalendarTokens.curveEmphasis,
                          height: 40.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? theme.colorScheme.surfaceContainerHigh
                                    : theme.cardColor)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                CalendarTokens.radiusSegPill),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: CalendarTokens.textBody,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.55),
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ─── Overflow ⋯ Button ───
          _OverflowScaleButton(
            activeScale: activeScale,
            isActive: _isOverflowActive,
            overflowScales: _overflowScales,
            onScaleChanged: onScaleChanged,
          ),
        ],
      ),
    );
  }

  static String _primaryLabelFa(JourneyScale scale) {
    switch (scale) {
      case JourneyScale.agenda:
        return 'برنامه';
      case JourneyScale.day:
        return 'روز';
      case JourneyScale.month:
        return 'ماه';
      default:
        return '';
    }
  }

  static String scaleLabelFa(JourneyScale scale) {
    switch (scale) {
      case JourneyScale.agenda:
        return 'برنامه';
      case JourneyScale.day:
        return 'روز';
      case JourneyScale.week:
        return 'هفته';
      case JourneyScale.month:
        return 'ماه';
      case JourneyScale.year:
        return 'سال';
    }
  }
}

/// The overflow ⋯ button that shows week / year options in a popup menu.
/// Highlights with the active scale's label when week or year is selected.
class _OverflowScaleButton extends StatelessWidget {
  const _OverflowScaleButton({
    required this.activeScale,
    required this.isActive,
    required this.overflowScales,
    required this.onScaleChanged,
  });

  final JourneyScale activeScale;
  final bool isActive;
  final List<JourneyScale> overflowScales;
  final ValueChanged<JourneyScale> onScaleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: isActive
          ? 'نمای فعال: ${JourneyScaleSwitcher.scaleLabelFa(activeScale)}'
          : 'نماهای بیشتر',
      child: PopupMenuButton<JourneyScale>(
        tooltip: '',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard)),
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.cardColor,
        elevation: 4,
        offset: const Offset(0, 4),
        itemBuilder: (ctx) => overflowScales
            .map(
              (scale) => PopupMenuItem<JourneyScale>(
                value: scale,
                child: Text(
                  JourneyScaleSwitcher.scaleLabelFa(scale),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: CalendarTokens.textBody,
                    fontWeight: scale == activeScale
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: scale == activeScale
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            )
            .toList(),
        onSelected: onScaleChanged,
        child: AnimatedContainer(
          duration: CalendarTokens.durationStandard,
          curve: CalendarTokens.curveEmphasis,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.dividerColor
                      .withValues(alpha: CalendarTokens.alphaCardBorder),
            ),
          ),
          child: isActive
              ? Text(
                  JourneyScaleSwitcher.scaleLabelFa(activeScale),
                  style: TextStyle(
                    fontSize: CalendarTokens.textBody,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Vazirmatn',
                  ),
                )
              : Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.55),
                ),
        ),
      ),
    );
  }
}
