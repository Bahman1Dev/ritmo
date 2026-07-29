import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ritmo/core/ai/ai_briefing_service.dart';
import 'package:ritmo/core/ai/ai_context_builder.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/ad_service.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
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
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/profile/presentation/profile_screen.dart';
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
import 'package:ritmo/features/today/presentation/widgets/dashboard/ai_suggestions_carousel.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/assistant_card.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/context_strip.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_module_summary.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/module_summary_grid.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/pulse_hero_card.dart';
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

int _safeDur(int? v, int fallback) => (v != null && v > 0) ? v : fallback;

class _NowDashboardScreenState extends State<NowDashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFirstLoad = true;
  AiBriefing? _briefing;
  bool _isBriefingLoading = false;
  int _rhythmScore = 82;
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
  String _currentEnergyTimeAgo = 'بر اساس پیش‌فرض';
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
      _isLoading = false; // first paint is ready
      _rhythmScore = controller.rhythmScore;
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

      _pushCriticalAlerts();
      _pushCheckinsAndReflections();
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
        if (!PremiumService.instance.can(PremiumFeature.coursesModule)) {
          PremiumUpgradeSheet.show(context);
          return;
        }
        screen = const CoursesScreen();
      case 'konkur':
        if (!PremiumService.instance.can(PremiumFeature.konkurModule)) {
          PremiumUpgradeSheet.show(context);
          return;
        }
        screen = const KonkurScreen();
    }
    if (screen == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!))
        .then((_) => _loadDashboardData());
  }

  Future<void> _openSupplementarySports() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings', where: "key = 'ss_onboarding_completed'", limit: 1);
      final hasCompletedOnboarding = settings.isNotEmpty && settings.first['value'] == 'true';

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

  Future<Map<String, String?>> _loadEnergyAnalyticsData() async {
    return {
      'peak': _peakPerformanceWindow,
      'fatigued': _mostFatiguedWindow,
      'productive': _mostProductiveWeekday,
    };
  }

  Widget _buildSelectableLevelCard({
    required String label,
    required String value,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required RitmoColors colors,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : colors.textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : colors.border.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFactorChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required RitmoColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.12) : colors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : colors.border.withValues(alpha: 0.5),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsItemRow({
    required IconData icon,
    required String title,
    required String value,
    required RitmoColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(Routine routine, String resultType, [int? customDuration]) async {
    final todayStr = RitmoDate.now().value;

    if (resultType == 'SKIPPED') {
      await RitmoExecutionKernel.instance.execute(
        SkipOccurrenceCommand(routineId: routine.id, dateStr: todayStr),
      );
    } else {
      final fullMinutes = routine.currentTargetMinutes > 0
          ? routine.currentTargetMinutes
          : _safeDur(routine.targetDurationMinutes, 30);
      final lightMinutes = _safeDur(routine.lightDurationMinutes, 20);
      final minimalMinutes = _safeDur(routine.minimalDurationMinutes, 10);
      final duration = customDuration ?? (resultType == 'FULL'
          ? fullMinutes
          : (resultType == 'LIGHT' ? lightMinutes : minimalMinutes));

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: (resultType == 'CANNOT_NOW' || resultType == 'SNOOZED' || resultType == 'SKIPPED')
              ? colors.warning
              : colors.success,
        ),
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
    final totalTasks = tasksList.length;
    final completedTasks = tasksList.where((t) => t['isCompleted'] == true).length;
    Map<String, dynamic>? nextTaskMap;
    for (final t in tasksList) {
      if (t['isCompleted'] == false) {
        nextTaskMap = t;
        break;
      }
    }
    nextTaskMap ??= <String, dynamic>{};
    final nextTaskTitle = nextTaskMap.isNotEmpty ? (nextTaskMap['title'] as String?) : null;
    final nextTaskTime = nextTaskMap.isNotEmpty ? (nextTaskMap['time'] as String?) : null;
    final nextTaskRoutine = nextTaskMap.isNotEmpty ? (nextTaskMap['routine'] as Routine?) : null;

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
                const SizedBox(height: RitmoSpacing.section),

                // 2. نوار زمینه‌ی یکپارچه: وضعیت + سیستم‌های من
                _enter(
                  1,
                  ContextStrip(
                    dailyBehavior: _dailyBehavior,
                    defaultEnergyLevel:
                        _settingsMap['default_energy_level'] ?? 'MEDIUM',
                    activeZoneName: _activeZoneName,
                    onReshuffleApplied: _loadDashboardData,
                    isWorshipActive:
                        _settingsMap['module_religion_enabled'] == 'true',
                    isMedicineActive:
                        _settingsMap['module_medicine_enabled'] == 'true',
                    isCoursesActive:
                        _settingsMap['module_courses_enabled'] == 'true',
                    isGoalsActive:
                        _settingsMap['module_goals_enabled'] == 'true',
                    onWorshipTap: () => _openModuleScreen('worship'),
                    onHealthTap: () => _openModuleScreen('medicine'),
                    onProjectsTap: () => _openModuleScreen('goals'),
                    onEducationTap: () => _openModuleScreen('courses'),
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 3. هشدارها و کارت‌های شرطی
                _enter(2, _buildCriticalAlertsSection()),
                _enter(2, _buildRecentInboxAlertsSection(colors)),
                _enter(2, _buildCheckinReminderCard()),
                _enter(2, _buildReflectionSuggestionCard()),

                // 4. کارت هیرو: نبض زندگی + خلاصه‌ی امروز
                _enter(
                  3,
                  PulseHeroCard(
                    rhythmScore: _rhythmScore,
                    totalTasks: totalTasks,
                    completedTasks: completedTasks,
                    nextTaskTitle: nextTaskTitle,
                    nextTaskTime: nextTaskTime,
                    onStartNext: () {
                      if (nextTaskRoutine != null) {
                        _showNiyyahSheet(nextTaskRoutine);
                      }
                    },
                    onNavigateToTab: widget.onNavigateToTab,
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 5. کارت زون و انرژی
                _enter(
                  4,
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

                if (_showReplanBanner) ...[
                  _enter(
                    5,
                    _buildMidDayReplanBanner(),
                  ),
                  const SizedBox(height: RitmoSpacing.section),
                ],

                // 6. کارت دستیار یکپارچه: پیشنهاد هوشمند + بریفینگ AI
                _enter(
                  5,
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

                _enter(
                  6,
                  AiSuggestionsCarousel(
                    onSuggestionApplied: _loadDashboardData,
                  ),
                ),
                const SizedBox(height: RitmoSpacing.section),

                // 7. گرید خلاصه‌ی ماژول‌های فعال
                _enter(
                  6,
                  ModuleSummaryGrid(
                    summaries: _moduleSummaries,
                    onModuleTap: _openModuleScreen,
                  ),
                ),
                if (_moduleSummaries.isNotEmpty)
                  const SizedBox(height: RitmoSpacing.section),

                // 8. کارهای امروز
                _enter(
                  7,
                  TodaysTasksSection(
                    tasks: tasksList,
                    onOpenDetails: _showDetailsSheet,
                    onStartTask: _showNiyyahSheet,
                    onReshuffleApplied: _loadDashboardData,
                    onViewAll: () => widget.onNavigateToTab?.call(4),
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

  void _showMoreSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onLogout: widget.onLogout,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTimerOverlay(
          routine: routine,
          completionMode: mode,
          onFinished: () {
            Navigator.pop(context);
            _loadDashboardData();
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

  void _showEnergyManagementSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.colors;
        final viewInsets = MediaQuery.of(context).viewInsets;
        var selectedLevel = _settingsMap['default_energy_level'] ?? 'MEDIUM';
        final noteController = TextEditingController();
        String? aiRecommendation;
        var loadingAi = false;
        
        // Checklist states
        var poorSleep = false;
        var highStress = false;
        var physicalFatigue = false;
        var lackOfFocus = false;
        var aiConsent = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.72,
                  minChildSize: 0.5,
                  expand: false,
                  snap: true,
                  snapSizes: const [0.72, 1.0],
                  builder: (context, scrollController) {
                    return RitmoTheme.glassCardLight(
                      borderRadius: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          thickness: 4.5,
                          radius: const Radius.circular(8),
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                            children: [
                            // Header drag bar
                            Center(
                              child: Container(
                                width: 36,
                                height: 4.5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: colors.textSecondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),

                            // Title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(CupertinoIcons.bolt_fill, size: 20, color: colors.warning),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'مدیریت و تحلیل انرژی ریتمو',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Dynamic Ring Indicator
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CustomPaint(
                                      painter: _EnergyRingPainter(
                                        percentage: _currentEnergyPercent,
                                        colors: _currentEnergyLabel == 'بالا'
                                            ? [colors.success, colors.primary]
                                            : (_currentEnergyLabel == 'پایین'
                                                ? [colors.medicalRed, colors.warning]
                                                : [colors.warning, colors.success]),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_currentEnergyPercent.toInt()}٪',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: colors.textPrimary,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'درصد پویای انرژی فعلی شما: $_currentEnergyLabel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  Text(
                                    _currentEnergyTimeAgo,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Calculation Breakdown (Explainability)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.textPrimary.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colors.border.withValues(alpha: 0.3), width: 0.8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'چرا این عدد؟ (فرمول محاسبه پویای انرژی)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_currentEnergyExplanation.isEmpty)
                                    Text(
                                      'در حال محاسبه...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    )
                                  else
                                    ..._currentEnergyExplanation.map((exp) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.circle_fill, size: 4, color: colors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              exp,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colors.textSecondary,
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
                            const SizedBox(height: 20),

                            // Energy selection cards
                            Text(
                              'تنظیم سطح انرژی پایه ثبت دستی:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildSelectableLevelCard(
                                  label: 'پایین 💤',
                                  value: 'LOW',
                                  isSelected: selectedLevel == 'LOW',
                                  activeColor: colors.medicalRed,
                                  onTap: () {
                                    setModalState(() {
                                      selectedLevel = 'LOW';
                                    });
                                  },
                                  colors: colors,
                                ),
                                const SizedBox(width: 8),
                                _buildSelectableLevelCard(
                                  label: 'متوسط ⚡',
                                  value: 'MEDIUM',
                                  isSelected: selectedLevel == 'MEDIUM',
                                  activeColor: colors.warning,
                                  onTap: () {
                                    setModalState(() {
                                      selectedLevel = 'MEDIUM';
                                    });
                                  },
                                  colors: colors,
                                ),
                                const SizedBox(width: 8),
                                _buildSelectableLevelCard(
                                  label: 'بالا 🔥',
                                  value: 'HIGH',
                                  isSelected: selectedLevel == 'HIGH',
                                  activeColor: colors.success,
                                  onTap: () {
                                    setModalState(() {
                                      selectedLevel = 'HIGH';
                                    });
                                  },
                                  colors: colors,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Selectable Factors
                            Text(
                              'فاکتورهای مؤثر بر خستگی یا افت انرژی امروز:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFactorChip(
                                  label: 'خواب ضعیف 🛌',
                                  selected: poorSleep,
                                  onTap: () {
                                    setModalState(() {
                                      poorSleep = !poorSleep;
                                    });
                                  },
                                  colors: colors,
                                ),
                                _buildFactorChip(
                                  label: 'استرس بالا 🧠',
                                  selected: highStress,
                                  onTap: () {
                                    setModalState(() {
                                      highStress = !highStress;
                                    });
                                  },
                                  colors: colors,
                                ),
                                _buildFactorChip(
                                  label: 'خستگی جسمی 🏋️',
                                  selected: physicalFatigue,
                                  onTap: () {
                                    setModalState(() {
                                      physicalFatigue = !physicalFatigue;
                                    });
                                  },
                                  colors: colors,
                                ),
                                _buildFactorChip(
                                  label: 'عدم تمرکز ذهنی 🎯',
                                  selected: lackOfFocus,
                                  onTap: () {
                                    setModalState(() {
                                      lackOfFocus = !lackOfFocus;
                                    });
                                  },
                                  colors: colors,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Note Field
                            CupertinoTextField(
                              controller: noteController,
                              placeholder: 'توضیحات کوتاه یا خلق‌و‌خو (اختیاری)',
                              placeholderStyle: const TextStyle(color: Colors.grey, fontSize: 11.5, fontFamily: 'Vazirmatn'),
                              style: TextStyle(color: colors.textPrimary, fontSize: 12.5, fontFamily: 'Vazirmatn'),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.textPrimary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Save button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                final db = await DatabaseHelper.instance.database;
                                final now = DateTime.now().millisecondsSinceEpoch;

                                final selectedFactors = <String>[];
                                if (poorSleep) selectedFactors.add('خواب ضعیف');
                                if (highStress) selectedFactors.add('استرس بالا');
                                if (physicalFatigue) selectedFactors.add('خستگی جسمی');
                                if (lackOfFocus) selectedFactors.add('عدم تمرکز ذهنی');

                                final noteText = noteController.text.trim();
                                final factorsString = selectedFactors.isNotEmpty
                                    ? '[عوامل: ${selectedFactors.join("، ")}]'
                                    : '';
                                final finalNote = noteText.isNotEmpty
                                    ? '$noteText $factorsString'
                                    : (factorsString.isNotEmpty ? factorsString : '');

                                await db.insert('energy_logs', {
                                  'id': 'energy_$now',
                                  'energyLevel': selectedLevel,
                                  'source': 'MANUAL',
                                  'note': finalNote.isEmpty ? null : finalNote,
                                  'loggedAt': now,
                                });

                                await db.rawUpdate(
                                  "UPDATE app_settings SET value = ?, updatedAt = ? WHERE key = 'default_energy_level'",
                                  [selectedLevel, now],
                                );

                                await _loadDashboardData();
                                _showToast('سطح انرژی با موفقیت به روز شد.');
                              },
                              child: const Text(
                                'ثبت و ذخیره‌سازی وضعیت',
                                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // AI Recommendation Section
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.15),
                                ),
                                color: colors.primary.withValues(alpha: 0.02),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.sparkles, size: 14, color: colors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'تحلیل هوشمند دستیار ریتمو (AI)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Data disclosure
                                  Text(
                                    'داده‌های ارسالی به هوش مصنوعی جهت تحلیل:',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• درصد پویای محاسبه شده فعلی: ${_currentEnergyPercent.toInt()}٪\n'
                                    '• عوامل موقت گزارش شده: ${[
                                      if (poorSleep) 'خواب ضعیف',
                                      if (highStress) 'استرس بالا',
                                      if (physicalFatigue) 'خستگی جسمی',
                                      if (lackOfFocus) 'عدم تمرکز ذهنی'
                                    ].join("، ").isEmpty ? "هیچکدام" : [
                                      if (poorSleep) 'خواب ضعیف',
                                      if (highStress) 'استرس بالا',
                                      if (physicalFatigue) 'خستگی جسمی',
                                      if (lackOfFocus) 'عدم تمرکز ذهنی'
                                    ].join("، ")}\n'
                                    '• فاز ساعت زیستی بدن در ساعت فعلی روز\n'
                                    '• تاریخچه خواب اخیر و وضعیت روتین‌های تکمیل‌شده',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textSecondary.withValues(alpha: 0.8),
                                      fontFamily: 'Vazirmatn',
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Consent Checkbox
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        aiConsent = !aiConsent;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          aiConsent ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                                          size: 16,
                                          color: aiConsent ? colors.success : colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'با ارسال امن داده‌های فوق جهت تحلیل موافقم.',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  if (aiRecommendation == null && !loadingAi)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: aiConsent ? colors.primary.withValues(alpha: 0.08) : colors.textSecondary.withValues(alpha: 0.04),
                                        foregroundColor: aiConsent ? colors.primary : colors.textSecondary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: !aiConsent ? null : () async {
                                        setModalState(() {
                                          loadingAi = true;
                                        });
                                        try {
                                          final selectedStr = [
                                            if (poorSleep) 'خواب ضعیف',
                                            if (highStress) 'استرس بالا',
                                            if (physicalFatigue) 'خستگی جسمی',
                                            if (lackOfFocus) 'عدم تمرکز ذهنی'
                                          ].join('، ');

                                          final result = await AIGateway.instance.sendQuery(
                                            query: 'یک پیشنهاد کوتاه، انگیزاننده و کاربردی به زبان فارسی برای بهبود انرژی من بر اساس روتین‌ها و وضعیت خواب اخیرم بده. '
                                                'درصد انرژی فعلی من ${_currentEnergyPercent.toInt()}٪ است و عوامل تاثیرگذار گزارش شده عبارتند از: $selectedStr. '
                                                'توجه: فقط درباره روتین‌ها، کار، ورزش و سبک زندگی راهنمایی بده.',
                                            consent: const ConsentProfile(),
                                          );
                                          setModalState(() {
                                            aiRecommendation = (result['response'] as String?) ?? 'پیشنهادی یافت نشد.';
                                            loadingAi = false;
                                          });
                                        } catch (e) {
                                          setModalState(() {
                                            aiRecommendation = 'خطا در اتصال به شبکه یا دریافت پاسخ.';
                                            loadingAi = false;
                                          });
                                        }
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.sparkles, size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'تحلیل و دریافت پیشنهاد',
                                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (loadingAi)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 1.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'در حال تحلیل داده‌های خواب و روتین‌ها توسط هوش مصنوعی...',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: colors.textSecondary,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          aiRecommendation!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textPrimary,
                                            fontFamily: 'Vazirmatn',
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton(
                                          onPressed: () {
                                            setModalState(() {
                                              aiRecommendation = null;
                                            });
                                          },
                                          child: Text(
                                            'تحلیل مجدد 🔄',
                                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Local Analytics Section
                            Text(
                              'گزارش آماری موتور تحلیل انرژی (محلی):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<Map<String, String?>>(
                              future: _loadEnergyAnalyticsData(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                    ),
                                  );
                                }

                                final peak = snapshot.data?['peak'] ?? 'داده ناکافی';
                                final fatigued = snapshot.data?['fatigued'] ?? 'داده ناکافی';
                                final productive = snapshot.data?['productive'] ?? 'داده ناکافی';

                                return Column(
                                  children: [
                                    _buildAnalyticsItemRow(
                                      icon: CupertinoIcons.chart_bar_alt_fill,
                                      title: 'ساعت طلایی بازدهی:',
                                      value: peak,
                                      colors: colors,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildAnalyticsItemRow(
                                      icon: CupertinoIcons.battery_25,
                                      title: 'بازه بیشترین خستگی:',
                                      value: fatigued,
                                      colors: colors,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildAnalyticsItemRow(
                                      icon: CupertinoIcons.calendar_today,
                                      title: 'پربازده‌ترین روز:',
                                      value: productive,
                                      colors: colors,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

  void _showToast(String msg) {
    if (!mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: colors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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

class _EnergyRingPainter extends CustomPainter {

  _EnergyRingPainter({required this.percentage, required this.colors});
  final double percentage;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final paintBg = Paint()
      ..color = colors.first.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);

    // Create gradient
    final gradient = SweepGradient(
      colors: colors,
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );

    // Glow effect
    final paintGlow = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // Foreground track
    final paintFg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);

    // Draw glow first
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintGlow);
    // Draw crisp path on top
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintFg);
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.colors != colors;
  }
}

