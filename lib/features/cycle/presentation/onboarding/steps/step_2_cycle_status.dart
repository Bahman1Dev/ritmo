import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';

class Step2CycleStatus extends StatelessWidget {
  const Step2CycleStatus({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onNext,
    required this.onBack,
    required this.onNavigateToPregnancy,
    required this.colors,
    required this.isDark,
  });

  final CycleOnboardingData data;
  final ValueChanged<CycleOnboardingData> onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onNavigateToPregnancy;
  final RitmoColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = colors.primary;

    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الان کجای چرخه‌ای؟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'پاسخ صادقانه شما به محاسبه صحیح فاز بدنی و جلوگیری از ثبت داده‌های غلط کمک می‌کند.',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Option 1: Currently in period
          _buildStatusOptionCard(
            choice: CyclePeriodStatusChoice.currentlyInPeriod,
            icon: CupertinoIcons.drop_fill,
            title: 'همین حالا در دوره‌ام',
            subtitle: 'دوره فعال است؛ تاریخ شروع را مشخص کنید تا دوره باز ثبت شود.',
          ),
          const SizedBox(height: 10),

          // Option 2: Ended with known start date
          _buildStatusOptionCard(
            choice: CyclePeriodStatusChoice.endedWithKnownStart,
            icon: CupertinoIcons.checkmark_circle_fill,
            title: 'تمام شده؛ تاریخ شروعش را می‌دانم',
            subtitle: 'دوره قبلی به پایان رسیده است؛ تاریخ شروع آن را وارد کنید.',
          ),
          const SizedBox(height: 10),

          // Option 3: Don't know / Don't remember
          _buildStatusOptionCard(
            choice: CyclePeriodStatusChoice.dontKnow,
            icon: CupertinoIcons.question_circle_fill,
            title: 'نمی‌دانم / یادم نیست',
            subtitle: 'هیچ دوره ساختگی ثبت نمی‌شود. اپ تا ثبت اولین دوره، داده ناکافی اعلام می‌کند.',
          ),

          // Date selection section (shown if Option 1 or Option 2 selected)
          if (data.periodStatus == CyclePeriodStatusChoice.currentlyInPeriod ||
              data.periodStatus == CyclePeriodStatusChoice.endedWithKnownStart) ...[
            const SizedBox(height: 20),
            Text(
              'تاریخ شروع دوره:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickStartDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar, color: primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _formatJalaliDate(data.startDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'تغییر تاریخ',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Divider(height: 28, color: colors.border.withValues(alpha: 0.5)),

          // Pregnancy Shortcut Button (Bug چ-۱۱)
          InkWell(
            onTap: onNavigateToPregnancy,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffEC4899).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الان باردارم (انتقال مستقیم به حالت بارداری)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xffF472B6) : const Color(0xffDB2777),
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_left,
                    size: 16,
                    color: isDark ? const Color(0xffF472B6) : const Color(0xffDB2777),
                  ),
                ],
              ),
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

  Widget _buildStatusOptionCard({
    required CyclePeriodStatusChoice choice,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = data.periodStatus == choice;
    final primaryColor = colors.primary;

    return InkWell(
      onTap: () {
        onDataChanged(data.copyWith(periodStatus: choice));
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : colors.border.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(CupertinoIcons.checkmark_alt_circle_fill, color: primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final today = DateTime.now();
    // Allow up to 90 days ago for realistic irregularity/postpartum window (Bug چ-۶)
    final ninetyDaysAgo = today.subtract(const Duration(days: 90));

    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(data.startDate),
      firstDate: Jalali.fromDateTime(ninetyDaysAgo),
      lastDate: Jalali.fromDateTime(today),
    );

    if (picked != null) {
      onDataChanged(data.copyWith(startDate: picked.toDateTime()));
    }
  }

  String _formatJalaliDate(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final dayStr = RitmoNumber.fa(j.day.toString());
    final yearStr = RitmoNumber.fa(j.year.toString());
    return '$dayStr ${_monthNameFa(j.month)} $yearStr';
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
