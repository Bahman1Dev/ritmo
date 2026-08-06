import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

class LifePulseSparklineChart extends StatefulWidget {
  const LifePulseSparklineChart({
    required this.pulseHistory,
    super.key,
  });

  final List<Map<String, dynamic>> pulseHistory;

  @override
  State<LifePulseSparklineChart> createState() => _LifePulseSparklineChartState();
}

class _LifePulseSparklineChartState extends State<LifePulseSparklineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = widget.pulseHistory.take(30).toList().reversed.toList();

    if (history.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          'هنوز داده‌های کافی برای رسم نمودار ثبت نشده است.',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final selectedItem = (_selectedIndex != null && _selectedIndex! < history.length)
        ? history[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'نمودار تعاملی ۳۰ روز اخیر:',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            if (selectedItem != null)
              Text(
                '${selectedItem['date']}: ${toPersianDigits('${selectedItem['rhythmScore']}٪')}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: Stack(
            children: [
              // Normal Band (60% to 80% range)
              Positioned(
                top: 48 * (1 - 0.8),
                bottom: 48 * 0.6,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(history.length, (index) {
                  final item = history[index];
                  final score = (item['rhythmScore'] as num? ?? 0).toDouble();
                  final heightFactor = (score / 100).clamp(0.05, 1.0);
                  final isSelected = _selectedIndex == index;

                  Color barColor = colors.success;
                  if (score < 50) {
                    barColor = colors.medicalRed;
                  } else if (score < 75) {
                    barColor = colors.primary;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Tooltip(
                      message: '${item['date']}: ${score.round()}٪',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 6.0 : 4.0,
                        height: 48 * heightFactor,
                        decoration: BoxDecoration(
                          color: isSelected ? barColor : barColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: barColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
