import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/today/presentation/widgets/reshuffle_preview_sheet.dart';
import 'package:ritmo/l10n/app_localizations.dart';

/// سکشن «کارهای امروز» — خارج‌شده از مونولیت داشبورد. فقط لایه‌ی نمایش.
class TodaysTasksSection extends StatelessWidget {

  const TodaysTasksSection({
    super.key,
    required this.tasks,
    required this.onOpenDetails,
    required this.onStartTask,
    required this.onReshuffleApplied,
    this.onViewAll,
  });
  /// آیتم‌های timeline از نوع task (همان ساختار Map قبلی:
  /// {routine, isCompleted, time, title, type})
  final List<Map<String, dynamic>> tasks;
  final Function(Routine) onOpenDetails;
  final Function(Routine) onStartTask;
  final VoidCallback onReshuffleApplied;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.todaysTasksTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.sectionTitle,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => ReshufflePreviewSheet(
                          onApplied: onReshuffleApplied,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(RitmoRadius.chip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RitmoRadius.chip),
                      ),
                      child: Text(
                        l10n.resolveConflictBtn,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RitmoSpacing.md),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      l10n.viewAll,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: RitmoSpacing.md),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.md),
            child: Text(
              l10n.noRoutinesToday,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          )
        else
          ...tasks.take(4).map((task) => _buildTaskCard(context, task)),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = task['isCompleted'] as bool;
    final routine = task['routine'] as Routine;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: RitmoTheme.glassCardLight(
        borderRadius: 18,
        color: colors.card.withValues(alpha: 0.55),
        child: InkWell(
          onTap: () {
            RitmoHaptics.tap();
            onOpenDetails(routine);
          },
          onLongPress: () {
            RitmoHaptics.warning();
            onStartTask(routine);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: RitmoSpacing.lg, vertical: RitmoSpacing.md),
            child: Row(
              children: [
                _categoryIcon(routine),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? colors.textSecondary
                              : colors.textPrimary,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.timeLabel} ${toPersianDigits('${task['time']}')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isCompleted
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color: isCompleted ? colors.success : colors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () {
                      RitmoHaptics.tap();
                      if (!isCompleted) {
                        onStartTask(routine);
                      } else {
                        onOpenDetails(routine);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(Routine routine) {
    var icon = Icons.circle;
    var color = const Color(0xff5B8AF5);
    switch (routine.category) {
      case Category.medical:
        icon = CupertinoIcons.capsule_fill;
        color = const Color(0xffFF6B6B);
      case Category.religious:
        icon = Icons.mosque;
        color = const Color(0xff9B89FF);
      case Category.learning:
        icon = CupertinoIcons.book_fill;
        color = const Color(0xffA78BFA);
      case Category.fitness:
        icon = Icons.directions_run;
        color = const Color(0xff34D399);
      case Category.work:
        icon = CupertinoIcons.briefcase_fill;
        color = const Color(0xff5B8AF5);
      case Category.personal:
        icon = CupertinoIcons.person_fill;
        color = const Color(0xffF5B95B);
      case Category.free:
        icon = CupertinoIcons.heart_fill;
        color = const Color(0xff2DD4BF);
      case Category.konkur:
        icon = Icons.school;
        color = const Color(0xff2563EB);
      case Category.custom:
        icon = Icons.label;
        color = const Color(0xffE25C9A);
    }

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RitmoRadius.chip),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
