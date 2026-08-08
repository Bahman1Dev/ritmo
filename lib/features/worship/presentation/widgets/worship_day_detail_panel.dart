import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/fullscreen_tasbih_sheet.dart';

class WorshipDayDetailPanel extends StatefulWidget {
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

  @override
  State<WorshipDayDetailPanel> createState() => _WorshipDayDetailPanelState();
}

class _WorshipDayDetailPanelState extends State<WorshipDayDetailPanel> {
  WorshipDay? _worshipDay;
  bool _isLoadingDay = true;

  static const List<String> weekdayNamesFa = [
    'دوشنبه',   // 1
    'سه‌شنبه',  // 2
    'چهارشنبه', // 3
    'پنج‌شنبه',  // 4
    'جمعه',     // 5
    'شنبه',     // 6
    'یکشنبه',   // 7
  ];

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  @override
  void didUpdateWidget(WorshipDayDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay.dateTime != widget.selectedDay.dateTime) {
      _loadDayData();
    }
  }

  Future<void> _loadDayData() async {
    try {
      final dayData = await WorshipEngine.instance.loadDay(widget.selectedDay.dateTime);
      if (mounted) {
        setState(() {
          _worshipDay = dayData;
          _isLoadingDay = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDay = false;
        });
      }
    }
  }

  String _getWeekdayName(int weekday) {
    return weekdayNamesFa[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedDay = widget.selectedDay;
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
            if (selectedDay.isToday && widget.qamariNightText != null) ...[
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
                      widget.qamariNightText!,
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

            // Obligatory Prayers Status Card
            _buildObligatoryPrayersCard(context, colors),

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

  Widget _buildObligatoryPrayersCard(BuildContext context, RitmoColors colors) {
    final prayers = [
      {'key': 'FAJR', 'label': 'صبح'},
      {'key': 'DHUHR', 'label': 'ظهر'},
      {'key': 'ASR', 'label': 'عصر'},
      {'key': 'MAGHRIB', 'label': 'مغرب'},
      {'key': 'ISHA', 'label': 'عشا'},
    ];

    final practiceMap = <String, WorshipPracticeState>{};
    if (_worshipDay != null) {
      for (final st in _worshipDay!.practices) {
        final key = (st.practice.subType ?? st.practice.id).toUpperCase();
        practiceMap[key] = st;
      }
    }

    final isToday = widget.selectedDay.isToday;
    final isFuture = widget.selectedDay.dateTime.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.checkmark_seal_fill, size: 15, color: Color(0xFFC4953B)),
                  const SizedBox(width: 6),
                  Text(
                    'وضعیت نمازهای واجب این روز',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              if (_isLoadingDay)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC4953B)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: prayers.map((p) {
              final pKey = p['key']!;
              final pLabel = p['label']!;
              final st = practiceMap[pKey];

              final isDone = st?.isDone ?? false;
              final resultType = st?.resultType;

              Color bgBadge;
              Color textBadgeColor;
              IconData badgeIcon;
              String statusText;

              if (isDone) {
                bgBadge = const Color(0xFF10B981).withValues(alpha: 0.12);
                textBadgeColor = const Color(0xFF10B981);
                badgeIcon = CupertinoIcons.checkmark_alt_circle_fill;
                statusText = 'خوانده شد';
              } else if (resultType == 'MISSED' || resultType == 'QADA_ADDED') {
                bgBadge = const Color(0xFFE53935).withValues(alpha: 0.12);
                textBadgeColor = const Color(0xFFE53935);
                badgeIcon = CupertinoIcons.xmark_circle_fill;
                statusText = 'قضا شد';
              } else if (resultType == 'SKIPPED') {
                bgBadge = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
                textBadgeColor = const Color(0xFF8B5CF6);
                badgeIcon = CupertinoIcons.moon_fill;
                statusText = 'معاف';
              } else if (isFuture) {
                bgBadge = colors.textPrimary.withValues(alpha: 0.04);
                textBadgeColor = colors.textTertiary;
                badgeIcon = CupertinoIcons.clock;
                statusText = 'در انتظار';
              } else {
                bgBadge = colors.textPrimary.withValues(alpha: 0.05);
                textBadgeColor = colors.textSecondary;
                badgeIcon = CupertinoIcons.circle;
                statusText = isToday ? 'در انتظار' : 'ثبت‌نشده';
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (st != null && !isFuture) {
                      unawaited(HapticFeedback.lightImpact());
                      if (isDone) {
                        await WorshipEngine.instance.logSkip(
                          practiceId: st.practice.id,
                          date: widget.selectedDay.dateTime,
                        );
                      } else {
                        await WorshipEngine.instance.logDone(
                          practiceId: st.practice.id,
                          date: widget.selectedDay.dateTime,
                        );
                      }
                      unawaited(_loadDayData());
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: bgBadge,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: textBadgeColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(badgeIcon, size: 15, color: textBadgeColor),
                        const SizedBox(height: 4),
                        Text(
                          pLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: textBadgeColor,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
                  widget.selectedDay.dailyZikr,
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
              FullscreenTasbihSheet.present(
                context,
                initialDhikrTitle: widget.selectedDay.dailyZikr.split('(').first.trim(),
                dhikrSubtitle: 'ذکر روز هفته',
                targetCount: 100,
                isFatimaTasbih: false,
              );
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

/// شیت جزئیات کامل روز انتخاب‌شده از تقویم
class WorshipDayDetailSheet extends StatelessWidget {
  const WorshipDayDetailSheet({
    super.key,
    required this.selectedDay,
    this.qamariNightText,
    this.onOpenTasbih,
  });

  final WorshipCalendarDay selectedDay;
  final String? qamariNightText;
  final VoidCallback? onOpenTasbih;

  static Future<void> present(
    BuildContext context, {
    required WorshipCalendarDay selectedDay,
    String? qamariNightText,
    VoidCallback? onOpenTasbih,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => WorshipDayDetailSheet(
        selectedDay: selectedDay,
        qamariNightText: qamariNightText,
        onOpenTasbih: onOpenTasbih,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: WorshipDayDetailPanel(
                selectedDay: selectedDay,
                qamariNightText: qamariNightText,
                onOpenTasbih: onOpenTasbih,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
