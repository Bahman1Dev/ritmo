import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

class WorshipSeasonsSection extends StatefulWidget {

  const WorshipSeasonsSection({
    super.key,
    required this.onChanged,
    this.hijriDate,
  });
  final VoidCallback onChanged;
  final HijriDate? hijriDate;

  @override
  State<WorshipSeasonsSection> createState() => _WorshipSeasonsSectionState();
}

class _WorshipSeasonsSectionState extends State<WorshipSeasonsSection> {
  bool _isLoading = true;
  List<WorshipSeason> _seasons = [];

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  @override
  void didUpdateWidget(WorshipSeasonsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Migration for old Gregorian-based Hijri seasons
      final checkRamadan = await db.query('worship_seasons', where: "id = 'ws_ramadan'", limit: 1);
      if (checkRamadan.isNotEmpty) {
        final start = checkRamadan.first['startDate'] as String? ?? '';
        if (start.contains('-') && start.split('-')[0].length == 4) {
          final batch = db.batch();
          batch.update('worship_seasons', {'startDate': '09-01', 'endDate': '09-30', 'start_date': '09-01', 'end_date': '09-30'}, where: "id = 'ws_ramadan'");
          batch.update('worship_seasons', {'startDate': '01-01', 'endDate': '01-10', 'start_date': '01-01', 'end_date': '01-10'}, where: "id = 'ws_muharram'");
          batch.update('worship_seasons', {'startDate': '12-01', 'endDate': '12-10', 'start_date': '12-01', 'end_date': '12-10'}, where: "id = 'ws_dhul_hijjah'");
          batch.update('worship_seasons', {'startDate': '07-13', 'endDate': '07-15', 'start_date': '07-13', 'end_date': '07-15'}, where: "id = 'ws_ayyam_al_beed'");
          batch.update('worship_seasons', {'startDate': '09-18', 'endDate': '09-22', 'start_date': '09-18', 'end_date': '09-22'}, where: "id = 'ws_qadr'");
          await batch.commit(noResult: true);
        }
      }

      // 2. Seed defaults if empty
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM worship_seasons');
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      if (count == 0) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final defaults = [
          {
            'id': 'ws_ramadan',
            'seasonType': 'FASTING',
            'title': 'ماه مبارک رمضان',
            'startDate': '09-01',
            'endDate': '09-30',
            'calendar': 'HIJRI',
            'isActive': 1,
            'priority_weight': 7.5,
            'createdAt': nowMs,
            'start_date': '09-01',
            'end_date': '09-30',
            'type': 'fasting',
            'is_active': 1,
          },
          {
            'id': 'ws_muharram',
            'seasonType': 'SPIRITUAL',
            'title': 'دهه اول محرم',
            'startDate': '01-01',
            'endDate': '01-10',
            'calendar': 'HIJRI',
            'isActive': 1,
            'priority_weight': 6.0,
            'createdAt': nowMs,
            'start_date': '01-01',
            'end_date': '01-10',
            'type': 'spiritual',
            'is_active': 1,
          },
          {
            'id': 'ws_dhul_hijjah',
            'seasonType': 'SPIRITUAL',
            'title': 'دهه اول ذی‌الحجه (ایام حج)',
            'startDate': '12-01',
            'endDate': '12-10',
            'calendar': 'HIJRI',
            'isActive': 1,
            'priority_weight': 5.5,
            'createdAt': nowMs,
            'start_date': '12-01',
            'end_date': '12-10',
            'type': 'spiritual',
            'is_active': 1,
          },
          {
            'id': 'ws_ayyam_al_beed',
            'seasonType': 'SPIRITUAL',
            'title': 'ایام البیض (اعتکاف)',
            'startDate': '07-13',
            'endDate': '07-15',
            'calendar': 'HIJRI',
            'isActive': 1,
            'priority_weight': 6.5,
            'createdAt': nowMs,
            'start_date': '07-13',
            'end_date': '07-15',
            'type': 'spiritual',
            'is_active': 1,
          },
          {
            'id': 'ws_qadr',
            'seasonType': 'SPIRITUAL',
            'title': 'شب‌های قدر',
            'startDate': '09-18',
            'endDate': '09-22',
            'calendar': 'HIJRI',
            'isActive': 1,
            'priority_weight': 8.0,
            'createdAt': nowMs,
            'start_date': '09-18',
            'end_date': '09-22',
            'type': 'spiritual',
            'is_active': 1,
          },
        ];

        for (final def in defaults) {
          await db.insert('worship_seasons', def);
        }
      }

      // 3. Fetch Seasons
      final results = await db.query('worship_seasons', orderBy: 'startDate DESC');
      final list = results.map(WorshipSeason.fromMap).toList();

