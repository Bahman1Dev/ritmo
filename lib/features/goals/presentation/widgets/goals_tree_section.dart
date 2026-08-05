import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';

class GoalsTreeSection extends StatefulWidget {

  const GoalsTreeSection({
    super.key,
    required this.goals,
    required this.stepsByGoal,
    required this.progressMap,
    required this.routineStatusMap,
    required this.routines,
    required this.onRefresh,
    required this.onToggleStep,
    required this.onDeleteGoal,
    required this.onEditGoal,
  });
  final List<Goal> goals;
  final Map<String, List<GoalStep>> stepsByGoal;
  final Map<String, double> progressMap;
  final Map<String, LinkedRoutineStatus> routineStatusMap;
  final List<RoutineRef> routines;
  final VoidCallback onRefresh;
  final void Function(GoalStep step, String goalId) onToggleStep;
  final void Function(String goalId) onDeleteGoal;
  final void Function(Goal goal) onEditGoal;

  @override
  State<GoalsTreeSection> createState() => _GoalsTreeSectionState();
}

class _GoalsTreeSectionState extends State<GoalsTreeSection> {
  final Map<String, bool> _expandedGoals = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rootGoals = widget.goals.where((g) => g.parentGoalId == null || g.parentGoalId!.isEmpty).toList();

    if (rootGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'هیچ هدفی ثبت نشده است.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final visited = <String>{};
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: rootGoals.length,
      itemBuilder: (context, index) {
        return _buildGoalNode(rootGoals[index], colors, 0, visited);
      },
    );
  }

  Widget _buildGoalNode(Goal goal, RitmoColors colors, int depth, Set<String> visited) {
    final goalId = goal.id;
    if (visited.contains(goalId)) return const SizedBox.shrink();
    visited.add(goalId);

    final title = goal.title;
    final desc = goal.description;
    final isCompleted = goal.status == 'COMPLETED';
    final steps = widget.stepsByGoal[goalId] ?? [];
    final children = widget.goals.where((g) => g.parentGoalId == goalId).toList();
    final isExpanded = _expandedGoals[goalId] ?? true;

    final progress = widget.progressMap[goalId] ?? 0.0;
    final percent = (progress * 100).toInt();

    // Check if goal has overdue steps
    final hasOverdueStep = steps.any((s) => s.isOverdue);

    // Calculate days until target deadline
    String? deadlineText;
    var deadlineColor = colors.textSecondary;
    if (goal.targetDate != null && goal.targetDate!.isNotEmpty) {
      if (goal.isOverdue) {
        deadlineText = 'مهلت گذشته - می‌رسی بهش 💪';
        deadlineColor = const Color(0xFFF59E0B); // Amber warning
      } else {
        final days = goal.daysUntilTarget;
        deadlineText = '${toPersianDigits(days)} روز مانده';
        if (days <= 3) {
          deadlineColor = const Color(0xFFF59E0B);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.only(right: 12.0 * depth),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: depth == 0 ? 0.35 : 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: depth == 0 ? 0.6 : 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (children.isNotEmpty || steps.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedGoals[goalId] = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4),
                      child: Icon(
                        isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_left,
                        color: colors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              goal.goalType.label,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? colors.success : colors.textPrimary,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                fontFamily: 'Vazirmatn',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                      // Deadline/Overdue row
                      if (deadlineText != null || hasOverdueStep) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (deadlineText != null)
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: deadlineColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    deadlineText,
                                    style: TextStyle(fontSize: 11, color: deadlineColor, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            if (hasOverdueStep)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'گام عقب‌افتاده',
                                  style: TextStyle(fontSize: 10, color: colors.warning, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit & Delete actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: colors.textSecondary, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => widget.onEditGoal(goal),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(CupertinoIcons.trash, color: colors.warning, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(goal),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      color: colors.border.withValues(alpha: 0.1),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(color: isCompleted ? colors.success : const Color(0xFFF59E0B)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${toPersianDigits(percent)}٪',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Children & Steps
            if (isExpanded) ...[
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.white10, height: 10),
                ...steps.map((step) {
                  final stepDone = step.isCompleted;
                  final routineStatus = widget.routineStatusMap[step.id];

                  // Find routine details if connected
                  RoutineRef? linkedRoutine;
                  if (step.linkedRoutineId != null) {
                    try {
                      linkedRoutine = widget.routines.firstWhere((r) => r.id == step.linkedRoutineId);
                    } catch (_) {}
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => widget.onToggleStep(step, goalId),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Icon(
                                stepDone ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                                color: stepDone ? colors.success : colors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: stepDone ? colors.textSecondary : colors.textPrimary,
                                    decoration: stepDone ? TextDecoration.lineThrough : null,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                              if (step.isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: colors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'عقب‌افتاده',
                                    style: TextStyle(fontSize: 9.5, color: colors.warning, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Linked Routine details chip
                        if (linkedRoutine != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 24, top: 4),
                            child: Material(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _openLinkedRoutine(linkedRoutine!),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.repeat, size: 10, color: colors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'روتین: ${linkedRoutine.title}',
                                        style: TextStyle(fontSize: 10.5, color: colors.primary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                                      ),
                                      if (routineStatus != null && routineStatus.doneCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 1,
                                          height: 8,
                                          color: colors.primary.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'انجام: ${toPersianDigits(routineStatus.doneCount)} · استریک: ${toPersianDigits(routineStatus.streak)}',
                                          style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              if (children.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...children.map((child) => _buildGoalNode(child, colors, depth + 1, visited)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openLinkedRoutine(RoutineRef routine) async {
    await Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, _) => UniversalPlannerSheet(
          routineToEdit: {
            'id': routine.id,
            'title': routine.title,
            'iconKey': routine.iconKey,
            'scheduleSummary': routine.scheduleSummary,
            'isArchived': routine.isArchived ? 1 : 0,
          },
          onSaved: widget.onRefresh,
        ),
      ),
    );
    widget.onRefresh();
  }

  Future<void> _confirmDelete(Goal goal) async {
    final impact = await GoalsRepository.instance.getDeletionImpact(goal.id);
    if (!mounted) return;

    final subInfo = impact.subGoalCount > 0 ? '\n• ${toPersianDigits(impact.subGoalCount)} زیرهدف' : '';
    final stepInfo = impact.stepCount > 0 ? '\n• ${toPersianDigits(impact.stepCount)} گام (شامل ${toPersianDigits(impact.completedStepCount)} گام انجام‌شده)' : '';
    final routineInfo = impact.linkedRoutineCount > 0 ? '\n• ${toPersianDigits(impact.linkedRoutineCount)} اتصال به روتین' : '';
    final reminderInfo = impact.scheduledReminderCount > 0 ? '\n• ${toPersianDigits(impact.scheduledReminderCount)} یادآور فعال (حذف هشدارها)' : '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کامل هدف', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        content: Text(
          'آیا از حذف هدف «${goal.title}» مطمئن هستید؟ موارد زیر برای همیشه حذف خواهند شد:$subInfo$stepInfo$routineInfo$reminderInfo',
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteGoal(goal.id);
            },
            child: const Text('حذف کامل', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

