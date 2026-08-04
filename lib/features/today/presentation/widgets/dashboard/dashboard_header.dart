import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// هدر هیروی داشبورد: سلامِ زمان‌محور + تاریخ جلالی + آواتار با هاله‌ی گرادیان
/// + زنگوله و دکمه‌ی دستیار. فقط لایه‌ی نمایش.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    this.avatarPath,
    required this.isAssistantActive,
    required this.unreadInboxCount,
    required this.onAvatarTap,
    required this.onBellTap,
    required this.onAssistantTap,
  });

  final String userName;
  final String? avatarPath;
  final bool isAssistantActive;
  final int unreadInboxCount;
  final VoidCallback onAvatarTap;
  final VoidCallback onBellTap;
  final VoidCallback onAssistantTap;

  /// سلام زمان‌محور: صبح/ظهر/عصر/شب بخیر
  static ({String greeting, String emoji}) timeGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return (greeting: 'صبح بخیر', emoji: '🌤');
    if (hour >= 12 && hour < 17) return (greeting: 'ظهر بخیر', emoji: '☀️');
    if (hour >= 17 && hour < 21) return (greeting: 'عصر بخیر', emoji: '🌇');
    return (greeting: 'شب بخیر', emoji: '🌙');
  }

  Widget _iconButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            RitmoHaptics.tap();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    // تاریخ
    final String dateStr;
    if (locale.languageCode == 'fa') {
      final jalali = Jalali.now();
      dateStr = '${jalali.formatter.wN} ${jalali.day} ${jalali.formatter.mN}';
    } else {
      final now = DateTime.now();
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      dateStr =
          '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    }

    final tg = timeGreeting(DateTime.now());
    final greetingLine = locale.languageCode == 'fa'
        ? '${tg.greeting}، $userName'
        : l10n.welcomeUser(userName);

    final hasAvatarFile =
        avatarPath != null &&
        avatarPath!.isNotEmpty &&
        File(avatarPath!).existsSync();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // راست: آواتار + سلام و تاریخ
        Expanded(
          child: Row(
            children: [
              // آواتار با هاله‌ی گرادیان انرژی
              Semantics(
                button: true,
                label: 'پروفایل',
                child: GestureDetector(
                  onTap: () {
                    RitmoHaptics.tap();
                    onAvatarTap();
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: colors.energyGradient),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.bg,
                        image: hasAvatarFile
                            ? DecorationImage(
                                image: FileImage(File(avatarPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasAvatarFile
                          ? null
                          : Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0] : '؟',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: RitmoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            greetingLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: RitmoSpacing.xs),
                        Text(tg.emoji, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toPersianDigits(dateStr),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // چپ: دستیار + زنگوله
        Row(
          children: [
            if (isAssistantActive) ...[
              _iconButton(
                context: context,
                semanticLabel: 'گفتگو با دستیار',
                onTap: onAssistantTap,
                child: Icon(
                  CupertinoIcons.sparkles,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: RitmoSpacing.sm),
            ],
            Stack(
              clipBehavior: Clip.none,
              children: [
                _iconButton(
                  context: context,
                  semanticLabel: 'اعلان‌ها',
                  onTap: onBellTap,
                  child: Icon(
                    Icons.notifications_none,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                ),
                if (unreadInboxCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.bg.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          toPersianDigits(unreadInboxCount.toString()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
