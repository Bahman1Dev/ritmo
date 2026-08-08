import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';

class TaskBucketSection extends StatelessWidget {
  const TaskBucketSection({
    super.key,
    required this.bucket,
    required this.tasks,
    required this.stepCounts,
    required this.attachmentCounts,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onTaskTap,
    required this.onToggleDone,
    required this.onToggleStar,
  });

  final TaskBucket bucket;
  final List<SimpleTask> tasks;
  final Map<String, (int done, int total)> stepCounts;
  final Map<String, int> attachmentCounts;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<SimpleTask> onTaskTap;
  final ValueChanged<SimpleTask> onToggleDone;
  final ValueChanged<SimpleTask> onToggleStar;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final isOverdue = bucket == TaskBucket.overdue;

    final titleColor = isOverdue ? colors.warning : colors.textPrimary;
    final countStr = PersianDigits.toPersian(tasks.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bucket Header
        InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_left,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${bucket.labelFa} ($countStr)',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bucket Items
        if (isExpanded)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final info = stepCounts[task.id];
              final attCount = attachmentCounts[task.id] ?? 0;

              return _TaskCardItem(
                task: task,
                stepInfo: info,
                attachmentCount: attCount,
                onTap: () => onTaskTap(task),
                onToggleDone: () => onToggleDone(task),
                onToggleStar: () => onToggleStar(task),
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TaskCardItem extends StatelessWidget {
  const _TaskCardItem({
    required this.task,
    required this.stepInfo,
    this.attachmentCount = 0,
    required this.onTap,
    required this.onToggleDone,
    required this.onToggleStar,
  });

  final SimpleTask task;
  final (int done, int total)? stepInfo;
  final int attachmentCount;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final info = stepInfo;
    final dueTime = task.dueTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: onTap,
        leading: IconButton(
          icon: Icon(
            task.isDone ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: task.isDone ? colors.success : colors.textTertiary,
            size: 22,
          ),
          onPressed: onToggleDone,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: task.isDone ? colors.textTertiary : colors.textPrimary,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: _buildSubtitle(colors, info, dueTime),
        trailing: IconButton(
          icon: Icon(
            task.isImportant ? CupertinoIcons.star_fill : CupertinoIcons.star,
            color: task.isImportant ? colors.accent : colors.textTertiary,
            size: 20,
          ),
          onPressed: onToggleStar,
        ),
      ),
    );
  }

  Widget? _buildSubtitle(RitmoColors colors, (int, int)? info, String? dueTime) {
    final bool hasSteps = (info != null && info.$2 > 0);
    final bool hasDueTime = dueTime != null;
    final bool hasAttachments = attachmentCount > 0;

    if (!hasSteps && !hasDueTime && !hasAttachments) return null;

    final parts = <Widget>[];

    if (hasSteps) {
      parts.add(Text(
        '${PersianDigits.toPersian(info.$1)} از ${PersianDigits.toPersian(info.$2)}',
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.textSecondary),
      ));
    } else if (hasDueTime) {
      parts.add(Text(
        PersianDigits.toPersian(dueTime!),
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.primary),
      ));
    }

    if (hasAttachments) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
      parts.add(Icon(CupertinoIcons.paperclip, size: 12, color: colors.textSecondary));
      parts.add(const SizedBox(width: 2));
      parts.add(Text(
        PersianDigits.toPersian(attachmentCount),
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.textSecondary),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: parts,
      ),
    );
  }
}
