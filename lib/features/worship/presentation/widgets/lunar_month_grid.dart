// lib/features/worship/presentation/widgets/lunar_month_grid.dart
// Hijri Month Grid View (29/30 days) — Section 4 UI Innovation #4
// Displays worship rhythm on a lunar monthly cycle (not solar weekly),
// transforming into a Fasting Tracker during Ramadan.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

class LunarMonthGrid extends StatefulWidget {
  const LunarMonthGrid({
    super.key,
    required this.currentHijri,
    this.isRamadan = false,
  });

  final HijriDate currentHijri;
  final bool isRamadan;

  @override
  State<LunarMonthGrid> createState() => _LunarMonthGridState();
}

class _LunarMonthGridState extends State<LunarMonthGrid> {
  bool _isLoading = true;
  List<WorshipDay> _monthDays = [];

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    try {
      final now = DateTime.now();
      // Load 30 days around today
      final from = now.subtract(Duration(days: widget.currentHijri.day - 1));
      final to = from.add(const Duration(days: 29));

      final days = await WorshipEngine.instance.loadRange(from, to);
      if (mounted) {
        setState(() {
          _monthDays = days;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hijri = widget.currentHijri;
    final totalDaysInHijri = HijriCalendarCalculator.daysInMonth(hijri.year, hijri.month);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month Title & Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isRamadan ? CupertinoIcons.moon_stars_fill : CupertinoIcons.calendar_today,
                    size: 18,
                    color: widget.isRamadan ? const Color(0xFFFFD700) : colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isRamadan ? 'تقویم روزه‌داری ماه مبارک رمضان' : 'ریتم ماه ${hijri.monthName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${toPersianDigits(totalDaysInHijri.toString())} روز',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 29/30 Day Grid
          if (_isLoading)
            const SizedBox(
              height: 100,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalDaysInHijri,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index + 1;
                final isToday = dayNumber == hijri.day;

                // Match with loaded WorshipDay
                WorshipDay? dayData;
                if (index < _monthDays.length) {
                  dayData = _monthDays[index];
                }

                var doneCount = 0;
                var totalCount = 0;
                if (dayData != null) {
                  totalCount = dayData.practices.length;
                  doneCount = dayData.practices.where((p) => p.isDone).length;
                }

                final ratio = totalCount > 0 ? doneCount / totalCount : 0.0;
                final isFullyDone = ratio >= 1.0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isFullyDone
                        ? colors.primary
                        : ratio > 0
                            ? colors.primary.withValues(alpha: 0.2 + ratio * 0.4)
                            : colors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? colors.primary
                          : Colors.transparent,
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          toPersianDigits(dayNumber.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isFullyDone ? Colors.white : colors.textPrimary,
                          ),
                        ),
                        if (isFullyDone)
                          const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
