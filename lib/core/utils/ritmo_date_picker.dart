import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Helper utility for opening a custom Jalali (Shamsi) glassmorphic date picker dialog.
class RitmoDatePicker {
  /// Displays the Jalali date picker dialog returning a Gregorian [DateTime].
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    dynamic builder,
    dynamic locale,
    dynamic theme,
  }) async {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _RitmoDatePickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          colors: colors,
          isDark: isDark,
        );
      },
    );
  }

  /// Displays the Jalali date picker dialog returning a [Jalali] object.
  static Future<Jalali?> showJalali({
    required BuildContext context,
    required Jalali initialDate,
    required Jalali firstDate,
    required Jalali lastDate,
    dynamic builder,
    dynamic locale,
    dynamic theme,
  }) async {
    final result = await show(
      context: context,
      initialDate: initialDate.toDateTime(),
      firstDate: firstDate.toDateTime(),
      lastDate: lastDate.toDateTime(),
      builder: builder,
      locale: locale,
      theme: theme,
    );
    return result != null ? Jalali.fromDateTime(result) : null;
  }
}

class _RitmoDatePickerDialog extends StatefulWidget {

  const _RitmoDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.colors,
    required this.isDark,
  });
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final RitmoColors colors;
  final bool isDark;

  @override
  State<_RitmoDatePickerDialog> createState() => _RitmoDatePickerDialogState();
}

class _RitmoDatePickerDialogState extends State<_RitmoDatePickerDialog> {
  late Jalali _selectedDate;
  late Jalali _viewDate;
  bool _showYearMonthPicker = false;
  late int _selectedYearPicker;

  final List<String> _persianMonths = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  final List<String> _weekdayLabels = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  void initState() {
    super.initState();
    _selectedDate = Jalali.fromDateTime(widget.initialDate);
    _viewDate = Jalali(_selectedDate.year, _selectedDate.month);
    _selectedYearPicker = _viewDate.year;
  }

