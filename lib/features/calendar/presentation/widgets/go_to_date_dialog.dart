import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// K29 — Go To Date Dialog ("برو به تاریخ")
/// Features quick shortcuts at the top:
/// - "امروز" (Today)
/// - "شنبهٔ آینده" (Next Saturday)
/// - "اول ماه بعد" (1st of Next Month)
class GoToDateDialog {
  GoToDateDialog._();

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) async {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    // Calculate next Saturday
    final todayJ = Jalali.fromDateTime(todayOnly);
    // Jalali weekDay: 1=Saturday, 7=Friday
    final daysToNextSat = (8 - todayJ.weekDay) % 7;
    final nextSat = todayOnly.add(Duration(days: daysToNextSat == 0 ? 7 : daysToNextSat));

    // Calculate 1st of next Jalali month
    final nextMonthJ = todayJ.addMonths(1);
    final firstOfNextMonthJ = Jalali(nextMonthJ.year, nextMonthJ.month, 1);
    final firstOfNextMonth = firstOfNextMonthJ.toDateTime();

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          ),
          title: const Text(
            'برو به تاریخ',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'میان‌برهای سریع:',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Shortcuts row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('امروز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    onPressed: () => Navigator.pop(ctx, todayOnly),
                  ),
                  ActionChip(
                    label: const Text('شنبهٔ آینده', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    onPressed: () => Navigator.pop(ctx, nextSat),
                  ),
                  ActionChip(
                    label: const Text('اول ماه بعد', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    onPressed: () => Navigator.pop(ctx, firstOfNextMonth),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Standard date picker launcher button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text(
                    'انتخاب تقویمی…',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null && ctx.mounted) {
                      Navigator.pop(ctx, picked);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          ],
        );
      },
    );
  }
}
