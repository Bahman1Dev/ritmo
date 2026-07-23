// lib/features/routines/presentation/widgets/planner_day_of_week_selector.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class PlannerDayOfWeekSelector extends StatelessWidget {

  const PlannerDayOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const days = [
      {'key': 6, 'label': 'ش'},
      {'key': 7, 'label': 'ی'},
      {'key': 1, 'label': 'د'},
      {'key': 2, 'label': 'س'},
      {'key': 3, 'label': 'چ'},
      {'key': 4, 'label': 'پ'},
      {'key': 5, 'label': 'ج'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final key = d['key']! as int;
        final label = d['label']! as String;
        final isSelected = selectedDays.contains(key);

        return GestureDetector(
          onTap: () {
            final list = List<int>.from(selectedDays);
            if (list.contains(key)) {
              if (list.length > 1) list.remove(key);
            } else {
              list.add(key);
            }
            onChanged(list);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF1E2235).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.03)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
