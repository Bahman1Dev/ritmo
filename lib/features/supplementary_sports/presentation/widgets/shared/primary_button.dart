import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class PrimaryButton extends StatelessWidget {

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48.0,
    this.width = double.infinity,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = SupplementarySportsTheme.getSuccessColor(context);
    final disabledBg = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.black : Colors.white;
    final disabledTextColor = isDark ? Colors.grey[600]! : Colors.grey[500]!;

    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        width: width,
        height: height.clamp(48.0, 56.0),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeBg,
            disabledBackgroundColor: disabledBg,
            foregroundColor: textColor,
            disabledForegroundColor: disabledTextColor,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: SupplementarySportsTheme.borderRadiusButton,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SupplementarySportsTheme.spacing16,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.black54 : Colors.white70,
                    ),
                  ),
                )
              : Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: SupplementarySportsTheme.buttonLabel.copyWith(
                    color: onPressed == null ? disabledTextColor : textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
