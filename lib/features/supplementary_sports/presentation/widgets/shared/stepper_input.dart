import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class StepperInput extends StatelessWidget {

  const StepperInput({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glassmorphic colors
    final glassBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final glassBorder = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
    final activeIconColor = SupplementarySportsTheme.getTextPrimary(context);
    final disabledIconColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        // Plus Button (Increments value)
        _buildPillButton(
          icon: Icons.add,
          enabled: value < max,
          bgColor: glassBg,
          borderColor: glassBorder,
          iconColor: value < max ? activeIconColor : disabledIconColor,
          semanticsLabel: 'افزایش مقدار، مقدار فعلی $value',
          onTap: () {
            if (value < max) {
              onChanged(value + 1);
            }
          },
        ),
        const SizedBox(width: SupplementarySportsTheme.spacing24),
        // Value Text
        Container(
          constraints: const BoxConstraints(minWidth: 48),
          alignment: Alignment.center,
          child: Text(
            toPersianDigits('$value'),
            style: SupplementarySportsTheme.h1.copyWith(
              color: SupplementarySportsTheme.getTextPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: SupplementarySportsTheme.spacing24),
        // Minus Button (Decrements value)
        _buildPillButton(
          icon: Icons.remove,
          enabled: value > min,
          bgColor: glassBg,
          borderColor: glassBorder,
          iconColor: value > min ? activeIconColor : disabledIconColor,
          semanticsLabel: 'کاهش مقدار، مقدار فعلی $value',
          onTap: () {
            if (value > min) {
              onChanged(value - 1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required bool enabled,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
