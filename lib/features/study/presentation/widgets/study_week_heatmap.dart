import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class StudyWeekHeatmap extends StatelessWidget {
  const StudyWeekHeatmap({super.key, required this.sessionsByDate});

  final Map<String, int> sessionsByDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    final days = List.generate(56, (i) {
      return now.subtract(Duration(days: 55 - i));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فعالیت ۸ هفته اخیر',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: 56,
            itemBuilder: (context, index) {
              final dt = days[index];
              final dateIso = dt.toIso8601String().substring(0, 10);
              final minutes = sessionsByDate[dateIso] ?? 0;

              Color cellColor = colors.surfaceElevated;
              if (minutes > 0 && minutes < 30) cellColor = colors.primary.withValues(alpha: 0.3);
              if (minutes >= 30 && minutes < 60) cellColor = colors.primary.withValues(alpha: 0.6);
              if (minutes >= 60) cellColor = colors.primary;

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
