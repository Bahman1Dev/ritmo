import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

enum HeroPriorityType {
  activeTimer,
  overdueOrNextItem,
  medicalSafety,
  morningCheckIn,
  emptyState,
}

class NextActionHeroData {
  const NextActionHeroData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.primaryCtaLabel,
    required this.onPrimaryTap,
    this.secondaryCtaLabel,
    this.onSecondaryTap,
    this.isMedicalAlert = false,
  });

  final HeroPriorityType type;
  final String title;
  final String subtitle;
  final String primaryCtaLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryTap;
  final bool isMedicalAlert;
}

/// کارت هیروی اقدام بعدی (Next Action Hero)
/// بر اساس ۵ سطح اولویت:
/// ۱. تایمر فعال
/// ۲. آیتم سررسیدشده یا بعدی امروز
/// ۳. هشدار دارویی (قرمز ایمنی)
/// ۴. چک‌این صبحگاهی
/// ۵. حالت خالی صادقانه
class NextActionHero extends StatelessWidget {
  const NextActionHero({super.key, required this.data});

  final NextActionHeroData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMedical = data.isMedicalAlert;

    final cardBorderColor = isMedical ? colors.medicalRed : colors.border;
    final cardBgColor = isMedical
        ? colors.medicalRed.withValues(alpha: 0.12)
        : colors.cardFill;

    return Semantics(
      container: true,
      label: 'اقدام بعدی: ${data.title}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(RitmoSpacing.lg),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(RitmoRadius.cardLarge),
          border: Border.all(
            color: cardBorderColor,
            width: isMedical ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // نشانگر اولویت بالای کارت
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isMedical
                        ? colors.medicalRed.withValues(alpha: 0.2)
                        : colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(RitmoRadius.chip),
                  ),
                  child: Text(
                    _priorityBadgeText(data.type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMedical ? colors.medicalRed : colors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (data.type == HeroPriorityType.activeTimer)
                  Icon(Icons.timer_outlined, color: colors.primary, size: 20),
              ],
            ),
            const SizedBox(height: RitmoSpacing.md),

            // عنوان و زیرعنوان
            Text(
              toPersianDigits(data.title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.cardTitle,
              ),
            ),
            const SizedBox(height: RitmoSpacing.xs),
            Text(
              toPersianDigits(data.subtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.cardSubtitle),
            ),
            const SizedBox(height: RitmoSpacing.lg),

            // دکمه اقدام اصلی (CTA)
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: data.primaryCtaLabel,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMedical
                              ? colors.medicalRed
                              : colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              RitmoRadius.card,
                            ),
                          ),
                        ),
                        onPressed: () {
                          RitmoHaptics.confirm();
                          data.onPrimaryTap();
                        },
                        child: Text(
                          data.primaryCtaLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (data.secondaryCtaLabel != null &&
                    data.onSecondaryTap != null) ...[
                  const SizedBox(width: RitmoSpacing.md),
                  Semantics(
                    button: true,
                    label: data.secondaryCtaLabel,
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          RitmoHaptics.tap();
                          data.onSecondaryTap!();
                        },
                        child: Text(
                          data.secondaryCtaLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _priorityBadgeText(HeroPriorityType type) {
    return switch (type) {
      HeroPriorityType.activeTimer => 'در حال اجرا',
      HeroPriorityType.overdueOrNextItem => 'اقدام بعدی امروز',
      HeroPriorityType.medicalSafety => 'هشدار دارویی',
      HeroPriorityType.morningCheckIn => 'ارزیابی اول روز',
      HeroPriorityType.emptyState => 'ریتم امروز',
    };
  }
}
