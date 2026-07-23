import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class SecondaryButton extends StatelessWidget {

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48.0,
    this.width = double.infinity,
  });
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final outlineColor = SupplementarySportsTheme.getTextSecondary(context);
    final textColor = SupplementarySportsTheme.getSuccessColor(context);
    final disabledColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        width: width,
        height: height.clamp(48.0, 56.0),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            side: BorderSide(
              color: onPressed != null ? outlineColor.withValues(alpha: 0.5) : disabledColor,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: SupplementarySportsTheme.borderRadiusButton,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SupplementarySportsTheme.spacing16,
            ),
          ),
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: SupplementarySportsTheme.buttonLabel.copyWith(
              color: onPressed != null ? textColor : outlineColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
