import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/action/action_capabilities.dart';
import 'package:ritmo/core/widgets/action/action_sheet_registry.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';

class PrayerActionBody extends ActionBody {
  final AgendaItem item;
  final String selectedQuality;
  final bool withJamat;
  final bool isPastTime;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<bool> onJamatChanged;

  const PrayerActionBody({
    super.key,
    required this.item,
    required this.selectedQuality,
    required this.withJamat,
    required this.isPastTime,
    required this.onQualityChanged,
    required this.onJamatChanged,
  });

  @override
  ActionCapabilities get capabilities => const ActionCapabilities(
        variants: ['ON_TIME', 'IN_TIME', 'LATE'],
        canTimer: false,
        canSnooze: false,
        canSkip: true,
        canEdit: false,
        canDetails: true,
        snoozeMeaning: SnoozeMeaning.qada,
      );

  @override
  List<SubmitAction> getSubmitActions(BuildContext context) {
    final mode = isPastTime ? 'QADA' : selectedQuality;
    final label = isPastTime ? 'ثبت به‌عنوان قضا 📿' : 'ثبت انجام نماز 🤲';

    return [
      SubmitAction(
        id: 'prayer_complete',
        label: label,
        icon: isPastTime ? CupertinoIcons.bookmark_fill : CupertinoIcons.check_mark_circled,
        onSubmit: () async {
          return await CompletionGateway.instance.submit(
            PrayerCompletion(
              prayerKey: item.sourceId,
              dateStr: item.dateStr,
              mode: mode,
            ),
          );
        },
      ),
    ];
  }

  @override
  List<HandoffAction> getHandoffActions(BuildContext context) => [];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prayer window virtue banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPastTime ? colors.warning.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPastTime ? colors.warning.withValues(alpha: 0.3) : colors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPastTime ? CupertinoIcons.clock : CupertinoIcons.sun_max_fill,
                color: isPastTime ? colors.warning : colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPastTime
                      ? 'وقت قانونی این نماز به پایان رسیده است.'
                      : 'فرصت فضیلت اول وقت باقی است.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (!isPastTime) ...[
          // Quality Chips
          Row(
            children: [
              Expanded(
                child: _QualityChip(
                  label: 'اول وقت 🎯',
                  qualityKey: 'ON_TIME',
                  selectedQuality: selectedQuality,
                  activeColor: colors.primary,
                  onTap: () => onQualityChanged('ON_TIME'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QualityChip(
                  label: 'در وقت ⚡',
                  qualityKey: 'IN_TIME',
                  selectedQuality: selectedQuality,
                  activeColor: colors.success,
                  onTap: () => onQualityChanged('IN_TIME'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QualityChip(
                  label: 'آخر وقت 🌿',
                  qualityKey: 'LATE',
                  selectedQuality: selectedQuality,
                  activeColor: colors.warning,
                  onTap: () => onQualityChanged('LATE'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Jamat toggle
          InkWell(
            onTap: () => onJamatChanged(!withJamat),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    withJamat ? CupertinoIcons.person_3_fill : CupertinoIcons.person_3,
                    color: withJamat ? colors.primary : colors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'اقامه به صورت باجماعت',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textPrimary,
                        fontWeight: withJamat ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: withJamat,
                    activeColor: colors.primary,
                    onChanged: onJamatChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String label;
  final String qualityKey;
  final String selectedQuality;
  final Color activeColor;
  final VoidCallback onTap;

  const _QualityChip({
    required this.label,
    required this.qualityKey,
    required this.selectedQuality,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = selectedQuality == qualityKey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : colors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
