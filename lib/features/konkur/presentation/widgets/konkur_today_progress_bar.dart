import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurTodayProgressBar extends StatelessWidget {
  const KonkurTodayProgressBar({
    super.key,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.completedItems,
    required this.totalItems,
    required this.colors,
  });

  final int plannedMinutes;
  final int actualMinutes;
  final int completedItems;
  final int totalItems;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    final ratio = min(actualMinutes / max(plannedMinutes, 1), 1.0);
    final fillColor = ratio >= 1.0
        ? colors.success
        : (ratio >= 0.5 ? const Color(0xFF8B5CF6) : colors.warning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDuration(actualMinutes),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مطالعه واقعی امروز',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDuration(plannedMinutes),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'هدف امروز',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.border.withValues(alpha: 0.5),
              color: fillColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${toPersianDigits(completedItems)} از ${toPersianDigits(totalItems)} مبحث تکمیل شده',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
