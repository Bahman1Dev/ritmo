import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';

class Step4Consents extends StatelessWidget {
  const Step4Consents({
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

    return SingleChildScrollView(
      key: const ValueKey(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اتصال‌ها و حریم خصوصی',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هیچ‌کدام لازم نیستند و همیشه می‌توانید بعداً در تنظیمات آن‌ها را تغییر دهید.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Worship Consent
          _buildConsentTile(
            title: 'هماهنگی با بخش عبادات',
            subtitle: 'محاسبه خودکار روزهای قضا و پیشنهاد تعلیق فرایض در زمان عادت.',
            whatGoesOut: 'خروجی: فقط در دیتابیس محلی دستگاه، بدون هیچ ارسال اینترنتی.',
            value: data.worshipConsent,
            onChanged: (val) => onDataChanged(data.copyWith(worshipConsent: val)),
          ),
          const SizedBox(height: 10),

          // 2. Energy Consent
          _buildConsentTile(
            title: 'تأثیر بر شاخص انرژی',
            subtitle: 'محاسبه اثر تغییرات فاز بر عدد پیش‌بینی انرژی روزانه.',
            whatGoesOut: 'خروجی: فقط یک اثر عددی ملایم روی شاخص انرژی، بدون هیچ واژه صریحی.',
            value: data.energyConsent,
            onChanged: (val) => onDataChanged(data.copyWith(energyConsent: val)),
          ),
          const SizedBox(height: 10),

          // 3. Reminders Consent
          _buildConsentTile(
            title: 'یادآوری‌های محرمانه',
            subtitle: 'دریافت اعلان‌های ساده و بدون متن صریح برای ثبت دوره.',
            whatGoesOut: 'خروجی: اعلان محلی روی همین گوشی، بدون درج کلمات افشاکننده.',
            value: data.remindersConsent,
            onChanged: (val) => onDataChanged(data.copyWith(remindersConsent: val)),
          ),
          const SizedBox(height: 10),

          // 4. Dashboard Consent
          _buildConsentTile(
            title: 'نمایش کارت خلاصه در امروز',
            subtitle: 'نمایش وضعیت فاز جاری در تب امروز.',
            whatGoesOut: 'خروجی: فقط یک کارت محرمانه در تب امروز همین دستگاه.',
            value: data.dashboardConsent,
            onChanged: (val) => onDataChanged(data.copyWith(dashboardConsent: val)),
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

  Widget _buildConsentTile({
    required String title,
    required String subtitle,
    required String whatGoesOut,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primaryColor = colors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value
            ? primaryColor.withValues(alpha: isDark ? 0.14 : 0.06)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? primaryColor.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.4),
          width: value ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
              CupertinoSwitch(
                activeTrackColor: primaryColor,
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          // Explicit "What goes out" line (Bug چ-۹)
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_right_arrow_left_circle,
                size: 13,
                color: value ? primaryColor : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  whatGoesOut,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: value ? primaryColor : colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
