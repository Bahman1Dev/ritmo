import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class ContinuityBar extends StatelessWidget {

  const ContinuityBar({
    super.key,
    required this.daysCompleted,
  });
  final List<bool> daysCompleted;

  @override
  Widget build(BuildContext context) {
    final successColor = SupplementarySportsTheme.getSuccessColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyBorderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    // Ensure we have exactly 7 elements
    final normalizedDays = List<bool>.from(daysCompleted);
    while (normalizedDays.length < 7) {
      normalizedDays.add(false);
    }
    if (normalizedDays.length > 7) {
      normalizedDays.removeRange(7, normalizedDays.length);
    }

    return Semantics(
      label: 'میزان تداوم تمرین در هفته اخیر',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: List.generate(7, (index) {
          final isCompleted = normalizedDays[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: SupplementarySportsTheme.spacing4),
            child: Semantics(
              label: 'روز ${index + 1}: ${isCompleted ? "تمرین شده" : "استراحت"}',
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isCompleted ? successColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? successColor : emptyBorderColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
