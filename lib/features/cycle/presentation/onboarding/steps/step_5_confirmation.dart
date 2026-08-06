import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';

class Step5Confirmation extends StatelessWidget {
  const Step5Confirmation({
    super.key,
    required this.data,
    required this.onSave,
    required this.onBack,
    required this.isSaving,
    required this.colors,
    required this.isDark,
  });

  final CycleOnboardingData data;
  final VoidCallback onSave;
  final VoidCallback onBack;
  final bool isSaving;
  final RitmoColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = colors.primary;

    return SingleChildScrollView(
      key: const ValueKey(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تأیید و ذخیره نهایی',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لطفاً خلاصه اطلاعات تنظیم‌شده را بررسی کنید. با فشردن دکمه ثبت، راهاندازی کامل می‌شود.',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  label: 'وضعیت اولیه دوره:',
                  value: _formatStatusText(),
                ),
                if (data.periodStatus == CyclePeriodStatusChoice.currentlyInPeriod ||
                    data.periodStatus == CyclePeriodStatusChoice.endedWithKnownStart) ...[
                  const Divider(height: 20),
                  _buildSummaryRow(
                    label: 'تاریخ شروع:',
                    value: _formatJalaliDate(data.startDate),
                  ),
                ],
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'طول چرخه:',
                  value: '${_toPersianDigits(data.cycleLength.toString())} روز',
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'طول خونریزی:',
                  value: '${_toPersianDigits(data.periodDuration.toString())} روز',
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'اتصال‌های فعال:',
                  value: _formatConsentsText(),
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'قفل امنیتی:',
                  value: data.enableLock ? 'فعال' : 'غیرفعال',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action buttons
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
                  onPressed: isSaving ? null : onBack,
                  child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'ثبت و شروع',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ],
    );
  }

  String _formatStatusText() {
    switch (data.periodStatus) {
      case CyclePeriodStatusChoice.currentlyInPeriod:
        return 'همین حالا در دوره‌ام (دوره باز)';
      case CyclePeriodStatusChoice.endedWithKnownStart:
        return 'تمام شده (دوره بسته)';
      case CyclePeriodStatusChoice.dontKnow:
        return 'نمی‌دانم (داده اولیه ثبت نمی‌شود)';
      case CyclePeriodStatusChoice.currentlyPregnant:
        return 'الان باردارم (انتقال به حالت بارداری)';
    }
  }

  String _formatConsentsText() {
    final active = <String>[];
    if (data.worshipConsent) active.add('عبادات');
    if (data.energyConsent) active.add('انرژی');
    if (data.remindersConsent) active.add('یادآوری‌ها');
    if (data.dashboardConsent) active.add('داشبورد امروز');
    if (active.isEmpty) return 'هیچ‌کدام';
    return active.join('، ');
  }

  String _formatJalaliDate(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final dayStr = _toPersianDigits(j.day.toString());
    final yearStr = _toPersianDigits(j.year.toString());
    return '$dayStr ${_monthNameFa(j.month)} $yearStr';
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
