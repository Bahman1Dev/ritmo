import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/presentation/ritmo_orb.dart';

class StepIdentity extends StatelessWidget {

  const StepIdentity({
    super.key,
    required this.name,
    required this.onNameChanged,
    required this.gender,
    required this.onGenderChanged,
    required this.age,
    required this.onAgeChanged,
  });
  final String name;
  final ValueChanged<String> onNameChanged;
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final int age;
  final ValueChanged<int> onAgeChanged;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: RitmoOrb(size: 70)),
        const SizedBox(height: 16),
        Text(
          'سلام، من ریتمو هستم.\nاسم شما چیه؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'نام شما...',
            hintStyle: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.5),
              fontFamily: 'Vazirmatn',
            ),
            filled: true,
            fillColor: colors.textPrimary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.border.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xff9B89FF),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: onNameChanged,
          controller: TextEditingController(text: name)..selection = TextSelection.fromPosition(TextPosition(offset: name.length)),
        ),
        const SizedBox(height: 24),
        Text(
          'جنسیت شما؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGenderChip(context, 'MALE', 'مرد'),
            const SizedBox(width: 8),
            _buildGenderChip(context, 'FEMALE', 'زن'),
            const SizedBox(width: 8),
            _buildGenderChip(context, 'PREFER_NOT_TO_SAY', 'ترجیح می‌دم نگم'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'چند سالتونه؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                pickerTextStyle: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                  fontSize: 20,
                ),
              ),
            ),
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: age - 10),
              itemExtent: 38,
              onSelectedItemChanged: (index) {
                onAgeChanged(index + 10);
              },
              children: List.generate(80, (index) {
                final displayAge = index + 10;
                return Center(
                  child: Text(
                    _toPersianDigits('$displayAge ساله'),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(BuildContext context, String value, String label) {
    final colors = context.colors;
    final isSelected = gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onGenderChanged(value);
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
