import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart';
import 'package:ritmo/features/goals/presentation/widgets/create_goal_sheet.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_archive_section.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_card_list_section.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_timeline_section.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_tree_section.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _showTreeView = false; // Toggle tree view vs card list

  List<Goal> _goals = [];
  Map<String, List<GoalStep>> _stepsByGoal = {};
  List<Map<String, dynamic>> _routines = [];
  List<Course> _courses = [];
  List<Map<String, dynamic>> _completions = [];

  GoalsEngineOutput? _engineOutput;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = GoalsRepository.instance;
      final goals = await repo.getGoals();
      final stepsMap = await repo.getGoalSteps();
      final routines = await repo.getRoutines();
      final completions = await repo.getRoutineCompletions();

      final courses = await repo.getCourses();
      final courseSessions = await repo.getCourseSessions();
      final konkurSubjects = await repo.getKonkurSubjects();
      final konkurTopics = await repo.getKonkurTopics();
      final konkurPlanItems = await repo.getKonkurPlanItems();

      // Run GoalsEngine
      final engine = GoalsEngine();
      final input = GoalsEngineInput(
        goals: goals,
        stepsByGoal: stepsMap,
        courses: courses,
        courseSessions: courseSessions,
        konkurSubjects: konkurSubjects,
        konkurTopics: konkurTopics,
        konkurPlanItems: konkurPlanItems,
        routineCompletions: completions,
        today: DateTime.now(),
      );

      final output = await engine.calculate(input);

      setState(() {
        _goals = goals;
        _stepsByGoal = stepsMap;
        _routines = routines;
        _courses = courses;
        _completions = completions;

        _engineOutput = output;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading goals engine data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateGoalSheet({Goal? editGoal, Map<String, dynamic>? templateData}) {
    final activeGoals = _goals.where((g) => g.status == 'ACTIVE').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateGoalSheet(
        activeGoals: activeGoals,
        routines: _routines,
        goalToEdit: editGoal,
        templateData: templateData,
        onSaved: _loadData,
      ),
    );
  }

  void _showAiAssistantSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiGoalsAssistantSheet(
        onSaved: _loadData,
      ),
    );
  }

  void _showArchiveSheet(List<Goal> completedGoals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        expand: false,
        snap: true,
        builder: (context, scrollController) {
          return RitmoTheme.glassCardLight(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'آرشیو اهداف تکمیل شده',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: GoalsArchiveSection(
                      completedGoals: completedGoals,
                      stepsByGoal: _stepsByGoal,
                      onRefresh: _loadData,
                      onRestoreGoal: (goalId) async {
                        await GoalsRepository.instance.updateGoalStatus(goalId, 'ACTIVE');
                        await _loadData();
                      },
                      onDeleteGoal: (goalId) async {
                        await GoalsRepository.instance.deleteGoal(goalId);
                        await _loadData();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _calculateMomentum(Goal goal) {
    var count = 0;
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayOnly.subtract(const Duration(days: 7));

    // Get steps of this goal
    final steps = _stepsByGoal[goal.id] ?? [];
    for (final step in steps) {
      // 1. Toggled steps in last 7 days
      if (step.isCompleted && step.scheduledDate != null) {
        try {
          final dt = DateTime.parse(step.scheduledDate!);
          if (dt.isAfter(sevenDaysAgo) && dt.isBefore(now)) {
            count++;
          }
        } catch (_) {}
      }

      // 2. Linked routines completions in last 7 days
      if (step.linkedRoutineId != null) {
        for (final comp in _completions) {
          final rId = comp['routineId'] as String?;
          final dateStr = comp['completionDate'] as String?;
          if (rId == step.linkedRoutineId && dateStr != null) {
            try {
              final dt = DateTime.parse(dateStr);
              if (dt.isAfter(sevenDaysAgo) && dt.isBefore(now)) {
                count++;
              }
            } catch (_) {}
          }
        }
      }
    }
    return count;
  }

  Goal? _findPolarisGoal(List<Goal> activeGoals) {
    if (activeGoals.isEmpty) return null;
    
    Goal? best;
    var bestScore = -999999;
    
    for (final goal in activeGoals) {
      var score = 0;
      final days = goal.daysUntilTarget;
      if (days >= 0 && days < 30) {
        score += (30 - days) * 100;
      }
      final momentum = _calculateMomentum(goal);
      score += momentum * 50;
      score += goal.updatedAt ~/ 1000000;
      
      if (score > bestScore) {
        bestScore = score;
        best = goal;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final activeGoals = _goals.where((g) => g.status == 'ACTIVE').toList();
    final completedGoals = _goals.where((g) => g.status == 'COMPLETED').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: RitmoIcons.back(context, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'اهداف و برنامه‌ها',
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(CupertinoIcons.wand_stars, color: colors.primary),
              tooltip: 'دستیار هوشمند برنامه‌ریزی',
              onPressed: _showAiAssistantSheet,
            ),
            IconButton(
              icon: Icon(CupertinoIcons.add, color: colors.primary),
              tooltip: 'ثبت هدف جدید',
              onPressed: _showCreateGoalSheet,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.textPrimary),
              onSelected: (val) {
                if (val == 'archive') {
                  _showArchiveSheet(completedGoals);
                } else if (val == 'toggle_view') {
                  setState(() {
                    _showTreeView = !_showTreeView;
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_view',
                  child: Text(
                    _showTreeView ? 'نمای کارت نتیجه‌محور' : 'نمای درختی اهداف',
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text(
                    'آرشیو اهداف',
                    style: TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Polaris Hero (Dynamic active goal vs empty templates)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _isLoading
                  ? const RitmoSkeletonCard()
                  : _buildHeroSection(activeGoals, colors, isDarkMode),
            ),

            // Custom Segmented switcher (اهداف / نقشه راه)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _tabController.animateTo(0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'اهداف',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _tabController.index == 0 ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _tabController.animateTo(1);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'نقشه راه',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _tabController.index == 1 ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Skeletons / Tab views
            Expanded(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: RitmoSkeletonList(itemCount: 3),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Goals Card List or Tree View
                        if (_showTreeView) GoalsTreeSection(
                                goals: activeGoals,
                                stepsByGoal: _stepsByGoal,
                                progressMap: _engineOutput?.goalProgress ?? {},
                                routineStatusMap: _engineOutput?.linkedRoutineStatus ?? {},
                                routines: _routines,
                                onRefresh: _loadData,
                                onToggleStep: (step, goalId) async {
                                  await GoalsRepository.instance.toggleStep(step.id, step.isCompleted, goalId);
                                  await _loadData();
                                },
                                onDeleteGoal: (goalId) async {
                                  await GoalsRepository.instance.deleteGoal(goalId);
                                  await _loadData();
                                },
                                onEditGoal: (goal) {
                                  _showCreateGoalSheet(editGoal: goal);
                                },
                              ) else GoalsCardListSection(
                                goals: _goals,
                                stepsByGoal: _stepsByGoal,
                                progressMap: _engineOutput?.goalProgress ?? {},
                                routineStatusMap: _engineOutput?.linkedRoutineStatus ?? {},
                                routines: _routines,
                                courses: _courses,
                                onRefresh: _loadData,
                                onToggleStep: (step, goalId) async {
                                  await GoalsRepository.instance.toggleStep(step.id, step.isCompleted, goalId);
                                  await _loadData();
                                },
                                onDeleteGoal: (goalId) async {
                                  await GoalsRepository.instance.deleteGoal(goalId);
                                  await _loadData();
                                },
                                onEditGoal: (goal) {
                                  _showCreateGoalSheet(editGoal: goal);
                                },
                              ),

                        // Tab 2: Timeline (Roadmap)
                        GoalsTimelineSection(
                          upcomingTimeline: _engineOutput?.upcomingTimeline ?? [],
                          overdueSteps: _engineOutput?.overdueSteps ?? [],
                          goals: _goals,
                          onRefresh: _loadData,
                          onToggleStep: (step, goalId) async {
                            await GoalsRepository.instance.toggleStep(step.id, step.isCompleted, goalId);
                            await _loadData();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(List<Goal> activeGoals, RitmoColors colors, bool isDarkMode) {
    final polarisGoal = _findPolarisGoal(activeGoals);

    if (polarisGoal != null) {
      // 1. Polaris Goal Card
      final progress = _engineOutput?.goalProgress[polarisGoal.id] ?? 0.0;
      final percent = (progress * 100).toInt();
      final momentum = _calculateMomentum(polarisGoal);

      var deadlineSummary = 'بدون مهلت تعیین‌شده';
      if (polarisGoal.targetDate != null && polarisGoal.targetDate!.isNotEmpty) {
        if (polarisGoal.isOverdue) {
          deadlineSummary = 'مهلت به پایان رسیده ⏳';
        } else {
          deadlineSummary = '${toPersianDigits(polarisGoal.daysUntilTarget)} روز مانده تا پایان مهلت';
        }
      }

      return RitmoTheme.glassCardLight(
        color: colors.primary.withValues(alpha: isDarkMode ? 0.08 : 0.12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Left: Progress Ring
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      backgroundColor: Colors.white10,
                    ),
                    Text(
                      '$percent٪',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              
              // Right: Goal Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ستاره قطبی فعال',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      polarisGoal.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deadlineSummary,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      momentum > 0 ? 'این هفته ${toPersianDigits(momentum)} گام جلو رفتی 🚀' : 'این هفته هنوز گامی برنداشتی؛ شروع کن!',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.success,
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Motivational Template Cards when empty
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'یک هدف جدید انتخاب کنید:',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL horizontal list view scroll direction
            children: [
              _buildTemplateCard('پروژه شخصی', 'راه‌اندازی پروژه شخصی جدید', CupertinoIcons.folder, 'MONTHLY', ['تعریف MVP پروژه', 'طراحی اولیه ایده', 'پیاده‌سازی نسخه اول', 'دریافت اولین بازخوردها'], colors),
              _buildTemplateCard('یادگیری مهارت', 'تسلط بر مهارت یا زبان جدید', CupertinoIcons.infinite, 'MONTHLY', ['انتخاب منبع آموزشی معتبر', 'مطالعه و تمرین روزانه ۳۰ دقیقه', 'انجام اولین پروژه آزمایشی', 'ارزیابی پیشرفت'], colors),
              _buildTemplateCard('پس‌انداز مالی', 'بهبود جریان درآمدی و پس‌انداز', CupertinoIcons.money_dollar, 'ANNUAL', ['ثبت و بودجه‌بندی هزینه‌ها', 'پس‌انداز ۱۰٪ درآمد ماهانه', 'سرمایه‌گذاری در بورس یا طلا', 'کاهش مخارج غیرضروری'], colors),
              _buildTemplateCard('کتاب‌خوانی', 'ایجاد عادت مطالعه مستمر کتاب', CupertinoIcons.book, 'WEEKLY', ['انتخاب اولین کتاب مطالعه', 'مطالعه قبل از خواب (۱۵ دقیقه)', 'خلاصه‌نویسی نکات کلیدی', 'اشتراک‌گذاری خلاصه'], colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    String title,
    String desc,
    IconData icon,
    String goalType,
    List<String> steps,
    RitmoColors colors,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showCreateGoalSheet(templateData: {
            'title': title,
            'description': desc,
            'goalType': goalType,
            'steps': steps,
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(fontSize: 10.5, fontFamily: 'Vazirmatn', color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
