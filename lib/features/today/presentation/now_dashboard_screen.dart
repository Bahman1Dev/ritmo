import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ritmo/core/ai/ai_briefing_service.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/ad_service.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/services/ritmo_timer_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/assistant/logic/mid_day_replan_service.dart';
import 'package:ritmo/features/assistant/presentation/assistant_screen.dart';
import 'package:ritmo/features/assistant/presentation/widgets/ai_day_planner_preview_sheet.dart';
import 'package:ritmo/features/courses/presentation/courses_screen.dart';
import 'package:ritmo/features/cycle/presentation/cycle_screen.dart';
import 'package:ritmo/features/goals/presentation/goals_screen.dart';
import 'package:ritmo/features/health/presentation/health_screen.dart';
import 'package:ritmo/features/inbox/logic/inbox_navigator.dart';
import 'package:ritmo/features/inbox/presentation/inbox_screen.dart';
import 'package:ritmo/features/study/study_module_entry.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/profile/presentation/profile_screen.dart';
import 'package:ritmo/features/settings/presentation/settings_screen.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/routines/presentation/widgets/routine_snooze_bottom_sheet.dart';
import 'package:ritmo/features/routines/shared/routine_actions.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_details_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_intro_screen.dart';
import 'package:ritmo/features/today/presentation/active_timer_overlay.dart';
import 'package:ritmo/features/today/presentation/dashboard_controller.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/assistant_card.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_module_summary.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/energy_management_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/module_summary_grid.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/next_action_hero.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/today_details_section.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/todays_tasks_section.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/zone_card.dart';
import 'package:ritmo/features/today/presentation/widgets/morning_checkin_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/wellbeing_screen.dart';
import 'package:ritmo/features/worship/presentation/worship_screen.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class NowDashboardScreen extends StatefulWidget {

  const NowDashboardScreen({
    super.key,
    required this.onLogout,
    required this.themeRepository,
    required this.localeRepository,
    this.onNavigateToTab,
  });
  final VoidCallback onLogout;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;
  final Function(int)? onNavigateToTab;

  @override
  State<NowDashboardScreen> createState() => _NowDashboardScreenState();
}

