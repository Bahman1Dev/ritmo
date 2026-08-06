import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/logic/worship_occasions_data.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/worship_day_detail_panel.dart';

class WorshipSolarCalendar extends StatefulWidget {
  const WorshipSolarCalendar({
    super.key,
    this.initialJalali,
    this.qamariNightText,
    this.onDaySelected,
    this.onOpenTasbih,
  });

  final Jalali? initialJalali;
  final String? qamariNightText;
  final ValueChanged<WorshipCalendarDay>? onDaySelected;
  final VoidCallback? onOpenTasbih;

  @override
  State<WorshipSolarCalendar> createState() => _WorshipSolarCalendarState();
}

class _WorshipSolarCalendarState extends State<WorshipSolarCalendar> {
  late int _selectedYear;
  late int _selectedMonth;

  late WorshipCalendarMonthData _monthData;
  late WorshipCalendarDay _selectedDay;

  @override
  void initState() {
    super.initState();
    final nowJ = widget.initialJalali ?? Jalali.now();
    _selectedYear = nowJ.year;
    _selectedMonth = nowJ.month;

    _loadMonthData();

    // Default selected day is today or 1st day of month
    _selectedDay = _monthData.days.firstWhere(
      (d) => d.isToday && d.isCurrentMonth,
      orElse: () => _monthData.days.firstWhere((d) => d.isCurrentMonth),
    );
  }

  void _loadMonthData() {
    _monthData = WorshipCalendarLogic.generateMonthData(_selectedYear, _selectedMonth);
  }

