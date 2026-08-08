import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/simple_tasks/data/simple_task_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';

/// K25 — Actionable Empty Day View
/// Displayed when a day has no items scheduled.
/// News tone: "برای این روز چیزی ثبت نشده." (no motivational talk).
/// 3 action buttons:
/// 1. "کارهای بدون تاریخ" — sheet with someday tasks to schedule today.
/// 2. "کپی از دیروز" — confirmation dialog + copy yesterday's items.
/// 3. "افزودن" — open UniversalPlannerSheet with prefilled date.
class EmptyDayView extends StatelessWidget {
  const EmptyDayView({
    super.key,
    required this.date,
    required this.onRefreshRequested,
  });

  final DateTime date;
  final VoidCallback onRefreshRequested;

  String get _dateStr =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'برای این روز چیزی ثبت نشده.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: CalendarTokens.textBody,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 24),

            // Button 1: Someday tasks
            _EmptyDayActionButton(
              label: 'کارهای بدون تاریخ',
              icon: Icons.inventory_2_rounded,
              onTap: () => _openSomedayTasksSheet(context),
            ),
            const SizedBox(height: 10),

            // Button 2: Copy from yesterday
            _EmptyDayActionButton(
              label: 'کپی از دیروز',
              icon: Icons.copy_rounded,
              onTap: () => _confirmCopyFromYesterday(context),
            ),
            const SizedBox(height: 10),

            // Button 3: Add new item
            _EmptyDayActionButton(
              label: 'افزودن',
              icon: Icons.add_rounded,
              onTap: () => UniversalPlannerSheet.show(context: context),
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSomedayTasksSheet(BuildContext context) async {
    final somedayTasks = await SimpleTaskRepository.instance.someday();
    if (!context.mounted) return;

    if (somedayTasks.isEmpty) {
      RitmoToast.show(context, 'هیچ کار بدون تاریخی وجود ندارد');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SomedayTasksPickerSheet(
        tasks: somedayTasks,
        targetDateStr: _dateStr,
        onScheduled: () {
          DayAgendaService.instance.invalidateDate(_dateStr);
          onRefreshRequested();
        },
      ),
    );
  }

  Future<void> _confirmCopyFromYesterday(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard)),
        title: const Text(
          'کپی از دیروز',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16),
        ),
        content: const Text(
          'برنامه‌ها و کارهای دیروز به امروز اضافه شوند؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأیید', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      RitmoHaptics.tap();
      // Invalidate target date and refresh
      DayAgendaService.instance.invalidateDate(_dateStr);
      onRefreshRequested();
      RitmoToast.show(context, 'برنامه‌ها کپی شدند');
    }
  }
}

class _EmptyDayActionButton extends StatelessWidget {
  const _EmptyDayActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isPrimary
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          side: BorderSide(
            color: isPrimary
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          ),
        ),
      ),
    );
  }
}

/// Sheet displaying someday tasks to schedule on the selected date.
class _SomedayTasksPickerSheet extends StatelessWidget {
  const _SomedayTasksPickerSheet({
    required this.tasks,
    required this.targetDateStr,
    required this.onScheduled,
  });

  final List<SimpleTask> tasks;
  final String targetDateStr;
  final VoidCallback onScheduled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHigh : theme.cardColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(CalendarTokens.radiusSheet)),
        ),
        padding: const EdgeInsets.all(CalendarTokens.spacingL),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'کارهای بدون تاریخ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (ctx, i) {
                final task = tasks[i];
                return ListTile(
                  title: Text(
                    task.title,
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final updated = task.copyWith(dueDate: targetDateStr);
                      await SimpleTaskRepository.instance.updateTask(updated);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        onScheduled();
                        RitmoToast.show(ctx, 'کار به امروز منتقل شد');
                      }
                    },
                    child: const Text('افزودن به امروز',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
