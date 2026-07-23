import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/course_detail_screen.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';

/// Section widget for rendering a card list of active goals.
class GoalsCardListSection extends StatelessWidget {

  /// Constructs a [GoalsCardListSection].
  const GoalsCardListSection({
    required this.goals,
    required this.stepsByGoal,
    required this.progressMap,
    required this.routineStatusMap,
    required this.routines,
    required this.courses,
    required this.onRefresh,
    required this.onToggleStep,
    required this.onDeleteGoal,
    required this.onEditGoal,
    super.key,
  });
  /// List of goals to display.
  final List<Goal> goals;

  /// Map of steps grouped by goal ID.
  final Map<String, List<GoalStep>> stepsByGoal;

  /// Map of progress percentages by goal ID.
  final Map<String, double> progressMap;

  /// Map of linked routine status entries by goal ID.
  final Map<String, LinkedRoutineStatus> routineStatusMap;

  /// List of routine maps.
  final List<Map<String, dynamic>> routines;

  /// List of linked courses.
  final List<Course> courses;

  /// Refresh callback.
  final VoidCallback onRefresh;

  /// Step toggle callback.
  final void Function(GoalStep step, String goalId) onToggleStep;

  /// Goal delete callback.
  final void Function(String goalId) onDeleteGoal;

  /// Goal edit callback.
  final void Function(Goal goal) onEditGoal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Filter high-level active goals
    final activeRootGoals = goals
        .where((g) => g.status == 'ACTIVE' && (g.parentGoalId == null || g.parentGoalId!.isEmpty))
        .toList();