  void _goToPrevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedYear--;
        _selectedMonth = 12;
      } else {
        _selectedMonth--;
      }
      _loadMonthData();
      _selectFirstValidDay();
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedYear++;
        _selectedMonth = 1;
      } else {
        _selectedMonth++;
      }
      _loadMonthData();
      _selectFirstValidDay();
    });
  }

  void _goToToday() {
    final nowJ = Jalali.now();
    setState(() {
      _selectedYear = nowJ.year;
      _selectedMonth = nowJ.month;
      _loadMonthData();
      _selectedDay = _monthData.days.firstWhere(
        (d) => d.isToday && d.isCurrentMonth,
        orElse: () => _monthData.days.firstWhere((d) => d.isCurrentMonth),
      );
    });
    if (widget.onDaySelected != null) {
      widget.onDaySelected!(_selectedDay);
    }
  }

  void _selectFirstValidDay() {
    _selectedDay = _monthData.days.firstWhere(
      (d) => d.isToday && d.isCurrentMonth,
      orElse: () => _monthData.days.firstWhere((d) => d.isCurrentMonth),
    );
    if (widget.onDaySelected != null) {
      widget.onDaySelected!(_selectedDay);
    }
  }

  void _onSelectDay(WorshipCalendarDay day) {
    setState(() {
      _selectedDay = day;
    });
    if (widget.onDaySelected != null) {
      widget.onDaySelected!(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Main Premium Solar Calendar Surface Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Navigation, Month Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title & Subtitle Range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_monthData.monthName} ${toPersianDigits(_monthData.year.toString())}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Today Button Shortcut
                            if (!(_selectedYear == Jalali.now().year && _selectedMonth == Jalali.now().month))
                              InkWell(
                                onTap: _goToToday,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC4953B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'امروز',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC4953B),
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_monthData.gregorianRangeText}  •  ${_monthData.hijriRangeText}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Prev / Next Month Controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: _goToNextMonth,
                        icon: const Icon(CupertinoIcons.chevron_forward, size: 18),
                        color: colors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'ماه بعد',
                      ),
                      IconButton(
                        onPressed: _goToPrevMonth,
                        icon: const Icon(CupertinoIcons.chevron_back, size: 18),
                        color: colors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'ماه قبل',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 7-Column Weekday Headers (Saturday to Friday)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeekdayHeader('ش', colors, isFriday: false),
                  _buildWeekdayHeader('ی', colors, isFriday: false),
                  _buildWeekdayHeader('د', colors, isFriday: false),
                  _buildWeekdayHeader('س', colors, isFriday: false),
                  _buildWeekdayHeader('چ', colors, isFriday: false),
                  _buildWeekdayHeader('پ', colors, isFriday: false),
                  _buildWeekdayHeader('ج', colors, isFriday: true),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: colors.textPrimary.withValues(alpha: 0.06)),
              const SizedBox(height: 10),

              // 7-Column Grid (35 or 42 Days)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: GridView.builder(
                  key: ValueKey('${_monthData.year}-${_monthData.month}'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _monthData.days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final day = _monthData.days[index];
                    return _buildDayCell(context, colors, day);
                  },
                ),
              ),
            ],
          ),
        ),

        // Reactive Detail Panel for Selected Day
        WorshipDayDetailPanel(
          selectedDay: _selectedDay,
          qamariNightText: widget.qamariNightText,
          onOpenTasbih: widget.onOpenTasbih,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(String label, RitmoColors colors, {required bool isFriday}) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isFriday ? const Color(0xFFE53935) : colors.textTertiary,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, RitmoColors colors, WorshipCalendarDay day) {
    final isSelected = day.jalali.year == _selectedDay.jalali.year &&
        day.jalali.month == _selectedDay.jalali.month &&
        day.jalali.day == _selectedDay.jalali.day;

    final isToday = day.isToday;
    final isCurrentMonth = day.isCurrentMonth;
    final isFriday = day.isFriday;

    // Card background color
    Color bgColor;
    if (isSelected) {
      bgColor = const Color(0xFFC4953B); // Golden brown premium accent
    } else {
      bgColor = Colors.transparent;
    }

    // Main text color
    Color mainTextColor;
    if (isSelected) {
      mainTextColor = Colors.white;
    } else if (!isCurrentMonth) {
      mainTextColor = colors.textTertiary.withValues(alpha: 0.35);
    } else if (isFriday) {
      mainTextColor = const Color(0xFFE53935);
    } else {
      mainTextColor = colors.textPrimary;
    }

    // Secondary digits color
    Color subTextColor;
    if (isSelected) {
      subTextColor = Colors.white.withValues(alpha: 0.8);
    } else if (!isCurrentMonth) {
      subTextColor = colors.textTertiary.withValues(alpha: 0.25);
    } else {
      subTextColor = colors.textSecondary;
    }

    return GestureDetector(
      onTap: () => _onSelectDay(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFFC4953B), width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC4953B).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Primary Solar Day Number
            Text(
              toPersianDigits(day.jalali.day.toString()),
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                color: mainTextColor,
                fontFamily: 'Vazirmatn',
              ),
            ),

            const SizedBox(height: 1),

            // Secondary Digits: Gregorian & Hijri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.dateTime.day.toString(),
                  style: TextStyle(
                    fontSize: 8,
                    color: subTextColor,
                    fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  ' • ',
                  style: TextStyle(fontSize: 7, color: subTextColor),
                ),
                Text(
                  toPersianDigits(day.hijri.day.toString()),
                  style: TextStyle(
                    fontSize: 8,
                    color: subTextColor,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Occasion Dot Indicators (Max 2 dots)
            if (isCurrentMonth && day.hasOccasions)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: day.occasions.take(2).map((occ) {
                  Color dotColor;
                  switch (occ.category) {
                    case WorshipOccasionCategory.celebration:
                      dotColor = isSelected ? Colors.white : const Color(0xFF10B981);
                      break;
                    case WorshipOccasionCategory.mourning:
                      dotColor = isSelected ? Colors.white : const Color(0xFFE53935);
                      break;
                    case WorshipOccasionCategory.fasting:
                    case WorshipOccasionCategory.worshipDeed:
                      dotColor = isSelected ? Colors.white : const Color(0xFFFFD700);
                      break;
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
