import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/util/ritmo_number.dart';

class CycleLivePreviewBar extends StatelessWidget {
  const CycleLivePreviewBar({
    super.key,
    required this.cycleLength,
    required this.periodDuration,
    required this.colors,
    required this.isDark,
  });

  final int cycleLength;
  final int periodDuration;
  final RitmoColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bleedingRatio = (periodDuration / cycleLength).clamp(0.05, 0.5);
    final normalRatio = 1.0 - bleedingRatio;
    final primaryColor = colors.primary;

    return Semantics(
      label: 'پیش‌نمایش زنده چرخه: $periodDuration روز خونریزی از $cycleLength روز چرخه',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'پیش‌نمایش ریتم چرخه',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  '${_toPersianDigits(periodDuration.toString())} روز خونریزی / ${_toPersianDigits(cycleLength.toString())} روز کل',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Segmented Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    // Bleeding Segment
                    Expanded(
                      flex: (bleedingRatio * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Normal Segment
                    Expanded(
                      flex: (normalRatio * 100).round(),
                      child: Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'روزهای خونریزی',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'سایر فازها',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _toPersianDigits(String input) {
    return RitmoNumber.fa(input);
  }
}