    if (activeRootGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.flag, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'هیچ هدف فعالی در حال حاضر وجود ندارد.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: activeRootGoals.length,
      itemBuilder: (context, index) {
        final goal = activeRootGoals[index];
        return _buildGoalCard(context, goal, colors);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, RitmoColors colors) {
    final progress = progressMap[goal.id] ?? 0.0;
    final percent = (progress * 100).toInt();

    // Get sub-goals
    final subGoals = goals.where((g) => g.parentGoalId == goal.id).toList();

    // Find next incomplete step
    final nextStep = _findNextIncompleteStep(goal);

    // Count connections
    final routineConnCount = _countRoutineConnections(goal, subGoals);
    final courseConnCount = courses.where((c) => c.linkedGoalId == goal.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showGoalDetailsSheet(context, goal);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLevelChip(goal.goalType, colors),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colors.border.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${toPersianDigits(percent)}٪',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Next Step
              if (nextStep != null)
                Row(
                  children: [
                    Icon(CupertinoIcons.chevron_left_2, size: 12, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'گام بعدی: ${nextStep.title}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(CupertinoIcons.check_mark_circled, size: 12, color: colors.success),
                    const SizedBox(width: 6),
                    Text(
                      'تمامی گام‌ها تکمیل شده‌اند 🎉',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.success,
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Connection Summary Row
              if (routineConnCount > 0 || courseConnCount > 0) ...[
                const Divider(color: Colors.white10, height: 16),
                Row(
                  children: [
                    if (routineConnCount > 0) ...[
                      Icon(CupertinoIcons.repeat, size: 11, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${toPersianDigits(routineConnCount)} روتین',
                        style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (routineConnCount > 0 && courseConnCount > 0)
                      Text('  ·  ', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    if (courseConnCount > 0) ...[
                      Icon(CupertinoIcons.book, size: 11, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${toPersianDigits(courseConnCount)} دوره آموزش',
                        style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(GoalLevel level, RitmoColors colors) {
    final chipBg = colors.primary.withValues(alpha: 0.1);
    final chipText = colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.bold,
          color: chipText,
        ),
      ),
    );
  }

  GoalStep? _findNextIncompleteStep(Goal goal) {
    // 1. Direct steps
    final directSteps = stepsByGoal[goal.id] ?? [];
    for (final s in directSteps) {
      if (!s.isCompleted) return s;
    }

    // 2. Sub-goal steps
    final subGoals = goals.where((g) => g.parentGoalId == goal.id).toList();
    for (final sg in subGoals) {
      final sgSteps = stepsByGoal[sg.id] ?? [];
      for (final s in sgSteps) {
        if (!s.isCompleted) return s;
      }
    }
    return null;
  }

  int _countRoutineConnections(Goal goal, List<Goal> subGoals) {
    final routineIds = <String>{};
    
    final directSteps = stepsByGoal[goal.id] ?? [];
    for (final s in directSteps) {
      if (s.linkedRoutineId != null) {
        routineIds.add(s.linkedRoutineId!);
      }
    }

    for (final sg in subGoals) {
      final sgSteps = stepsByGoal[sg.id] ?? [];
      for (final s in sgSteps) {
        if (s.linkedRoutineId != null) {
          routineIds.add(s.linkedRoutineId!);
        }
      }
    }

    return routineIds.length;
  }

  void _showGoalDetailsSheet(BuildContext context, Goal rootGoal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalDetailsSheet(
        rootGoal: rootGoal,
        goals: goals,
        stepsByGoal: stepsByGoal,
        progressMap: progressMap,
        routines: routines,
        courses: courses,
        onRefresh: onRefresh,
        onToggleStep: onToggleStep,
        onDeleteGoal: onDeleteGoal,
        onEditGoal: onEditGoal,
      ),
    );
  }
}

/// Sheet widget displaying detailed breakdown of a goal.
class GoalDetailsSheet extends StatefulWidget {

  /// Constructs a [GoalDetailsSheet].
  const GoalDetailsSheet({
    required this.rootGoal,
    required this.goals,
    required this.stepsByGoal,
    required this.progressMap,
    required this.routines,
    required this.courses,
    required this.onRefresh,
    required this.onToggleStep,
    required this.onDeleteGoal,
    required this.onEditGoal,
    super.key,
  });
  /// Target root goal object.
  final Goal rootGoal;

  /// Full list of goals.
  final List<Goal> goals;

  /// Map of steps grouped by goal ID.
  final Map<String, List<GoalStep>> stepsByGoal;

  /// Map of progress values.
  final Map<String, double> progressMap;

  /// List of routines.
  final List<Map<String, dynamic>> routines;

  /// List of courses.
  final List<Course> courses;

  /// Callback to trigger refresh.
  final VoidCallback onRefresh;

  /// Callback when a step is toggled.
  final void Function(GoalStep step, String goalId) onToggleStep;

  /// Callback when a goal is deleted.
  final void Function(String goalId) onDeleteGoal;

  /// Callback when a goal is edited.
  final void Function(Goal goal) onEditGoal;

  @override
  State<GoalDetailsSheet> createState() => _GoalDetailsSheetState();
}

class _GoalDetailsSheetState extends State<GoalDetailsSheet> {
  late Goal _currentGoal;
  final List<Goal> _navigationStack = [];

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.rootGoal;
  }

  void _navigateToSubGoal(Goal subGoal) {
    setState(() {
      _navigationStack.add(_currentGoal);
      _currentGoal = subGoal;
    });
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentGoal = _navigationStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = widget.progressMap[_currentGoal.id] ?? 0.0;
    final percent = (progress * 100).toInt();

    final steps = widget.stepsByGoal[_currentGoal.id] ?? [];
    final subGoals = widget.goals.where((g) => g.parentGoalId == _currentGoal.id).toList();

    // Connected Courses & Routines directly to this goal level
    final linkedRoutineIds = steps
        .where((s) => s.linkedRoutineId != null)
        .map((s) => s.linkedRoutineId!)
        .toSet();
    final connectedRoutines = widget.routines
        .where((r) => linkedRoutineIds.contains(r['id']))
        .toList();
    final connectedCourses = widget.courses
        .where((c) => c.linkedGoalId == _currentGoal.id)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      expand: false,
      snap: true,
      snapSizes: const [0.85, 1.0],
      builder: (context, scrollController) {
        return RitmoTheme.glassCardLight(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Navigation Header (Breadcrumb style)
                if (_navigationStack.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _navigateBack,
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.chevron_right, size: 14, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'بازگشت',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontFamily: 'Vazirmatn',
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·  بازگشت به ${_navigationStack.last.title}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Vazirmatn',
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Goal Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _currentGoal.title,
                              style: TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildLevelChip(_currentGoal.goalType, colors),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Goal Description
                      if (_currentGoal.description != null && _currentGoal.description!.isNotEmpty) ...[
                        Text(
                          _currentGoal.description!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Deadline text
                      if (_currentGoal.targetDate != null && _currentGoal.targetDate!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(CupertinoIcons.time, size: 14, color: colors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _currentGoal.isOverdue
                                  ? 'مهلت گذشته - می‌رسی بهش 💪'
                                  : 'مهلت انجام: ${formatShamsiDate(_currentGoal.targetDate)} (${toPersianDigits(_currentGoal.daysUntilTarget)} روز مانده)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'Vazirmatn',
                                color: _currentGoal.isOverdue ? colors.warning : colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Big Progress Circle & Info Row
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  backgroundColor: colors.border.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                  strokeWidth: 6,
                                ),
                                Text(
                                  '$percent٪',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'وضعیت پیشرفت هدف',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تعداد ${toPersianDigits(steps.where((s) => s.isCompleted).length)} از ${toPersianDigits(steps.length)} گام تکمیل شده است.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Steps Checklist
                      Text(
                        'گام‌های برنامه‌ریزی‌شده',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (steps.isEmpty)
                        Text(
                          'هیچ گامی برای این هدف تعریف نشده است.',
                          style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn', color: colors.textSecondary),
                        )
                      else
                        ...steps.map((step) => _buildStepRow(step, colors)),
                      const SizedBox(height: 24),

                      // Sub-goals Section (Mini Progress Chip wrap)
                      if (subGoals.isNotEmpty) ...[
                        Text(
                          'زیرهدف‌ها',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: subGoals.map((sg) {
                            final sgProgress = widget.progressMap[sg.id] ?? 0.0;
                            return GestureDetector(
                              onTap: () => _navigateToSubGoal(sg),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.card.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        value: sgProgress,
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                        backgroundColor: Colors.white10,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sg.title,
                                      style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Connected courses or routines
                      if (connectedRoutines.isNotEmpty || connectedCourses.isNotEmpty) ...[
                        Text(
                          'ارتباطات متصل',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...connectedRoutines.map((r) => _buildRoutineTile(r, colors)),
                        ...connectedCourses.map((c) => _buildCourseTile(context, c, colors)),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons (Edit, Complete/Restore, Delete)
                      const Divider(color: Colors.white10, height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(CupertinoIcons.pencil, size: 14),
                              label: const Text('ویرایش', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary.withValues(alpha: 0.1),
                                foregroundColor: colors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onEditGoal(_currentGoal);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _currentGoal.status == 'COMPLETED' ? CupertinoIcons.arrow_counterclockwise : CupertinoIcons.archivebox,
                                size: 14,
                              ),
                              label: Text(
                                _currentGoal.status == 'COMPLETED' ? 'بازگردانی' : 'آرشیو',
                                style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                foregroundColor: colors.textPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                final repo = GoalsRepository.instance;
                                final navigator = Navigator.of(context);
                                if (_currentGoal.status == 'COMPLETED') {
                                  await repo.updateGoalStatus(_currentGoal.id, 'ACTIVE');
                                } else {
                                  await repo.updateGoalStatus(_currentGoal.id, 'COMPLETED');
                                }
                                await HapticFeedback.mediumImpact();
                                widget.onRefresh();
                                navigator.pop();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(CupertinoIcons.trash, size: 14),
                        label: const Text('حذف کامل هدف', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('حذف هدف', style: TextStyle(fontFamily: 'Vazirmatn')),
                              content: const Text('آیا از حذف کامل این هدف و تمامی گام‌های آن مطمئن هستید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('حذف', style: TextStyle(fontFamily: 'Vazirmatn')),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );
                          if (confirm ?? false) {
                            widget.onDeleteGoal(_currentGoal.id);
                            await HapticFeedback.vibrate();
                            navigator.pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow(GoalStep step, RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          step.title,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Vazirmatn',
            color: step.isCompleted ? colors.textSecondary : colors.textPrimary,
            decoration: step.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: step.scheduledDate != null
            ? Text(
                'برنامه‌ریزی: ${formatShamsiDate(step.scheduledDate)}',
                style: TextStyle(fontSize: 10.5, fontFamily: 'Vazirmatn', color: colors.textSecondary),
              )
            : null,
        value: step.isCompleted,
        activeColor: colors.primary,
        checkColor: Colors.white,
        onChanged: (val) {
          HapticFeedback.lightImpact(); // Haptic feedback on toggle!
          widget.onToggleStep(step, _currentGoal.id);
          // Auto update the step's value locally in state to reflect change instantly
          setState(() {
            final idx = widget.stepsByGoal[_currentGoal.id]!.indexOf(step);
            if (idx != -1) {
              final updatedStep = GoalStep(
                id: step.id,
                goalId: step.goalId,
                title: step.title,
                isCompleted: val ?? false,
                displayOrder: step.displayOrder,
                createdAt: step.createdAt,
                scheduledDate: step.scheduledDate,
                linkedRoutineId: step.linkedRoutineId,
              );
              widget.stepsByGoal[_currentGoal.id]![idx] = updatedStep;
            }
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildRoutineTile(Map<String, dynamic> routine, RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(CupertinoIcons.repeat, size: 16, color: colors.primary),
        title: Text(
          routine['title'] as String? ?? '',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'دوره روتین تکرارشونده',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
        ),
        trailing: const Icon(CupertinoIcons.chevron_left, size: 12),
        onTap: () {
          // Simply pop details sheet and show routines
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCourseTile(BuildContext context, Course course, RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(CupertinoIcons.book, size: 16, color: colors.primary),
        title: Text(
          course.title,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'دوره آموزشی متصل',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
        ),
        trailing: const Icon(CupertinoIcons.chevron_left, size: 12),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)),
          );
        },
      ),
    );
  }

  Widget _buildLevelChip(GoalLevel level, RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.label,
        style: TextStyle(fontSize: 10, fontFamily: 'Vazirmatn', color: colors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
