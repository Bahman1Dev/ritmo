import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';

class Step1PrivacyLock extends StatelessWidget {
  const Step1PrivacyLock({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onNext,
    required this.colors,
    required this.isDark,
  });

  final CycleOnboardingData data;
  final ValueChanged<CycleOnboardingData> onDataChanged;
  final VoidCallback onNext;
  final RitmoColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = colors.primary;

    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.lock_shield_fill, color: primaryColor, size: 34),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'این اتاق مال توست',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Privacy commitments
          _buildPrivacyCommitmentCard(
            icon: CupertinoIcons.device_phone_portrait,
            title: 'داده‌ها روی همین گوشی می‌ماند',
            description: 'تمام داده‌های شما به‌صورت کاملاً آفلاین روی دیتابیس محلی ذخیره شده و به هیچ سروری ارسال نمی‌شوند.',
          ),
          const SizedBox(height: 10),
          _buildPrivacyCommitmentCard(
            icon: CupertinoIcons.eye_slash_fill,
            title: 'بدون واژه صریح بیرون از این صفحه',
            description: 'در اعلانات، داشبورد اصلی و سایر صفحات اپلیکیشن هیچ کلمه صریح یا افشاکننده‌ای استفاده نمی‌شود.',
          ),
          const SizedBox(height: 10),
          _buildPrivacyCommitmentCard(
            icon: CupertinoIcons.switch_camera,
            title: 'کنترل کامل اتصالات در دست شماست',
            description: 'هیچ اتصالی با سایر بخش‌ها بدون اجازه و انتخاب صریح شما در گام‌های بعدی فعال نخواهد شد.',
          ),

          Divider(height: 32, color: colors.border.withValues(alpha: 0.5)),

          // Lock recommendation option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.enableLock ? primaryColor.withValues(alpha: 0.6) : colors.border.withValues(alpha: 0.5),
                width: data.enableLock ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.lock_fill, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فعال‌سازی قفل امنیتی ورود',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'حفاظت از بخش چرخه بدن با رمز پین یا بیومتریک گوشی',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  activeTrackColor: primaryColor,
                  value: data.enableLock,
                  onChanged: (val) {
                    onDataChanged(data.copyWith(enableLock: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
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
                'متوجه شدم، مرحله بعد',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCommitmentCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
