import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';

class CycleBurdenCard extends StatelessWidget {
  const CycleBurdenCard({
    super.key,
    required this.burden,
    required this.advice,
  });

  final BodyBurdenScore burden;
  final CycleAdaptiveAdvice advice;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeColor = burden.level == 'HIGH'
        ? const Color(0xFFEC4899)
        : (burden.level == 'MODERATE' ? Colors.amber.shade700 : Colors.teal);

    final badgeTitleFa = burden.level == 'HIGH'
        ? 'بار بدنی بالا'
        : (burden.level == 'MODERATE' ? 'بار بدنی متوسط' : 'بار بدنی متوازن');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 20, color: badgeColor),
                  const SizedBox(width: 8),
                  Text(
                    'شاخص ریتم بدنی و تنظیم بار روزانه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeTitleFa,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...advice.recommendationsFa.map((rec) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
