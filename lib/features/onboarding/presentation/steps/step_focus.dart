import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class StepFocus extends StatelessWidget {

  const StepFocus({
    super.key,
    required this.focusAreas,
    required this.onFocusAreaToggled,
    required this.enabledModules,
    required this.onModuleToggled,
    required this.energyProfile,
    required this.onEnergyProfileChanged,
  });
  final Map<String, bool> focusAreas;
  final ValueChanged<String> onFocusAreaToggled;
  final Map<String, bool> enabledModules;
  final ValueChanged<String> onModuleToggled;
  final String energyProfile;
  final ValueChanged<String> onEnergyProfileChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedFocusCount = focusAreas.values.where((v) => v).length;

    // List of focus areas in Persian
    final focusList = focusAreas.keys.toList();

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
          'حداکثر ۳ حوزه از دغدغه‌های فعلی خود را انتخاب کنید ($selectedFocusCount/۳)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 16),
        // Grid of Focus chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: focusList.map((area) {
            final isSelected = focusAreas[area] ?? false;
            return ChoiceChip(
              label: Text(area),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && selectedFocusCount >= 3) {
                  HapticFeedback.vibrate(); // Warning vibration
                  return;
                }
                HapticFeedback.selectionClick();
                onFocusAreaToggled(area);
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
        const SizedBox(height: 24),
        // Active Systems Dynamic Panel
        Text(
          'سیستم‌های فعال شما',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSystemToggleChip(context, 'module_medicine_enabled', '💊 دارو و سلامت', enabledModules['module_medicine_enabled'] ?? false),
                  _buildSystemToggleChip(context, 'module_courses_enabled', '📚 دوره‌های آموزشی', enabledModules['module_courses_enabled'] ?? false),
                  _buildSystemToggleChip(context, 'module_konkur_enabled', '🎓 کنکور', enabledModules['module_konkur_enabled'] ?? false),
                  _buildSystemToggleChip(context, 'module_goals_enabled', '🎯 اهداف و برنامه‌ها', enabledModules['module_goals_enabled'] ?? false),
                  _buildSystemToggleChip(context, 'module_sports_enabled', '🏃 ورزش', enabledModules['module_sports_enabled'] ?? false),
                  _buildSystemToggleChip(context, 'module_religion_enabled', '🕌 عبادت', enabledModules['module_religion_enabled'] ?? false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Energy Profile Selection
        Text(
          'سطح انرژی عمومی شما در طول روز چطور است؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEnergyChip(context, 'LOW', 'کم 💤'),
            const SizedBox(width: 8),
            _buildEnergyChip(context, 'MEDIUM', 'متوسط ⚡'),
            const SizedBox(width: 8),
            _buildEnergyChip(context, 'HIGH', 'زیاد 🔥'),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemToggleChip(BuildContext context, String key, String label, bool isSelected) {
    final colors = context.colors;
    return FilterChip(
      label: Text(isSelected ? '$label ✓' : label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onModuleToggled(key);
      },
      labelStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        color: isSelected ? Colors.white : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      selectedColor: const Color(0xff34C759).withValues(alpha: 0.25),
      backgroundColor: colors.textPrimary.withValues(alpha: 0.02),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xff34C759) : colors.border.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildEnergyChip(BuildContext context, String value, String label) {
    final colors = context.colors;
    final isSelected = energyProfile == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          onEnergyProfileChanged(value);
        }
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
  }
}
