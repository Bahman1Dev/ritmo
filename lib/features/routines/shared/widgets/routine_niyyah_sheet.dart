import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

enum NiyyahAction { startTimer, completeInstantly, snooze, edit, viewDetails }

class NiyyahIntent {
  const NiyyahIntent(this.action, {this.mode = 'FULL', this.duration = 0});
  final NiyyahAction action;
  final String mode;
  final int duration;
}

class RoutineNiyyahSheet extends StatefulWidget {
  const RoutineNiyyahSheet({
    super.key,
    required this.routine,
    this.initialMode = 'FULL',
  });

  final Routine routine;
  final String initialMode;

  static Future<void> show({
    required BuildContext context,
    required Routine routine,
    String initialMode = 'FULL',
    required Future<void> Function(String selectedMode) onStartTimer,
    required Future<void> Function(String selectedMode, int duration) onCompleteInstantly,
    required Future<void> Function() onSnooze,
    required Future<void> Function() onEdit,
    required Future<void> Function() onViewDetails,
  }) async {
    final intent = await showModalBottomSheet<NiyyahIntent>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RoutineNiyyahSheet(
        routine: routine,
        initialMode: initialMode,
      ),
    );

    if (intent == null) return; // User dismissed sheet
    if (!context.mounted) return;

    switch (intent.action) {
      case NiyyahAction.startTimer:
        await onStartTimer(intent.mode);
        break;
      case NiyyahAction.completeInstantly:
        await onCompleteInstantly(intent.mode, intent.duration);
        break;
      case NiyyahAction.snooze:
        await onSnooze();
        break;
      case NiyyahAction.edit:
        await onEdit();
        break;
      case NiyyahAction.viewDetails:
        await onViewDetails();
        break;
    }
  }

  @override
  State<RoutineNiyyahSheet> createState() => _RoutineNiyyahSheetState();
}

class _RoutineNiyyahSheetState extends State<RoutineNiyyahSheet> {
  late String selectedMode;

  @override
  void initState() {
    super.initState();
    final hasTiers = (widget.routine.lightDurationMinutes != null && widget.routine.lightDurationMinutes! > 0) ||
                     (widget.routine.minimalDurationMinutes != null && widget.routine.minimalDurationMinutes! > 0);
    if (!hasTiers) {
      selectedMode = 'FULL';
    } else {
      selectedMode = widget.initialMode;
    }
  }

  void _dispatchIntent(NiyyahIntent intent) {
    RitmoHaptics.confirm();
    Navigator.pop(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final targetMinutes = widget.routine.currentTargetMinutes > 0
        ? widget.routine.currentTargetMinutes
        : (widget.routine.targetDurationMinutes ?? 30);
    final lightMinutes = widget.routine.lightDurationMinutes ?? 20;
    final minimalMinutes = widget.routine.minimalDurationMinutes ?? 10;

    final hasLight = widget.routine.lightDurationMinutes != null && widget.routine.lightDurationMinutes! > 0;
    final hasMinimal = widget.routine.minimalDurationMinutes != null && widget.routine.minimalDurationMinutes! > 0;
    final hasTiers = hasLight || hasMinimal;

    final canStartTimer = widget.routine.targetDurationMinutes != null && widget.routine.targetDurationMinutes! > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CupertinoIcons.sparkles,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آماده‌ای؟',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.routine.title,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode Selection (if routine has tiers)
            if (hasTiers) ...[
              Text(
                'کیفیت و سطح انجام',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ModeSelectorTile(
                      label: 'کامل',
                      durationMinutes: targetMinutes,
                      isSelected: selectedMode == 'FULL',
                      color: colors.success,
                      onTap: () => setState(() => selectedMode = 'FULL'),
                    ),
                  ),
                  if (hasLight) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeSelectorTile(
                        label: 'سبک',
                        durationMinutes: lightMinutes,
                        isSelected: selectedMode == 'LIGHT',
                        color: colors.primary,
                        onTap: () => setState(() => selectedMode = 'LIGHT'),
                      ),
                    ),
                  ],
                  if (hasMinimal) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeSelectorTile(
                        label: 'حداقلی',
                        durationMinutes: minimalMinutes,
                        isSelected: selectedMode == 'MINIMAL',
                        color: colors.warning,
                        onTap: () => setState(() => selectedMode = 'MINIMAL'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Action 1: Start Focus Timer
            if (canStartTimer)
              ElevatedButton.icon(
                onPressed: () => _dispatchIntent(NiyyahIntent(NiyyahAction.startTimer, mode: selectedMode)),
                icon: const Icon(CupertinoIcons.play_circle_fill, size: 20),
                label: const Text(
                  'شروع تایمر تمرکز',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'برای این روتین مدت‌زمانی تعریف نشده است',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Action 2: Instant Completion
            OutlinedButton.icon(
              onPressed: () => _dispatchIntent(NiyyahIntent(NiyyahAction.completeInstantly, mode: selectedMode)),
              icon: Icon(CupertinoIcons.check_mark_circled, size: 20, color: colors.success),
              label: Text(
                'ثبت فوری بدون تایمر',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.success),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.success.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Actions Row: Snooze, Edit, Details
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _dispatchIntent(const NiyyahIntent(NiyyahAction.snooze)),
                    icon: Icon(CupertinoIcons.time, size: 18, color: colors.warning),
                    label: Text(
                      'تعویق روتین',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.warning),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _dispatchIntent(const NiyyahIntent(NiyyahAction.edit)),
                    icon: Icon(CupertinoIcons.pencil, size: 18, color: colors.primary),
                    label: Text(
                      'ویرایش',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _dispatchIntent(const NiyyahIntent(NiyyahAction.viewDetails)),
                    icon: Icon(CupertinoIcons.info_circle, size: 18, color: colors.textSecondary),
                    label: Text(
                      'جزئیات',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _ModeSelectorTile extends StatelessWidget {
  const _ModeSelectorTile({
    required this.label,
    required this.durationMinutes,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int durationMinutes;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colors.border.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? color : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${PersianDigits.convert(durationMinutes.toString())} دقیقه',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: isSelected ? color : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
