import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/logic/starter_pack_catalog.dart';

class StepFirstRoutine extends StatelessWidget {
  const StepFirstRoutine({
    super.key,
    required this.suggestedTemplates,
    required this.onTemplateToggled,
  });

  final List<StarterRoutineTemplate> suggestedTemplates;
  final ValueChanged<StarterRoutineTemplate> onTemplateToggled;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final catalogTemplates = StarterPackCatalog.allTemplates;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'بسته عادات و روتین‌های پیشنهادی',
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
          'بر اساس حوزه‌های انتخابی شما، این روتین‌ها پیشنهاد می‌شوند. موارد دلخواه را انتخاب کنید.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: catalogTemplates.map((template) {
            final isSelected = suggestedTemplates.any((t) => t.id == template.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xff9B89FF).withValues(alpha: 0.15)
                    : colors.textPrimary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xff9B89FF) : colors.border.withValues(alpha: 0.12),
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  onTemplateToggled(template);
                },
                activeColor: const Color(0xff9B89FF),
                title: Text(
                  template.titleFa,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _toPersianDigits('زمان: ${template.defaultTime} · مدت: ${template.durationMinutes} دقیقه'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
