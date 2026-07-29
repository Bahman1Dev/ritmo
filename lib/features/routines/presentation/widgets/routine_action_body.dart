import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/widgets/action/action_capabilities.dart';
import 'package:ritmo/core/widgets/action/action_sheet_registry.dart';
import 'package:ritmo/core/widgets/action/action_sheet_result.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';

class RoutineActionBody extends ActionBody {
  final Routine routine;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const RoutineActionBody({
    super.key,
    required this.routine,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  ActionCapabilities get capabilities => ActionCapabilities(
        variants: const ['FULL', 'LIGHT', 'MINIMAL'],
        canTimer: true,
        canSnooze: true,
        canSkip: true,
        canEdit: true,
        canDetails: true,
        snoozeMeaning: SnoozeMeaning.normal,
      );

  @override
  List<SubmitAction> getSubmitActions(BuildContext context) => [];

  @override
  List<HandoffAction> getHandoffActions(BuildContext context) => [];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final fullMinutes = routine.currentTargetMinutes > 0
        ? routine.currentTargetMinutes
        : (routine.targetDurationMinutes ?? 30);
    final lightMinutes = routine.lightDurationMinutes ?? 20;
    final minimalMinutes = routine.minimalDurationMinutes ?? 10;

    final hasLight = routine.lightDurationMinutes != null && routine.lightDurationMinutes! > 0;
    final hasMinimal = routine.minimalDurationMinutes != null && routine.minimalDurationMinutes! > 0;
    final hasTiers = hasLight || hasMinimal;

    if (!hasTiers) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'مدت زمان هدف: ${PersianDigits.convert(fullMinutes.toString())} دقیقه',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _TierCard(
            title: 'کامل 🎯',
            minutes: fullMinutes,
            modeKey: 'FULL',
            selectedMode: selectedMode,
            activeColor: colors.primary,
            onTap: () => onModeChanged('FULL'),
          ),
        ),
        if (hasLight) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _TierCard(
              title: 'سبک ⚡',
              minutes: lightMinutes,
              modeKey: 'LIGHT',
              selectedMode: selectedMode,
              activeColor: colors.success,
              onTap: () => onModeChanged('LIGHT'),
            ),
          ),
        ],
        if (hasMinimal) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _TierCard(
              title: 'حداقلی 🌿',
              minutes: minimalMinutes,
              modeKey: 'MINIMAL',
              selectedMode: selectedMode,
              activeColor: colors.warning,
              onTap: () => onModeChanged('MINIMAL'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final String title;
  final int minutes;
  final String modeKey;
  final String selectedMode;
  final Color activeColor;
  final VoidCallback onTap;

  const _TierCard({
    required this.title,
    required this.minutes,
    required this.modeKey,
    required this.selectedMode,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        RitmoHaptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [activeColor, activeColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : colors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${PersianDigits.convert(minutes.toString())} دقیقه',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
