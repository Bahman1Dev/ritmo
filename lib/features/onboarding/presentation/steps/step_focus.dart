import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/models/focus_area.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_city_picker.dart';

class StepFocus extends StatelessWidget {
  const StepFocus({
    super.key,
    required this.chosenAreas,
    required this.onAreaToggled,
    required this.energyProfile,
    required this.onEnergyChanged,
    required this.isFemale,
    required this.enableCycle,
    required this.onCycleToggled,
  });

  final Set<FocusArea> chosenAreas;
  final ValueChanged<FocusArea> onAreaToggled;
  final String energyProfile;
  final ValueChanged<String> onEnergyChanged;
  final bool isFemale;
  final bool enableCycle;
  final ValueChanged<bool> onCycleToggled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canCourses = PremiumService.instance.can(PremiumFeature.coursesModule);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'حوزه‌های تمرکز شما',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'حداکثر ۳ حوزه از دغدغه‌های فعلی خود را انتخاب کنید (${chosenAreas.length}/۳)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: FocusArea.values.map((area) {
            final isSelected = chosenAreas.contains(area);
            final isStudyOrSkill = area == FocusArea.study || area == FocusArea.skill;
            final isLocked = isStudyOrSkill && !canCourses;

            return ChoiceChip(
              avatar: isLocked ? const Icon(CupertinoIcons.lock_fill, size: 14, color: Colors.amber) : null,
              label: Text(area.faLabel),
              selected: isSelected,
              onSelected: (selected) {
                if (isLocked) {
                  PremiumUpgradeSheet.show(context);
                  return;
                }
                if (selected && chosenAreas.length >= 3) {
                  HapticFeedback.vibrate();
                  return;
                }
                HapticFeedback.selectionClick();
                onAreaToggled(area);
              },
              labelStyle: TextStyle(
                fontFamily: 'Vazirmatn',
                color: isSelected ? Colors.white : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              selectedColor: const Color(0xff9B89FF).withValues(alpha: 0.4),
              backgroundColor: colors.textPrimary.withValues(alpha: 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xff9B89FF) : colors.border.withValues(alpha: 0.15),
                ),
              ),
            );
          }).toList(),
        ),

        if (chosenAreas.contains(FocusArea.worship)) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PrayerCityPicker(onChanged: () {}),
              );
            },
            icon: const Icon(CupertinoIcons.location_solid, size: 16),
            label: const Text(
              'انتخاب شهر برای اوقات شرعی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],

        if (isFemale) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'ردیابی چرخه سلامتی بانوان (کاملاً محرمانه و آفلاین)',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                  ),
                ),
                Switch(
                  value: enableCycle,
                  onChanged: onCycleToggled,
                  activeColor: const Color(0xff9B89FF),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        Text(
          'سطح انرژی عمومی اولیه',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EnergyChoiceChip(
                label: 'کم (استراحت)',
                profile: 'LOW',
                isSelected: energyProfile == 'LOW',
                onSelect: () => onEnergyChanged('LOW'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EnergyChoiceChip(
                label: 'متوسط (معمولی)',
                profile: 'MEDIUM',
                isSelected: energyProfile == 'MEDIUM',
                onSelect: () => onEnergyChanged('MEDIUM'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EnergyChoiceChip(
                label: 'بالا (پرانرژی)',
                profile: 'HIGH',
                isSelected: energyProfile == 'HIGH',
                onSelect: () => onEnergyChanged('HIGH'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnergyChoiceChip extends StatelessWidget {
  const _EnergyChoiceChip({
    required this.label,
    required this.profile,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final String profile;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff9B89FF).withValues(alpha: 0.25)
              : colors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff9B89FF) : colors.border.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.textPrimary : colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}
