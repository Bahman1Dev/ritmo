import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class OnboardingProgressBar extends StatelessWidget {

  const OnboardingProgressBar({
    super.key,
    required this.step,
    required this.total,
  });
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = (step / total).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressColor = SupplementarySportsTheme.getSuccessColor(context);
    final trackColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;

    final stepText = toPersianDigits('$step/$total');

    return Semantics(
      label: 'پیشرفت ثبت‌نام، مرحله $stepText',
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SupplementarySportsTheme.spacing12,
          horizontal: SupplementarySportsTheme.spacing16,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Progress Bar Track
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Track
                    Container(
                      height: 8,
                      color: trackColor,
                    ),
                    // Progress
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          height: 8,
                          width: constraints.maxWidth * ratio,
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: SupplementarySportsTheme.spacing16),
            // Text representation
            Text(
              '($stepText)',
              textDirection: TextDirection.rtl,
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
