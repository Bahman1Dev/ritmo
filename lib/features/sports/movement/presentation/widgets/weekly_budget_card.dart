// lib/features/sports/movement/presentation/widgets/weekly_budget_card.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/sports/movement/domain/movement_budget.dart';

class WeeklyBudgetCard extends StatelessWidget {
  const WeeklyBudgetCard({
    super.key,
    required this.snapshot,
    this.onTap,
  });

  final MovementBudgetSnapshot snapshot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = snapshot.progressRatio;
    final achievedInt = snapshot.achievedMetMinutes.round();
    final targetInt = snapshot.weeklyMetMinutesTarget.round();

    String footerText;
    if (snapshot.achievedMetMinutes >= snapshot.weeklyMetMinutesTarget) {
      footerText = 'هفتهٔ فوق‌العاده‌ای بود 🎉 همهٔ بودجه رو کامل کردی!';
    } else if (snapshot.achievedMetMinutes == 0) {
      footerText = 'هفتهٔ تازه شروع شده، اولین حرکت رو ثبت کن 🌱';
    } else if (snapshot.daysRemaining <= 2 && snapshot.progressRatio < 0.5) {
      footerText = 'هنوز وقت هست 💪 با یک حرکت سبک نزدیک‌تر میشی';
    } else {
      footerText = '${snapshot.daysRemaining.toPersianDigits()} روز مونده · با این روند به ${snapshot.projectedTotal.round().toPersianDigits()} MET-min می‌رسی';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        color: colors.surfaceVariant.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'بودجهٔ حرکت این هفته',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${achievedInt.toPersianDigits()} از ${targetInt.toPersianDigits()}',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: colors.outlineVariant.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? const Color(0xFF10B981) : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Breakdown list
                if (snapshot.byKind.isNotEmpty) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: snapshot.byKind.entries.take(3).map((e) {
                      final metVal = e.value.round().toPersianDigits();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${e.key}  $metVal MET-min',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Footer Text
                Text(
                  footerText,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
