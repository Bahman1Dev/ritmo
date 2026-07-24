import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';

class CyclePredictionConfidenceCard extends StatelessWidget {
  const CyclePredictionConfidenceCard({
    super.key,
    required this.confidence,
    required this.dataQuality,
  });

  final PredictionConfidence confidence;
  final DataQualityReport dataQuality;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeColor = switch (confidence.level) {
      PredictionConfidenceLevel.high => Colors.teal,
      PredictionConfidenceLevel.medium => Colors.amber.shade700,
      PredictionConfidenceLevel.low => Colors.orange.shade800,
    };

    final badgeLabelFa = switch (confidence.level) {
      PredictionConfidenceLevel.high => 'اطمینان بالا',
      PredictionConfidenceLevel.medium => 'اطمینان متوسط',
      PredictionConfidenceLevel.low => 'نیازمند داده بیشتر',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 18, color: badgeColor),
                  const SizedBox(width: 8),
                  Text(
                    'اعتبار پیش‌بینی ریتم بدنی',
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
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabelFa,
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
          if (confidence.reasonsFa.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...confidence.reasonsFa.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
