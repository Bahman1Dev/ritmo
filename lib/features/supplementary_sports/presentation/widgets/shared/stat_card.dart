import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class StatCard extends StatelessWidget {

  const StatCard({
    super.key,
    required this.value,
    required this.label,
  });
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = SupplementarySportsTheme.getSurfaceColor(context);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(SupplementarySportsTheme.spacing16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: SupplementarySportsTheme.borderRadiusCard,
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Value (Large Persian text/number)
            Text(
              toPersianDigits(value),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: SupplementarySportsTheme.h1.copyWith(
                fontSize: 28,
                color: SupplementarySportsTheme.getTextPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: SupplementarySportsTheme.spacing8),
            // Label (Descriptive text)
            Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: SupplementarySportsTheme.caption.copyWith(
                color: SupplementarySportsTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