      if (mounted) {
        setState(() {
          _seasons = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worship seasons: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showManageSheet() {
    _loadSeasons();
    widget.onChanged();
  }

  String _formatDateToJalali(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final yr = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final dt = DateTime(yr, m, d);
      final jalali = Jalali.fromDateTime(dt);

      final months = [
        'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
        'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
      ];
      return toPersianDigits('${jalali.day} ${months[jalali.month - 1]}');
    } catch (_) {
      return toPersianDigits(dateStr);
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'fasting':
        return 'روزه';
      case 'prayer':
        return 'نماز';
      case 'spiritual':
        return 'معنوی';
      case 'custom':
      default:
        return 'سفارشی';
    }
  }

  Future<void> _toggleSeasonActive(WorshipSeason season, bool active) async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'worship_seasons',
        {
          'isActive': active ? 1 : 0,
          // snake_case
          'is_active': active ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [season.id],
      );
      await _loadSeasons();
      widget.onChanged();
    } catch (e) {
      debugPrint('Error toggling season active status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    final activeSeasons = _seasons.where((s) => s.isActiveNow(widget.hijriDate)).toList();
    final inactiveSeasons = _seasons.where((s) => !s.isActiveNow(widget.hijriDate)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مناسبت‌ها و فصل‌های عبادی',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              GestureDetector(
                onTap: _showManageSheet,
                child: Text(
                  '⚙️ مدیریت',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Seasons Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0b0b0e) : Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.68),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info label
                Text(
                  'این بخش اولویت‌بندی هوشمند کارهای مذهبی روزانه شما را در ایام خاص تقویت می‌کند.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 14),

                if (activeSeasons.isEmpty && inactiveSeasons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'مناسبتی تعریف نشده است.',
                        style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  )
                else ...[
                  // Active List
                  if (activeSeasons.isNotEmpty) ...[
                    Text(
                      'مناسبت‌های جاری:',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 6),
                    ...activeSeasons.map((season) => _buildSeasonRow(season, true, colors)),
                  ],

                  // Divider if both lists have elements
                  if (activeSeasons.isNotEmpty && inactiveSeasons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: colors.border, height: 1),
                    ),

                  // Inactive / Upcoming List
                  if (inactiveSeasons.isNotEmpty) ...[
                    Text(
                      'مناسبت‌های دیگر / آتی:',
                      style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 6),
                    ...inactiveSeasons.take(3).map((season) => _buildSeasonRow(season, false, colors)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeasonPeriod(WorshipSeason season) {
    if (season.calendar.toUpperCase() == 'HIJRI') {
      try {
        final startParts = season.startDate.split('-');
        final endParts = season.endDate.split('-');
        final startM = int.parse(startParts[startParts.length - 2]);
        final startD = int.parse(startParts.last);
        final endM = int.parse(endParts[endParts.length - 2]);
        final endD = int.parse(endParts.last);

        final startMonthName = hijriMonthsFa[startM] ?? '';
        final endMonthName = hijriMonthsFa[endM] ?? '';

        if (startMonthName == endMonthName) {
          return toPersianDigits('$startD تا $endD $startMonthName');
        }
        return toPersianDigits('$startD $startMonthName تا $endD $endMonthName');
      } catch (_) {
        return toPersianDigits('${season.startDate} تا ${season.endDate}');
      }
    } else {
      final startJalali = _formatDateToJalali(season.startDate);
      final endJalali = _formatDateToJalali(season.endDate);
      return '$startJalali تا $endJalali';
    }
  }

  Widget _buildSeasonRow(WorshipSeason season, bool isActiveNow, RitmoColors colors) {
    final dateRangeStr = _formatSeasonPeriod(season);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActiveNow
            ? const Color(0xffD4A843).withValues(alpha: 0.05)
            : colors.textSecondary.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActiveNow
              ? const Color(0xffD4A843).withValues(alpha: 0.3)
              : colors.textSecondary.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActiveNow ? CupertinoIcons.moon_stars_fill : CupertinoIcons.calendar,
            color: isActiveNow ? const Color(0xffD4A843) : colors.iconSecondary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActiveNow ? const Color(0xffC4953B) : colors.cardTitle,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateRangeStr • ${_getTypeLabel(season.seasonType)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),

          // Priority Weight badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActiveNow
                  ? const Color(0xffD4A843).withValues(alpha: 0.15)
                  : colors.textSecondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              toPersianDigits('وزن: ${season.priorityWeight.toStringAsFixed(1)}'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActiveNow ? const Color(0xffC4953B) : colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Active/Inactive toggle
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: season.isActive,
              activeTrackColor: const Color(0xffD4A843),
              onChanged: (val) => _toggleSeasonActive(season, val),
            ),
          ),
        ],
      ),
    );
  }
}
