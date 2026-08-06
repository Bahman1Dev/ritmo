import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/widgets/cycle_live_preview_bar.dart';

class Step3RhythmParams extends StatelessWidget {
  const Step3RhythmParams({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onNext,
    required this.onBack,
    required this.colors,
    required this.isDark,
  });

  final CycleOnboardingData data;
  final ValueChanged<CycleOnboardingData> onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final RitmoColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = colors.primary;

    // Dynamic Live Capping (Bug چ-۷): Bleeding duration cannot exceed cycleLength - 2 or max 10.
    final maxBleeding = math.min(10, math.max(3, data.cycleLength - 2));
    final safePeriodDuration = data.periodDuration.clamp(3, maxBleeding);

    final forecastDate = _calculateNextForecastDate();

    return SingleChildScrollView(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ریتم من',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              // Preset button
              InkWell(
                onTap: () {
                  onDataChanged(data.copyWith(cycleLength: 28, periodDuration: 6));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'مطمئن نیستم (تنظیم میانگین ۲۸/۶)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'میانگین طول چرخه و مدت خونریزی خود را مشخص کنید.',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 16),

          // 1. Cycle Length Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طول چرخه (فاصله شروع دو دوره):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              Text(
                '${_toPersianDigits(data.cycleLength.toString())} روز',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          Semantics(
            label: 'طول چرخه',
            value: '${data.cycleLength} روز',
            child: Slider(
              value: data.cycleLength.toDouble(),
              min: 21,
              max: 45,
              divisions: 24,
              activeColor: primaryColor,
              inactiveColor: colors.border.withValues(alpha: 0.5),
              onChanged: (v) {
                final newLen = v.round();
                final newMaxBleeding = math.min(10, math.max(3, newLen - 2));
                final cappedPeriod = safePeriodDuration.clamp(3, newMaxBleeding);
                onDataChanged(data.copyWith(
                  cycleLength: newLen,
                  periodDuration: cappedPeriod,
                ));
              },
            ),
          ),

          const SizedBox(height: 12),

          // 2. Bleeding Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طول مدت خونریزی:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              Text(
                '${_toPersianDigits(safePeriodDuration.toString())} روز',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          Semantics(
            label: 'طول مدت خونریزی',
            value: '$safePeriodDuration روز',
            child: Slider(
              value: safePeriodDuration.toDouble(),
              min: 3,
              max: maxBleeding.toDouble(),
              divisions: math.max(1, maxBleeding - 3),
              activeColor: primaryColor,
              inactiveColor: colors.border.withValues(alpha: 0.5),
              onChanged: (v) {
                onDataChanged(data.copyWith(periodDuration: v.round()));
              },
            ),
          ),

          const SizedBox(height: 16),

          // Live Cycle Preview Bar (§۵)
          CycleLivePreviewBar(
            cycleLength: data.cycleLength,
            periodDuration: safePeriodDuration,
            colors: colors,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Live forecast text line (§۵)
          if (forecastDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'با این اعداد، دوره بعدی حدوداً حوالی $forecastDate است.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onBack,
                  child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: onNext,
                  child: const Text(
                    'مرحله بعد',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _calculateNextForecastDate() {
    if (data.periodStatus == CyclePeriodStatusChoice.dontKnow ||
        data.periodStatus == CyclePeriodStatusChoice.currentlyPregnant) {
      return null;
    }
    final nextDt = data.startDate.add(Duration(days: data.cycleLength));
    final j = Jalali.fromDateTime(nextDt);
    final dayStr = _toPersianDigits(j.day.toString());
    final monthStr = _monthNameFa(j.month);
    return '$dayStr $monthStr';
  }

  String _toPersianDigits(String input) {
    return RitmoNumber.fa(input);
  }

  String _monthNameFa(int m) {
    const months = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }
}
