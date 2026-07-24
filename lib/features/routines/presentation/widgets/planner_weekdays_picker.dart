import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class PlannerWeekdaysPicker extends StatelessWidget {
  const PlannerWeekdaysPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final List<int> selectedDays; // 6,7,1,2,3,4,5 (Saturday..Friday)
  final ValueChanged<List<int>> onChanged;

  static const List<Map<String, dynamic>> _days = [
    {'name': 'ش', 'value': 6},
    {'name': 'ی', 'value': 7},
    {'name': 'د', 'value': 1},
    {'name': 'س', 'value': 2},
    {'name': 'چ', 'value': 3},
    {'name': 'پ', 'value': 4},
    {'name': 'ج', 'value': 5},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((d) {
        final val = d['value'] as int;
        final isSelected = selectedDays.contains(val);

        return GestureDetector(
          onTap: () {
            final list = List<int>.from(selectedDays);
            if (isSelected) {
              if (list.length > 1) {
                list.remove(val);
              }
            } else {
              list.add(val);
            }
            onChanged(list);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                d['name'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
