import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:shamsi_date/shamsi_date.dart';

class GoalsArchiveSection extends StatelessWidget {

  const GoalsArchiveSection({
    super.key,
    required this.completedGoals,
    required this.stepsByGoal,
    required this.onRefresh,
    required this.onRestoreGoal,
    required this.onDeleteGoal,
  });
  final List<Goal> completedGoals;
  final Map<String, List<GoalStep>> stepsByGoal;
  final VoidCallback onRefresh;
  final Function(String goalId) onRestoreGoal;
  final Function(String goalId) onDeleteGoal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (completedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'هیچ هدفی در آرشیو وجود ندارد.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: completedGoals.length,
        itemBuilder: (context, index) {
          final goal = completedGoals[index];
          final steps = stepsByGoal[goal.id] ?? [];
          final completedStepsCount = steps.where((s) => s.isCompleted).length;

          // Format shamsi completion date (Fixes ه-11)
          var compDateStr = '';
          try {
            final compMs = goal.completedAt ?? goal.updatedAt;
            final dt = DateTime.fromMillisecondsSinceEpoch(compMs);
            final jalali = Jalali.fromDateTime(dt);
            compDateStr = '${toPersianDigits(jalali.day)} ${jalali.formatter.mN} ${toPersianDigits(jalali.year)}';
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 17.5)),
              ),
              title: Text(
                goal.title,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                'تکمیل در: $compDateStr · ${toPersianDigits(completedStepsCount)} گام انجام شده',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: colors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.settings_backup_restore, color: colors.primary, size: 18),
                    tooltip: 'بازیابی هدف',
                    onPressed: () => onRestoreGoal(goal.id),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.warning, size: 18),
                    tooltip: 'حذف یا رهاسازی',
                    onPressed: () => _confirmDelete(context, goal, colors),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Goal goal, RitmoColors colors) async {
    final impact = await GoalsRepository.instance.getDeletionImpact(goal.id);

    if (!context.mounted) return;

    unawaited(
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأیید حذف یا رهاسازی «${goal.title}»', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('این عملیات بر موارد زیر تأثیر می‌گذارد:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• زیراهداف: ${toPersianDigits(impact.subGoalCount)} عدد', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5)),
                  Text('• گام‌های مرتبط: ${toPersianDigits(impact.stepCount)} عدد (${toPersianDigits(impact.completedStepCount)} گام انجام شده)', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5)),
                  Text('• یادآورهای فعال: ${toPersianDigits(impact.scheduledReminderCount)} عدد', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('می‌توانید به جای حذف کامل، هدف را «رهاسازی» کنید تا آمار آن حفظ شود.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GoalsRepository.instance.updateGoalStatus(goal.id, 'ABANDONED', abandonReason: 'کاربر هدف را رها کرد');
              onRefresh();
            },
            child: const Text('رهاسازی (حفظ آمار)', style: TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFFF59E0B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteGoal(goal.id);
            },
            child: Text('حذف کامل', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.warning, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ));
  }
}
