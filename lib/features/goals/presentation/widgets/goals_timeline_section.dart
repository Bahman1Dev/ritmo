import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/presentation/courses_screen.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Section widget for displaying the timeline of upcoming goals and steps.
class GoalsTimelineSection extends StatelessWidget {

  /// Constructs a [GoalsTimelineSection].
  const GoalsTimelineSection({
    required this.upcomingTimeline,
    required this.overdueSteps,
    required this.goals,
    required this.onRefresh,
    required this.onToggleStep,
    super.key,
  });
  /// List of upcoming timeline items.
  final List<TimelineItem> upcomingTimeline;

  /// List of overdue goal steps.
  final List<GoalStep> overdueSteps;

  /// Full list of goals.
  final List<Goal> goals;

  /// Callback to trigger refresh.
  final VoidCallback onRefresh;

  /// Callback when a step is toggled.
  final void Function(GoalStep step, String goalId) onToggleStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final tomorrowStr =
        DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10);

    if (upcomingTimeline.isEmpty && overdueSteps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'برنامه‌ای برای روزهای آینده ثبت نشده است.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14.5,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group items by month first, and then within each month group by date
    final groupedByMonth = <String, List<TimelineItem>>{}; // Key: "1405-7"
    for (final item in upcomingTimeline) {
      try {
        final dt = DateTime.parse(item.dateIso);
        final jalali = Jalali.fromDateTime(dt);
        final key = '${jalali.year}-${jalali.month}';
        groupedByMonth.putIfAbsent(key, () => []).add(item);
      } catch (_) {
        groupedByMonth.putIfAbsent('سایر', () => []).add(item);
      }
    }

    final sortedMonthKeys =
        groupedByMonth.keys.toList()..sort((a, b) {
          if (a == 'سایر') return 1;
          if (b == 'سایر') return -1;
          final partsA = a.split('-');
          final partsB = b.split('-');
          final yrA = int.parse(partsA[0]);
          final mhA = int.parse(partsA[1]);
          final yrB = int.parse(partsB[0]);
          final mhB = int.parse(partsB[1]);
          if (yrA != yrB) return yrA.compareTo(yrB);
          return mhA.compareTo(mhB);
        });

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: colors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Render Overdue Section at the top
          if (overdueSteps.isNotEmpty) ...[
            _buildSectionHeader('عقب‌افتاده‌ها ⚠️', colors, isOverdue: true),
            const SizedBox(height: 8),
            Card(
              color: colors.warning.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.warning.withValues(alpha: 0.2)),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children:
                      overdueSteps.map((step) {
                        final goal = goals.firstWhere(
                          (g) => g.id == step.goalId,
                          orElse:
                              () => Goal(
                                id: '',
                                title: 'هدف نامشخص',
                                goalType: GoalLevel.daily,
                                createdAt: 0,
                                updatedAt: 0,
                              ),
                        );
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: colors.warning,
                            size: 18,
                          ),
                          title: Text(
                            step.title,
                            style: TextStyle(
                              color: colors.warningText,
                              fontFamily: 'Vazirmatn',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'هدف: ${goal.title} · مهلت: ${formatShamsiDate(step.scheduledDate)}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              CupertinoIcons.checkmark_square,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => onToggleStep(step, step.goalId),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Render Month Groups
          ...sortedMonthKeys.map((monthKey) {
            final monthItems = groupedByMonth[monthKey]!;

            // Calculate statistics
            final stepsCount =
                monthItems
                    .where((i) => i.source == TimelineSource.goalStep)
                    .length;
            final othersCount = monthItems.length - stepsCount;

            var monthTitle = monthKey;
            if (monthKey != 'سایر') {
              final parts = monthKey.split('-');
              final yr = int.parse(parts[0]);
              final mh = int.parse(parts[1]);
              final dummyJalali = Jalali(yr, mh);
              monthTitle = '${dummyJalali.formatter.mN} ${toPersianDigits(yr)}';
            }

            final statsText =
                '${toPersianDigits(stepsCount)} گام · ${toPersianDigits(othersCount)} برنامه‌ جانبی';

            // Group items inside this month by exact day
            final itemsByDay = <String, List<TimelineItem>>{};
            for (final item in monthItems) {
              itemsByDay.putIfAbsent(item.dateIso, () => []).add(item);
            }
            final sortedDays = itemsByDay.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Header
                _buildMonthHeader(monthTitle, statsText, colors),
                const SizedBox(height: 12),

                // Render days within this month
                ...sortedDays.map((dateIso) {
                  var dayTitle = '';
                  final isToday = dateIso == todayStr;

                  if (isToday) {
                    dayTitle = 'امروز';
                  } else if (dateIso == tomorrowStr) {
                    dayTitle = 'فردا';
                  } else {
                    try {
                      final jalali = Jalali.fromDateTime(
                        DateTime.parse(dateIso),
                      );
                      dayTitle =
                          '${jalali.formatter.wN}، ${toPersianDigits(jalali.day)} ${jalali.formatter.mN}';
                    } catch (_) {
                      dayTitle = dateIso;
                    }
                  }

                  final dayItems = itemsByDay[dateIso]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayHeader(dayTitle, isToday, colors),
                        const SizedBox(height: 6),
                        ...dayItems.map(
                          (item) => _buildTimelineItemRow(
                            item,
                            isToday,
                            context,
                            colors,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String title, String stats, RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stats,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white10, height: 1),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String title, bool isToday, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isToday ? colors.primary : colors.textSecondary,
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'امروز',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontFamily: 'Vazirmatn',
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    RitmoColors colors, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isOverdue ? colors.warning : colors.primary,
        ),
      ),
    );
  }

  Widget _buildTimelineItemRow(
    TimelineItem item,
    bool isToday,
    BuildContext context,
    RitmoColors colors,
  ) {
    final hasTodayPulse = isToday && !item.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              hasTodayPulse
                  ? colors.primary.withValues(alpha: 0.6)
                  : colors.border.withValues(alpha: 0.4),
          width: hasTodayPulse ? 1.5 : 1,
        ),
        boxShadow:
            hasTodayPulse
                ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: ListTile(
        onTap: () => _handleItemTap(context, item),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSourceColor(item.source, colors).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.source.icon,
            size: 16,
            color: _getSourceColor(item.source, colors),
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: item.isDone ? colors.textSecondary : colors.textPrimary,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              item.source.label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: _getSourceColor(item.source, colors),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.subtitle != null) ...[
              Text(
                ' · ',
                style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
              ),
              Expanded(
                child: Text(
                  item.subtitle!,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing:
            item.source == TimelineSource.goalStep
                ? IconButton(
                  icon: Icon(
                    item.isDone
                        ? CupertinoIcons.checkmark_square_fill
                        : CupertinoIcons.square,
                    color: item.isDone ? colors.success : colors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    final step = GoalStep(
                      id: item.sourceId,
                      goalId: '',
                      title: item.title,
                      isCompleted: item.isDone,
                      displayOrder: 0,
                      createdAt: 0,
                    );
                    var goalId = '';
                    for (final g in goals) {
                      if (g.id == item.sourceId) {
                        goalId = g.id;
                        break;
                      }
                    }
                    onToggleStep(step, goalId);
                  },
                )
                : Icon(
                  item.isDone ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: item.isDone ? 16 : 12,
                  color: item.isDone ? colors.success : colors.textSecondary,
                ),
      ),
    );
  }

  Color _getSourceColor(TimelineSource source, RitmoColors colors) {
    switch (source) {
      case TimelineSource.goalStep:
        return colors.primary;
      case TimelineSource.courseSession:
        return colors.success;
      case TimelineSource.konkurPlan:
        return colors.warning;
    }
  }

  void _handleItemTap(BuildContext context, TimelineItem item) {
    switch (item.source) {
      case TimelineSource.goalStep:
        break;
      case TimelineSource.courseSession:
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (context) => const CoursesScreen()),
        ).then((_) => onRefresh());
      case TimelineSource.konkurPlan:
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (context) => const KonkurScreen()),
        ).then((_) => onRefresh());
    }
  }
}
