import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/fullscreen_tasbih_sheet.dart';

class WorshipDayDetailPanel extends StatelessWidget {
  const WorshipDayDetailPanel({
    super.key,
    required this.selectedDay,
    this.qamariNightText,
    this.onOpenTasbih,
  });

  final WorshipCalendarDay selectedDay;

  /// Optional text for Qamari Night if local time is past Maghrib (e.g. "امشب: شب ۲۲ صفر")
  final String? qamariNightText;

  final VoidCallback? onOpenTasbih;

  static const List<String> weekdayNamesFa = [
    'دوشنبه',   // 1
    'سه‌شنبه',  // 2
    'چهارشنبه', // 3
    'پنج‌شنبه',  // 4
    'جمعه',     // 5
    'شنبه',     // 6
    'یکشنبه',   // 7
  ];

  String _getWeekdayName(int weekday) {
    return weekdayNamesFa[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final j = selectedDay.jalali;
    final h = selectedDay.hijri;
    final dt = selectedDay.dateTime;

    final weekdayName = _getWeekdayName(dt.weekday);
    final gMonthName = WorshipCalendarLogic.gregorianMonthNamesFa[dt.month];

    final fullDateText =
        '$weekdayName، ${toPersianDigits(j.day.toString())} ${selectedDay.jalali.formatter.mN} ${toPersianDigits(j.year.toString())}  •  ${toPersianDigits(dt.day.toString())} $gMonthName  •  ${h.formatted}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey('${j.year}-${j.month}-${j.day}'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.textPrimary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Header & Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4953B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    size: 18,
                    color: Color(0xFFC4953B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اعمال و مناسبت‌های ${toPersianDigits(j.day.toString())} ${WorshipCalendarLogic.jalaliMonthNames[j.month - 1]}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullDateText,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),

                // Badges: Today / Qamari Night
                if (selectedDay.isToday) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'امروز',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Qamari Night Badge (if active for today after Maghrib)
            if (selectedDay.isToday && qamariNightText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.moon_stars_fill, size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    Text(
                      qamariNightText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Divider(height: 1, color: colors.textPrimary.withValues(alpha: 0.08)),
            const SizedBox(height: 14),

            // Occasions List or Empty State
            if (selectedDay.hasOccasions) ...[
              ...selectedDay.occasions.map((occ) => _buildOccasionCard(context, colors, occ)),
            ] else ...[
              _buildEmptyOccasionsCard(context, colors),
            ],

            const SizedBox(height: 14),

            // Daily Zikr Section
            _buildDailyZikrCard(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionCard(BuildContext context, RitmoColors colors, WorshipOccasion occ) {
    IconData icon;
    Color iconColor;
    Color bgBadge;

    switch (occ.category) {
      case WorshipOccasionCategory.celebration:
        icon = CupertinoIcons.sparkles;
        iconColor = const Color(0xFF10B981);
        bgBadge = const Color(0xFF10B981).withValues(alpha: 0.1);
        break;
      case WorshipOccasionCategory.mourning:
        icon = CupertinoIcons.moon_fill;
        iconColor = const Color(0xFFE53935);
        bgBadge = const Color(0xFFE53935).withValues(alpha: 0.1);
        break;
      case WorshipOccasionCategory.fasting:
        icon = CupertinoIcons.sun_max_fill;
        iconColor = const Color(0xFFD4A843);
        bgBadge = const Color(0xFFD4A843).withValues(alpha: 0.1);
        break;
      case WorshipOccasionCategory.worshipDeed:
        icon = CupertinoIcons.book_fill;
        iconColor = const Color(0xFF6366F1);
        bgBadge = const Color(0xFF6366F1).withValues(alpha: 0.1);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgBadge,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  occ.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          if (occ.recommendedAmal != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(
                'توصیه عبادی: ${occ.recommendedAmal}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontFamily: 'Vazirmatn',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOccasionsCard(BuildContext context, RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.info_circle, size: 16, color: colors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'مناسبت عبادی خاصی برای این روز ثبت نشده است.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyZikrCard(BuildContext context, RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC4953B).withValues(alpha: 0.08),
            const Color(0xFFD4A843).withValues(alpha: 0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC4953B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.circle_grid_hex_fill, size: 14, color: Color(0xFFC4953B)),
                    const SizedBox(width: 6),
                    Text(
                      'ذکر روز هفته',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selectedDay.dailyZikr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC4953B),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),

          // Action Button: Start Zikr (Real Route)
          InkWell(
            onTap: () {
              if (onOpenTasbih != null) {
                onOpenTasbih!();
              } else {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => FullscreenTasbihSheet(
                      initialDhikrTitle: selectedDay.dailyZikr.split('(').first.trim(),
                      targetCount: 100,
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC4953B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC4953B).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.play_arrow_solid, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'شروع ذکر',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
