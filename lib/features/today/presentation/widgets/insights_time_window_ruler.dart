import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

enum InsightsTimeWindow {
  last7Days,
  last30Days,
  lastSeason,
  allTime,
}

extension InsightsTimeWindowX on InsightsTimeWindow {
  String get label {
    switch (this) {
      case InsightsTimeWindow.last7Days:
        return toPersianDigits('۷ روز اخیر');
      case InsightsTimeWindow.last30Days:
        return toPersianDigits('۳۰ روز اخیر');
      case InsightsTimeWindow.lastSeason:
        return 'فصل جاری';
      case InsightsTimeWindow.allTime:
        return 'کل دوره';
    }
  }

  int get days {
    switch (this) {
      case InsightsTimeWindow.last7Days:
        return 7;
      case InsightsTimeWindow.last30Days:
        return 30;
      case InsightsTimeWindow.lastSeason:
        return 90;
      case InsightsTimeWindow.allTime:
        return 3650;
    }
  }
}

class InsightsTimeWindowRuler extends StatelessWidget {
  const InsightsTimeWindowRuler({
    required this.selectedWindow,
    required this.onWindowChanged,
    super.key,
  });

  final InsightsTimeWindow selectedWindow;
  final ValueChanged<InsightsTimeWindow> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: InsightsTimeWindow.values.map((window) {
          final isSelected = window == selectedWindow;
          return Expanded(
            child: GestureDetector(
              onTap: () => onWindowChanged(window),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    window.label,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