class _NowDashboardScreenState extends State<NowDashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFirstLoad = true;
  AiBriefing? _briefing;
  bool _isBriefingLoading = false;
  int _unreadInboxCount = 0;
  StreamSubscription? _inboxSubscription;
  List<InboxItem> _recentInboxItems = [];


  // Timeline list representation
  List<Map<String, dynamic>> _timelineItems = [];

  // Specialized Dashboard state variables
  Map<String, String> _settingsMap = {};

  DailyBehavior? _dailyBehavior;
  Map<String, dynamic>? _activeZone;
  String? _activeZoneName;
  String? _activeZoneIcon;
  String? _activeZoneTimeRange;
  String? _activeZoneColorHex;
  int _activeZoneRoutinesCount = 0;
  RitmoEngineOutput? _engineOutput;
  bool _needCheckin = true;
  bool _hasReflection = false;
  bool _reflectionDismissed = false;
  bool _showReplanBanner = false;

  // Dynamic Energy State fields
  double _currentEnergyPercent = 65;
  String _currentEnergyLabel = 'متوسط';
  String _currentEnergyDesc = 'مناسب برای مطالعه، پروژه‌ها و روتین‌ها';
  String? _currentEnergyTimeAgo;
  List<String> _currentEnergyExplanation = [];
  String? _peakPerformanceWindow;
  String? _mostFatiguedWindow;
  String? _mostProductiveWeekday;
  List<DashboardModuleSummary> _moduleSummaries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
    _checkActiveTimerOnStart();
    _checkLaunchIntent();
    RitmoEvents.routineChanges.addListener(_onRoutineChanges);
    _updateUnreadCount();
    _inboxSubscription = RitmoEventBus().onEvents.where((e) => e.type == 'inbox_updated').listen((_) {
      _updateUnreadCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxSubscription?.cancel();
    RitmoEvents.routineChanges.removeListener(_onRoutineChanges);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLaunchIntent();
      _loadDashboardData();
    }
  }

  Future<void> _checkLaunchIntent() async {
    final launchInfo = await sl<NotificationPlatform>().getLaunchIntent();
    // Quick Add notification action tapped
    if (launchInfo != null && launchInfo['action'] == 'OPEN_QUICK_ADD') {
      if (mounted) {
        unawaited(Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            pageBuilder: (context, _, _) => UniversalPlannerSheet(
              onSaved: _loadDashboardData,
            ),
          ),
        ));
      }
      return;
    }
    // Home-screen widget row tapped → open that module's screen directly.
    if (launchInfo != null && launchInfo['action'] == 'OPEN_MODULE') {
      final moduleId = launchInfo['moduleId'] as String?;
      if (moduleId != null && moduleId.isNotEmpty && mounted) {
        _openModuleScreen(moduleId);
      }
      return;
    }
    if (launchInfo != null && launchInfo['action'] == 'START_TIMER') {
      final reminderId = launchInfo['reminderId'] as String?;
      if (reminderId != null) {
        final db = await DatabaseHelper.instance.database;
        final List<Map<String, dynamic>> reminders = await db.query(
          'pending_reminders',
          where: 'id = ?',
          whereArgs: [reminderId],
        );
        if (reminders.isNotEmpty) {
          final routineId = reminders.first['routineId'] as String;
          final List<Map<String, dynamic>> routines = await db.query(
            'routines',
            where: 'id = ?',
            whereArgs: [routineId],
          );
          if (routines.isNotEmpty) {
            final rMap = routines.first;
            final categoryStr = rMap['category'] as String;
            final category = Category.values.firstWhere(
              (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
              orElse: () => Category.custom,
            );
            final routine = Routine(
              id: routineId,
              title: rMap['title'] as String,
              description: rMap['description'] as String?,
              category: category,
              routineType: RoutineType.values.firstWhere(
                (e) => e.name.toLowerCase() == (rMap['routineType'] as String? ?? '').toLowerCase(),
                orElse: () => RoutineType.timeBased,
              ),
              notificationLevel: NotificationLevel.values.firstWhere(
                (e) => e.name.toLowerCase() == (rMap['notificationLevel'] as String? ?? '').toLowerCase(),
                orElse: () => NotificationLevel.none,
              ),
              isEssential: rMap['isEssential'] == 1,
              energyRule: EnergyRule.values.firstWhere(
                (e) => e.name.toLowerCase() == (rMap['energyRule'] as String? ?? '').toLowerCase(),
                orElse: () => EnergyRule.none,
              ),
              priority: rMap['priority'] as double? ?? 1.0,
              targetDurationMinutes: rMap['targetDurationMinutes'] as int?,
              lightDurationMinutes: rMap['lightDurationMinutes'] as int?,
              minimalDurationMinutes: rMap['minimalDurationMinutes'] as int?,
              progressionMode: rMap['progressionMode'] as String? ?? 'NONE',
              progressionStart: rMap['progressionStart'] as int? ?? 0,
              progressionTarget: rMap['progressionTarget'] as int? ?? 0,
              progressionStep: rMap['progressionStep'] as int? ?? 0,
              progressionEveryN: rMap['progressionEveryN'] as int? ?? 1,
              progressionCurrent: rMap['progressionCurrent'] as int? ?? 0,
              progressionDoneSinceAdvance: rMap['progressionDoneSinceAdvance'] as int? ?? 0,
              itemType: rMap['itemType'] as String? ?? 'ROUTINE',
            );

            if (mounted) {
              _startTimerFlow(routine, 'FULL');
            }
          }
        }
      }
    }
  }

  Future<void> _updateUnreadCount() async {
    final count = await CentralInboxService.unreadCount();
    if (mounted) {
      setState(() {
        _unreadInboxCount = count;
      });
    }
  }

  void _onRoutineChanges() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _checkActiveTimerOnStart() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = await DatabaseHelper.instance.database;
      final activeTimers = await db.query('active_timers', limit: 1);
      if (activeTimers.isNotEmpty) {
        final timerData = activeTimers.first;
        final routineId = timerData['routineId']! as String;
        final plannedMinutes = timerData['plannedDurationMinutes']! as int;

        final routineMapList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routineMapList.isNotEmpty) {
          final rMap = routineMapList.first;
          final categoryStr = rMap['category']! as String;
          final category = Category.values.firstWhere(
            (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
            orElse: () => Category.custom,
          );
          final routine = Routine(
            id: routineId,
            title: rMap['title']! as String,
            description: rMap['description'] as String?,
            category: category,
            routineType: RoutineType.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['routineType'] as String? ?? '').toLowerCase(),
              orElse: () => RoutineType.timeBased,
            ),
            notificationLevel: NotificationLevel.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['notificationLevel'] as String? ?? '').toLowerCase(),
              orElse: () => NotificationLevel.none,
            ),
            isEssential: rMap['isEssential'] == 1,
            energyRule: EnergyRule.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['energyRule'] as String? ?? '').toLowerCase(),
              orElse: () => EnergyRule.none,
            ),
            priority: rMap['priority'] as double? ?? 1.0,
            targetDurationMinutes: rMap['targetDurationMinutes'] as int?,
            lightDurationMinutes: rMap['lightDurationMinutes'] as int?,
            minimalDurationMinutes: rMap['minimalDurationMinutes'] as int?,
            progressionMode: rMap['progressionMode'] as String? ?? 'NONE',
            progressionStart: rMap['progressionStart'] as int? ?? 0,
            progressionTarget: rMap['progressionTarget'] as int? ?? 0,
            progressionStep: rMap['progressionStep'] as int? ?? 0,
            progressionEveryN: rMap['progressionEveryN'] as int? ?? 1,
            progressionCurrent: rMap['progressionCurrent'] as int? ?? 0,
            progressionDoneSinceAdvance: rMap['progressionDoneSinceAdvance'] as int? ?? 0,
            itemType: rMap['itemType'] as String? ?? 'ROUTINE',
          );

          var mode = 'FULL';
          if (plannedMinutes == routine.lightDurationMinutes) {
            mode = 'LIGHT';
          } else if (plannedMinutes == routine.minimalDurationMinutes) {
            mode = 'MINIMAL';
          }

          if (mounted) {
            _startTimerFlow(routine, mode);
          }
        }
      }
    });
  }

  Future<void> _refreshBriefing() async {
    if (!mounted) return;
    setState(() {
      _isBriefingLoading = true;
    });
    try {
      final b = await AiBriefingService.instance.getOrRefresh(force: true);
      if (mounted) {
        setState(() {
          _briefing = b;
        });
      }
    } catch (e) {
      debugPrint('[BRIEFING] Manual refresh failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBriefingLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading || _isFirstLoad) {
      setState(() {
        _isLoading = true;
      });
    }

    final controller = DashboardController();

    // ── P0: critical path (settings → routines → RIE → timeline) ──────────
    await controller.loadP0();

    if (!mounted) return;
    setState(() {
      _isFirstLoad = false;
      _isLoading = false;
      _timelineItems = controller.timelineItems;
      _settingsMap = controller.settingsMap;
      _activeZone = controller.activeZone;
      _activeZoneName = controller.activeZoneName;
      _activeZoneIcon = controller.activeZoneIcon;
      _activeZoneTimeRange = controller.activeZoneTimeRange;
      _activeZoneColorHex = controller.activeZoneColorHex;
      _activeZoneRoutinesCount = controller.activeZoneRoutinesCount;
      _engineOutput = controller.engineOutput;
      _needCheckin = controller.needCheckin;
      _hasReflection = controller.hasReflection;
      _reflectionDismissed = controller.reflectionDismissed;
    });

    // ── P1: deferred — runs after first frame is painted ─────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await controller.loadP1();

      var recentInbox = <InboxItem>[];
      try {
        recentInbox = await CentralInboxService.getItems(
          statusFilter: InboxStatus.UNREAD,
          limit: 3,
        );
      } catch (e) {
        debugPrint('Error loading recent inbox: $e');
      }

      final showReplan = await MidDayReplanService.instance.shouldSuggestReplan();

      if (!mounted) return;
      setState(() {
        _briefing = controller.briefing;
        _isBriefingLoading = controller.isBriefingLoading;
        _dailyBehavior = controller.dailyBehavior;
        _currentEnergyPercent = controller.currentEnergyPercent;
        _currentEnergyLabel = controller.currentEnergyLabel;
        _currentEnergyDesc = controller.currentEnergyDesc;
        _currentEnergyTimeAgo = controller.currentEnergyTimeAgo;
        _currentEnergyExplanation = controller.currentEnergyExplanation;
        _peakPerformanceWindow = controller.peakPerformanceWindow;
        _mostFatiguedWindow = controller.mostFatiguedWindow;
        _mostProductiveWeekday = controller.mostProductiveWeekday;
        _moduleSummaries = controller.moduleSummaries;
        _recentInboxItems = recentInbox;
        _showReplanBanner = showReplan;
      });

      await _pushCriticalAlerts();
      await _pushCheckinsAndReflections();
    });
  }

  void _openModuleScreen(String moduleId) {
    Widget? screen;
    switch (moduleId) {
      case 'sleep': screen = const WellbeingScreen(initialSection: WellbeingSection.sleep);
      case 'sports':
        _openSupplementarySports();
        return;
      case 'energy': screen = const WellbeingScreen();
      case 'medicine': screen = const HealthScreen();
      case 'worship': screen = const WorshipScreen();
      case 'cycle': screen = const CycleScreen();
      case 'goals': screen = const GoalsScreen();
      case 'courses':
        screen = const CoursesScreen(); // can() always returns true
      case 'study':
      case 'konkur':
        StudyModuleEntry.open(context).then((_) => _loadDashboardData());
        return;
    }
    if (screen == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!))
        .then((_) => _loadDashboardData());
  }

  Future<void> _openSupplementarySports() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final profiles = await db.query('ss_user_profile', where: 'onboardingCompleted = 1', limit: 1);
      final hasCompletedOnboarding = profiles.isNotEmpty;

      if (mounted) {
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => hasCompletedOnboarding 
                ? const SSHomeDashboardScreen() 
                : const SSIntroScreen(),
          ),
        ).then((_) => _loadDashboardData()));
      }
    } catch (e) {
      debugPrint('Error opening supplementary sports: $e');
      if (mounted) {
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SSIntroScreen(),
          ),
        ).then((_) => _loadDashboardData()));
      }
    }
  }

  Future<void> _completeTask(Routine routine, String resultType, [int? customDuration]) async {
    final todayStr = RitmoDate.now().value;

    if (resultType == 'SKIPPED') {
      await RitmoExecutionKernel.instance.execute(
        SkipOccurrenceCommand(routineId: routine.id, dateStr: todayStr),
      );
    } else {
      final duration = DurationBounds.resolveForCompletion(
        targetMinutes: routine.targetDurationMinutes,
        lightMinutes: routine.lightDurationMinutes,
        minimalMinutes: routine.minimalDurationMinutes,
        resultType: resultType,
        customDuration: customDuration,
        currentTargetMinutes: routine.currentTargetMinutes,
      );

      await RitmoExecutionKernel.instance.execute(
        CompleteOccurrenceCommand(
          routineId: routine.id,
          dateStr: todayStr,
          resultType: resultType,
          durationMinutes: duration,
        ),
      );
    }

    if (mounted) {
      var msg = 'روتین "${routine.title}" انجام شد! 🌟';
      if (resultType == 'LIGHT') msg = 'روتین "${routine.title}" به صورت سبک انجام شد! ⚡';
      if (resultType == 'MINIMAL') msg = 'روتین "${routine.title}" به صورت حداقلی انجام شد! 🌿';
      if (resultType == 'SKIPPED') msg = 'روتین "${routine.title}" رد شد. ✕';
      if (resultType == 'CANNOT_NOW' || resultType == 'SNOOZED') {
        msg = 'روتین "${routine.title}" به تعویق افتاد. ⏳';
      }

      final colors = context.colors;
      final isWarning = (resultType == 'CANNOT_NOW' || resultType == 'SNOOZED' || resultType == 'SKIPPED');
      RitmoToast.show(
        context,
        msg,
        icon: isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        iconColor: isWarning ? colors.warning : colors.success,
      );
    }

    unawaited(_loadDashboardData());
  }

  /// ورود پلکانی سکشن‌ها — با احترام به Reduced Motion
  Widget _enter(int slot, Widget child) {
    if (RitmoMotion.reduceMotion(context)) return child;
    return child
        .animate(delay: Duration(milliseconds: 45 * slot))
        .fadeIn(duration: RitmoMotion.normal, curve: RitmoMotion.standard)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: RitmoMotion.normal,
          curve: RitmoMotion.standard,
        );
  }

  /// اسکلت لودینگ هم‌شکل با چیدمان صفحه — به‌جای اسپینر (سند طراحی §۴.۲)
  Widget _buildLoadingSkeleton() {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر: آواتار + دو خط متن + زنگوله
              Row(
                children: [
                  RitmoSkeleton(width: 48, height: 48, borderRadius: 24),
                  SizedBox(width: RitmoSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RitmoSkeleton(width: 120, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      RitmoSkeleton(width: 80, height: 10, borderRadius: 4),
                    ],
                  ),
                  Spacer(),
                  RitmoSkeleton(width: 44, height: 44, borderRadius: 22),
                ],
              ),
              SizedBox(height: RitmoSpacing.section),
              // نوار زمینه
              RitmoSkeleton(
                  width: double.infinity, height: 36, borderRadius: 12),
              SizedBox(height: RitmoSpacing.section),
              // کارت هیروی نبض
              RitmoSkeleton(
                  width: double.infinity, height: 190, borderRadius: 20),
              SizedBox(height: RitmoSpacing.section),
              // کارت زون
              RitmoSkeleton(
                  width: double.infinity, height: 130, borderRadius: 20),
              SizedBox(height: RitmoSpacing.section),
              // کارت دستیار
              RitmoSkeleton(
                  width: double.infinity, height: 170, borderRadius: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    final tasksList = _timelineItems.where((i) => i['type'] == 'task').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Directionality(
        textDirection: Localizations.localeOf(context).languageCode == 'fa'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: colors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130), // space for bottom dock
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. هدر هیرو
                _enter(
                  0,
                  DashboardHeader(
                    userName: _settingsMap['user_name'] ?? 'کاربر',
                    avatarPath: _settingsMap['user_avatar_path'],
                    isAssistantActive:
                        _settingsMap['module_assistant_enabled'] == 'true',
                    unreadInboxCount: _unreadInboxCount,
                    onAvatarTap: _showMoreSheet,
                    onBellTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const InboxScreen()),
                      ).then((_) => _updateUnreadCount());
                    },
                    onAssistantTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AssistantScreen()),
                      );
                    },
                  ),
                ),
                _enter(
                  1,
                  _buildCriticalAlertsSection(),
                ),

                // 2. کارت هیروی اقدام بعدی (Next Action Hero)
                _enter(
                  2,
                  NextActionHero(
                    data: _buildNextActionHeroData(),
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 3. کارهای امروز (Agenda - max 3-5 items)
                _enter(
                  2,
                  TodaysTasksSection(
                    tasks: tasksList.take(5).toList(),
                    onOpenDetails: _showDetailsSheet,
                    onStartTask: _showNiyyahSheet,
                    onReshuffleApplied: _loadDashboardData,
                    onViewAll: () => widget.onNavigateToTab?.call(4),
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 4. کارت خلاصه‌ی وضعیت تک‌عاملی (ZoneCard / Energy)
                _enter(
                  3,
                  ZoneCard(
                    isDarkMode: isDarkMode,
                    currentEnergyPercent: _currentEnergyPercent,
                    currentEnergyLabel: _currentEnergyLabel,
                    currentEnergyDesc: _currentEnergyDesc,
                    activeZone: _activeZone,
                    activeZoneName: _activeZoneName,
                    activeZoneIcon: _activeZoneIcon,
                    activeZoneColorHex: _activeZoneColorHex,
                    activeZoneRoutinesCount: _activeZoneRoutinesCount,
                    activeZoneTimeRange: _activeZoneTimeRange,
                    onEnergyTap: () => _showEnergyManagementSheet(isDarkMode),
                    onRealmChanged: _loadDashboardData,
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 5. حداکثر یک پیشنهاد دستیار
                _enter(
                  4,
                  AssistantCard(
                    suggestedRoutine: _engineOutput?.suggestedRoutine,
                    suggestLightVersion:
                        _engineOutput?.suggestLightVersion ?? false,
                    activeZoneName: _activeZoneName ?? '',
                    defaultEnergyLevel:
                        _settingsMap['default_energy_level'] ?? 'MEDIUM',
                    dailyBehavior: _dailyBehavior,
                    onStartTap: _showNiyyahSheet,
                    onWhyTap: _showWhySuggestionDialog,
                    briefing: _briefing,
                    isBriefingLoading: _isBriefingLoading,
                    onRefreshBriefing: _refreshBriefing,
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 6. بخش تاشوی «جزئیات امروز» (پیش‌فرض بسته)
                _enter(
                  5,
                  TodayDetailsSection(
                    itemCount: _moduleSummaries.length + (_showReplanBanner ? 1 : 0),
                    children: [
                      if (_showReplanBanner) ...[
                        _buildMidDayReplanBanner(),
                        const SizedBox(height: RitmoSpacing.md),
                      ],
                      ModuleSummaryGrid(
                        summaries: _moduleSummaries,
                        onModuleTap: _openModuleScreen,
                      ),
                      const SizedBox(height: RitmoSpacing.md),
                      _buildCheckinReminderCard(),
                      _buildReflectionSuggestionCard(),
                      _buildRecentInboxAlertsSection(colors),
                    ],
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),
                AdService.instance.getBannerAd(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NextActionHeroData _buildNextActionHeroData() {
    final timers = RitmoTimerService.instance.activeTimers;
    final activeTimer = timers.isNotEmpty ? timers.first : null;
    if (activeTimer != null) {
      return NextActionHeroData(
        type: HeroPriorityType.activeTimer,
        title: 'کار در حال اجرا: ${activeTimer.itemId}',
        subtitle: '${PersianDigits.convert(((activeTimer.durationSeconds) / 60).round().toString())} دقیقه · حالت ${activeTimer.mode}',
        primaryCtaLabel: 'ادامه / مشاهده',
        onPrimaryTap: () {
          widget.onNavigateToTab?.call(2);
        },
      );
    }

    final nextItem = _timelineItems.isNotEmpty ? _timelineItems.first : null;
    if (nextItem != null) {
      final title = nextItem['title']?.toString() ?? 'برنامه‌ی بعدی';
      final timeStr = nextItem['scheduled_time']?.toString() ?? 'امروز';
      final routineId = nextItem['routine_id']?.toString() ?? nextItem['id']?.toString();
      return NextActionHeroData(
        type: HeroPriorityType.overdueOrNextItem,
        title: title,
        subtitle: 'زمان: ${PersianDigits.convert(timeStr)}',
        primaryCtaLabel: 'ثبت / شروع',
        onPrimaryTap: () async {
          if (routineId != null) {
            final db = await DatabaseHelper.instance.database;
            final rows = await db.query('routines', where: 'id = ?', whereArgs: [routineId], limit: 1);
            if (rows.isNotEmpty) {
              final r = Routine.fromMap(rows.first);
              _showNiyyahSheet(r);
            }
          }
        },
      );
    }

    if (_settingsMap['module_medicine_enabled'] == 'true' && _needCheckin) {
      return NextActionHeroData(
        type: HeroPriorityType.medicalSafety,
        title: 'بررسی ایمنی دارویی و مصرف امروز',
        subtitle: 'ثبت وضعیت مصرف داروهای فعال',
        primaryCtaLabel: 'ثبت مصرف دارو',
        isMedicalAlert: true,
        onPrimaryTap: () => _openModuleScreen('medicine'),
      );
    }

    if (_needCheckin) {
      return NextActionHeroData(
        type: HeroPriorityType.morningCheckIn,
        title: 'ارزیابی انرژی اول روز',
        subtitle: 'تنظیم ریتم فعالیت با چند پرسش کوتاه',
        primaryCtaLabel: 'شروع ارزیابی',
        onPrimaryTap: _showMorningCheckinSheet,
      );
    }

    return NextActionHeroData(
      type: HeroPriorityType.emptyState,
      title: 'برنامه‌ای برای این زمان ثبت نشده است',
      subtitle: 'با افزودن کار جدید، ریتم امروزتان را شکل دهید',
      primaryCtaLabel: 'افزودن برنامه',
      onPrimaryTap: () {
        UniversalPlannerSheet.show(context: context);
      },
    );
  }

  void _showMoreSheet() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => SettingsScreen(
          onFactoryReset: widget.onLogout,
          themeRepository: widget.themeRepository,
          localeRepository: widget.localeRepository,
        ),
      ),
    ).then((_) {
      if (mounted) _loadDashboardData();
    });
  }

  Future<void> _snoozeTask(Routine routine) async {
    RoutineSnoozeBottomSheet.show(
      context: context,
      routine: routine,
      onSnoozeSelected: (minutes) {
        _snoozeRoutineWithMinutes(routine, minutes);
      },
    );
  }

  Future<void> _snoozeRoutineWithMinutes(Routine routine, int snoozeMin) async {
    final todayStr = RitmoDate.now().value;
    final decision = SnoozePolicy.evaluate(
      itemId: routine.id,
      now: DateTime.now(),
      requestedMinutes: snoozeMin,
      currentDeferCount: 0,
      category: routine.category.name,
      isEssential: routine.isEssential ? 1 : 0,
    );

    final isBlocked = decision.verdict == SnoozeVerdict.exhausted ||
        decision.verdict == SnoozeVerdict.blockedMidnight;

    if (isBlocked) {
      if (mounted) {
        RitmoToast.show(
          context,
          decision.userMessage ?? 'امکان تعویق وجود ندارد.',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
      return;
    }

    await RoutineActions.snoozeRoutine(
      context: context,
      routineId: routine.id,
      dateStr: todayStr,
      minutes: decision.allowedMinutes,
      onDone: () {
        if (mounted) _loadDashboardData();
      },
    );
  }

  void _showMorningCheckinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MorningCheckinSheet(
        onSaved: () {
          final now = DateTime.now();
          final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          CentralInboxService.markActionedForEntity('system', 'checkin_$dateStr');
          _loadDashboardData();
        },
      ),
    );
  }

  void _showNiyyahSheet(Routine routine, {String initialMode = 'FULL'}) {
    RoutineNiyyahSheet.show(
      context: context,
      routine: routine,
      initialMode: initialMode,
      onStartTimer: (selectedMode) async {
        _startTimerFlow(routine, selectedMode);
      },
      onCompleteInstantly: (selectedMode, duration) async {
        await _completeTask(routine, selectedMode, duration);
      },
      onSnooze: () async {
        await _snoozeTask(routine);
      },
      onEdit: () async {
        final rMap = {
          'id': routine.id,
          'title': routine.title,
          'description': routine.description,
          'category': routine.category.name,
          'routineType': routine.routineType.name,
          'notificationLevel': routine.notificationLevel.name,
          'isEssential': routine.isEssential ? 1 : 0,
          'energyRule': routine.energyRule.name,
          'priority': routine.priority,
          'targetDurationMinutes': routine.targetDurationMinutes,
          'lightDurationMinutes': routine.lightDurationMinutes,
          'minimalDurationMinutes': routine.minimalDurationMinutes,
        };

        await Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            pageBuilder: (context, _, _) => UniversalPlannerSheet(
              routineToEdit: rMap,
              onSaved: _loadDashboardData,
            ),
          ),
        );
      },
      onViewDetails: () async {
        _showDetailsSheet(routine);
      },
    );
  }

  void _showDetailsSheet(Routine routine) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    RoutineDetailsSheet.show(
      context: context,
      routine: routine,
      targetDate: todayStr,
      onReverted: _loadDashboardData,
    );
  }

  void _startTimerFlow(Routine routine, String mode) {
    // T4: compute today's date explicitly and pass as dateStr
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTimerOverlay(
          routine: routine,
          completionMode: mode,
          dateStr: todayStr,         // T4: explicit, not hidden DateTime.now() inside overlay
          onCompleted: (outcome) {  // T6: only on confirmed completion
            Navigator.pop(context);
            _loadDashboardData();
            if (outcome.didWrite) {
              RitmoToast.show(context, 'روتین با تایمر ثبت شد ✓');
            } else {
              RitmoToast.show(context, outcome.errorMessage ?? 'ثبت انجام نشد');
            }
          },
          onCancelled: () {         // T6: neutral — no success message
            Navigator.pop(context);
            // No feedback — user chose not to complete
          },
        ),
      ),
    );
  }

  void _showWhySuggestionDialog(String titleText) {
    final l10n = AppLocalizations.of(context)!;
    var explanationText = 'سیستم بر اساس موتور تحلیل بافت (Context Engine)، شرایط زمانی و انرژی فعلی شما را سنجیده است.';
    
    if (_engineOutput?.contextExplanation != null) {
      final exp = _engineOutput!.contextExplanation;
      final title = exp.params['title'] as String? ?? titleText;
      switch (exp.type) {
        case ContextExplanationType.rest:
          explanationText = l10n.contextExplanationRest;
        case ContextExplanationType.essential:
          explanationText = l10n.contextExplanationEssential(title);
        case ContextExplanationType.sick:
          explanationText = l10n.contextExplanationSick(title);
        case ContextExplanationType.exam:
          explanationText = l10n.contextExplanationExam(title);
        case ContextExplanationType.busy:
          explanationText = l10n.contextExplanationBusy(title);
        case ContextExplanationType.worship:
          explanationText = l10n.contextExplanationWorship(exp.params['season'] as String? ?? '', title);
        case ContextExplanationType.zone:
          explanationText = l10n.contextExplanationZone(title);
        case ContextExplanationType.lowEnergy:
          explanationText = l10n.contextExplanationLowEnergy(title);
        case ContextExplanationType.dynamic:
          explanationText = l10n.contextExplanationDynamic(title);
        case ContextExplanationType.reflectionAware:
          explanationText =
              'با توجه به خودارزیابی اخیر و حال‌وهوای این روزهایت، نسخه‌ی سبک‌تر «$title» را پیشنهاد دادم تا با ملایمت پیش بروی. کارهای ضروری همچنان سرجای خود هستند. 🌿';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.card,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(CupertinoIcons.sparkles, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'تحلیل هوشمند ریتمو',
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              explanationText,
              style: TextStyle(fontSize: 13, height: 1.6, color: colors.textPrimary.withValues(alpha: 0.9), fontFamily: 'Vazirmatn'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('فهمیدم', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showEnergyManagementSheet(bool isDarkMode) async {
    final result = await EnergyManagementSheet.present(context);
    if (result == true) {
      await _loadDashboardData();
    }
  }








  Widget _buildCheckinReminderCard() {
    if (!_needCheckin) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RitmoTheme.glassCardLight(
        color: colors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => MorningCheckinSheet(
                onSaved: () {
                  final now = DateTime.now();
                  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  CentralInboxService.markActionedForEntity('system', 'checkin_$dateStr');
                  _loadDashboardData();
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.sparkles, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.checkinReminderTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.checkinReminderDesc,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_left, color: colors.textSecondary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionSuggestionCard() {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    if (now.hour < 22) return const SizedBox.shrink();
    if (_hasReflection) return const SizedBox.shrink();
    if (_reflectionDismissed) return const SizedBox.shrink();

    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RitmoTheme.glassCardLight(
        color: const Color(0xff6366F1).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xff6366F1).withValues(alpha: 0.2),
          width: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff6366F1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.moon_stars_fill, color: Color(0xff818CF8), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reflectionReminderTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.reflectionReminderDesc,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      final db = await DatabaseHelper.instance.database;
                      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                      await db.insert(
                        'app_settings',
                        {
                          'key': 'dismissed_reflection_date',
                          'value': todayStr,
                          'updatedAt': DateTime.now().millisecondsSinceEpoch,
                        },
                        conflictAlgorithm: ConflictAlgorithm.replace,
                      );
                      await HapticFeedback.lightImpact();
                      final now = DateTime.now();
                      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      await CentralInboxService.markActionedForEntity('system', 'reflection_$dateStr');
                      setState(() {
                        _reflectionDismissed = true;
                      });
                      await _loadDashboardData();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      l10n.laterOrDismiss,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => DailyReflectionSheet(
                          onSaved: () {
                            final now = DateTime.now();
                            final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                            CentralInboxService.markActionedForEntity('system', 'reflection_$dateStr');
                            _loadDashboardData();
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.yesRecord,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMidDayReplanBanner() {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RitmoTheme.glassCardLight(
        color: colors.goldAccent.withValues(alpha: 0.08),
        border: Border.all(
          color: colors.goldAccent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.goldAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history_toggle_off_rounded, color: colors.goldAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'برنامه امروز شما عقب افتاده است ⏳',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'آیا مایلید برنامه باقی‌مانده روز شما مجدداً چیده شود؟',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await MidDayReplanService.instance.recordUserRejected();
                      setState(() {
                        _showReplanBanner = false;
                      });
                      if (mounted) {
                        RitmoToast.show(context, 'پیشنهاد رد شد.');
                      }
                    },
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.goldAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final draft = await MidDayReplanService.instance.computeReplan();
                      if (draft != null) {
                        if (mounted) {
                          AiDayPlannerPreviewSheet.show(
                            context,
                            initialDraft: draft,
                            onSaved: _loadDashboardData,
                          );
                        }
                      } else {
                        if (mounted) {
                          RitmoToast.show(context, 'کار عقب‌افتاده‌ای یافت نشد ⚡');
                        }
                      }
                    },
                    child: const Text(
                      'بازچینی برنامه',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsSection() {
    final l10n = AppLocalizations.of(context)!;
    final alerts = _engineOutput?.criticalAlerts ?? [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RitmoTheme.glassCardLight(
        color: isDarkMode
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.08),
        border: Border.all(
          color: isDarkMode
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.2),
          width: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.criticalSystemAlerts,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.red[300] : Colors.red[800],
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...alerts.map((alert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                    Expanded(
                      child: Text(
                        alert,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pushCriticalAlerts() async {
    final alerts = _engineOutput?.criticalAlerts ?? [];
    for (final alert in alerts) {
      final dedupeKey = 'alert_${alert.hashCode}';
      await CentralInboxService.push(
        category: InboxCategory.INSIGHT,
        sourceSystem: 'intelligence_engine',
        entityId: dedupeKey,
        eventType: 'critical_alert',
        title: 'هشدار سیستم',
        body: alert,
        priority: 2,
        linkModule: 'insights',
        linkAction: 'view_alerts',
      );
    }
  }

  Future<void> _pushCheckinsAndReflections() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (_needCheckin) {
      final dedupeKey = 'checkin_$dateStr';
      await CentralInboxService.push(
        category: InboxCategory.REMINDER,
        sourceSystem: 'system',
        entityId: dedupeKey,
        eventType: 'morning_checkin',
        title: 'ارزیابی صبحگاهی 🌅',
        body: 'روز خود را با ثبت ارزیابی صبحگاهی آغاز کنید تا وضعیت انرژی شما محاسبه شود.',
        priority: 1,
        linkModule: 'home',
        linkAction: 'open_checkin',
        dateBucket: dateStr,
      );
    }
    
    final reflectionAvailable = now.hour >= 22 && !_hasReflection && !_reflectionDismissed;
    if (reflectionAvailable) {
      final dedupeKey = 'reflection_$dateStr';
      await CentralInboxService.push(
        category: InboxCategory.REMINDER,
        sourceSystem: 'system',
        entityId: dedupeKey,
        eventType: 'daily_reflection',
        title: 'بازتاب روزانه 🌌',
        body: 'زمان مناسبی برای ثبت بازخورد روز و تحلیل فعالیت‌هاست.',
        priority: 1,
        linkModule: 'home',
        linkAction: 'open_reflection',
        dateBucket: dateStr,
      );
    }
  }

  Widget _buildRecentInboxAlertsSection(RitmoColors colors) {
    if (_recentInboxItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخرین یادآوری‌ها و اعلان‌ها 🔔',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InboxScreen()),
                  ).then((_) => _loadDashboardData());
                },
                child: const Text(
                  'مشاهده همه',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff5B8AF5),
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentInboxItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _recentInboxItems[index];
              var itemColor = const Color(0xff5B8AF5);
              if (item.priority == InboxPriority.critical) {
                itemColor = Colors.redAccent;
              } else if (item.category == InboxCategory.MILESTONE) {
                itemColor = const Color(0xffFBBF24);
              } else if (item.category == InboxCategory.INSIGHT) {
                itemColor = const Color(0xff34D399);
              }

              return RitmoTheme.glassCardLight(
                color: colors.card.withValues(alpha: 0.5),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                child: InkWell(
                  onTap: () {
                    InboxNavigator.open(context, item).then((_) => _loadDashboardData());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, color: itemColor, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.body != null && item.body!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.body!,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_left, color: colors.textSecondary, size: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTERS & INDICATORS
// ---------------------------------------------------------------------------



