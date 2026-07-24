import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/logic/today_calendar_convergence_helper.dart';

class TodaySchedulePreviewCard extends StatelessWidget {
  TodaySchedulePreviewCard({
    super.key,
    required this.snapshot,
    TodayCalendarConvergenceHelper? convergenceHelper,
  }) : convergenceHelper = convergenceHelper ?? TodayCalendarConvergenceHelper();

  final DayAgendaSnapshot snapshot;
  final TodayCalendarConvergenceHelper convergenceHelper;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = snapshot.currentActivity;
    final next = snapshot.nextActivity;
    final topSuggestion = snapshot.suggestions.isNotEmpty ? snapshot.suggestions.first : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 16,
        color: colors.card.withValues(alpha: 0.65),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'برنامه‌های امروز',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => convergenceHelper.openCalendarInContext(
                      context,
                      itemId: current?.id ?? next?.id,
                    ),
                    icon: const Icon(CupertinoIcons.chevron_left, size: 14),
                    label: const Text(
                      'مشاهده در تقویم',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Current Activity Pill
              if (current != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اکنون: ${current.title}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (current.timeOfDay != null)
                              Text(
                                toPersianDigits('ساعت ${current.timeOfDay} (${current.durationMinutes ?? 30} دقیقه)'),
                                style: TextStyle(fontSize: 10, color: colors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                        tooltip: 'تکمیل برنامه',
                        onPressed: () => convergenceHelper.completeItem(current),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Next Activity Pill
              if (next != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: colors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بعدی: ${next.title}${next.timeOfDay != null ? ' (${toPersianDigits(next.timeOfDay!)})' : ''}',
                          style: TextStyle(fontSize: 12, color: colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Smart Insight / Free Gap Pill
              if (topSuggestion != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.lightbulb_fill, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topSuggestion.message,
                          style: const TextStyle(fontSize: 11, color: Colors.amber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Empty Fallback
              if (current == null && next == null && topSuggestion == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'هیچ برنامه‌ فعالی برای امروز باقی نمانده است.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