  Jalali _addMonths(Jalali date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }
    final temp = Jalali(newYear, newMonth);
    final newDay = date.day.clamp(1, temp.monthLength);
    return Jalali(newYear, newMonth, newDay);
  }

  int _getIranianWeekdayIndex(int dartWeekday) {
    if (dartWeekday == 6) return 0; // Sat
    if (dartWeekday == 7) return 1; // Sun
    return dartWeekday + 1; // Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
  }

  String _getPersianWeekdayName(int dartWeekday) {
    switch (dartWeekday) {
      case 6:
        return 'شنبه';
      case 7:
        return 'یکشنبه';
      case 1:
        return 'دوشنبه';
      case 2:
        return 'سه‌شنبه';
      case 3:
        return 'چهارشنبه';
      case 4:
        return 'پنج‌شنبه';
      case 5:
        return 'جمعه';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = widget.isDark;

    final firstDayJalali = Jalali(_viewDate.year, _viewDate.month);
    final firstDayGregorian = firstDayJalali.toDateTime();
    final startOffset = _getIranianWeekdayIndex(firstDayGregorian.weekday);
    final daysInMonth = _viewDate.monthLength;
    final totalCells = startOffset + daysInMonth;

    final jalaliFirstLimit = Jalali.fromDateTime(widget.firstDate);
    final jalaliLastLimit = Jalali.fromDateTime(widget.lastDate);

    final yearsList = List<int>.generate(
      (jalaliLastLimit.year - jalaliFirstLimit.year) + 1,
      (index) => jalaliFirstLimit.year + index,
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color:
                isDark
                    ? const Color(0xFF111424).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.border.withValues(alpha: isDark ? 0.12 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Selected Date Display
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'انتخاب تاریخ',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getPersianWeekdayName(_selectedDate.toDateTime().weekday)}، '
                            '${_selectedDate.day} '
                            '${_persianMonths[_selectedDate.month - 1]} '
                            '${_selectedDate.year}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: colors.border.withValues(alpha: isDark ? 0.12 : 0.4),
                      height: 1,
                    ),
                    const SizedBox(height: 12),

                    // Month/Year navigation row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: colors.textPrimary,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_showYearMonthPicker) {
                                // Shift years page
                              } else {
                                _viewDate = _addMonths(_viewDate, -1);
                                _selectedYearPicker = _viewDate.year;
                              }
                            });
                          },
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showYearMonthPicker = !_showYearMonthPicker;
                              if (_showYearMonthPicker) {
                                _selectedYearPicker = _viewDate.year;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${_persianMonths[_viewDate.month - 1]} '
                                  '${_viewDate.year}',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showYearMonthPicker
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: colors.textPrimary,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_showYearMonthPicker) {
                                // Shift years page
                              } else {
                                _viewDate = _addMonths(_viewDate, 1);
                                _selectedYearPicker = _viewDate.year;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Content panel (Grid or Selector)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child:
                          _showYearMonthPicker
                              ? _buildYearMonthPanel(yearsList, colors, isDark)
                              : _buildDaysPanel(
                                totalCells,
                                startOffset,
                                daysInMonth,
                                jalaliFirstLimit,
                                jalaliLastLimit,
                                colors,
                                isDark,
                              ),
                    ),

                    const SizedBox(height: 16),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'لغو',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              () => Navigator.pop(
                                context,
                                _selectedDate.toDateTime(),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'تایید',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysPanel(
    int totalCells,
    int startOffset,
    int daysInMonth,
    Jalali firstLimit,
    Jalali lastLimit,
    RitmoColors colors,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('days_panel'),
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              _weekdayLabels.map((lbl) {
                return SizedBox(
                  width: 36,
                  child: Text(
                    lbl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox();
            }

            final dayNum = index - startOffset + 1;
            final cellDate = Jalali(_viewDate.year, _viewDate.month, dayNum);

            // Bounds check
            final cellDateTimeRaw = cellDate.toDateTime();
            final cellDateTime = DateTime(
              cellDateTimeRaw.year,
              cellDateTimeRaw.month,
              cellDateTimeRaw.day,
            );
            final limitFirst = DateTime(
              widget.firstDate.year,
              widget.firstDate.month,
              widget.firstDate.day,
            );
            final limitLast = DateTime(
              widget.lastDate.year,
              widget.lastDate.month,
              widget.lastDate.day,
            );
            final isEnabled =
                !cellDateTime.isBefore(limitFirst) &&
                !cellDateTime.isAfter(limitLast);
            final isSelected =
                cellDate.year == _selectedDate.year &&
                cellDate.month == _selectedDate.month &&
                cellDate.day == _selectedDate.day;

            return InkWell(
              onTap:
                  isEnabled
                      ? () {
                        setState(() {
                          _selectedDate = cellDate;
                        });
                      }
                      : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.primary : Colors.transparent,
                ),
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected
                            ? Colors.white
                            : (isEnabled
                                ? colors.textPrimary
                                : colors.textSecondary.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearMonthPanel(
    List<int> yearsList,
    RitmoColors colors,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('year_month_panel'),
      children: [
        // Year selection row
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: yearsList.length,
            itemBuilder: (context, index) {
              final year = yearsList[index];
              final isSelectedYear = year == _selectedYearPicker;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    '$year',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelectedYear,
                  selectedColor: colors.primary.withValues(alpha: 0.15),
                  checkmarkColor: colors.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelectedYear ? colors.primary : colors.textSecondary,
                    fontWeight:
                        isSelectedYear ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedYearPicker = year;
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Months grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final monthName = _persianMonths[index];
            final isSelectedMonth =
                _viewDate.month == monthIndex &&
                _viewDate.year == _selectedYearPicker;

            return InkWell(
              onTap: () {
                setState(() {
                  _viewDate = Jalali(_selectedYearPicker, monthIndex);
                  _showYearMonthPicker = false;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelectedMonth
                            ? colors.primary
                            : colors.border.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  color:
                      isSelectedMonth
                          ? colors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                ),
                child: Text(
                  monthName,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight:
                        isSelectedMonth ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelectedMonth ? colors.primary : colors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
