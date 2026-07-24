import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/mood_engine.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/analytics/sleep_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/core/ux/ritmo_empty_state.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:ritmo/features/energy/presentation/widgets/energy_hero.dart';
import 'package:ritmo/features/energy/presentation/widgets/energy_patterns_section.dart';
import 'package:ritmo/features/energy/presentation/widgets/energy_today_section.dart';
import 'package:ritmo/features/energy/presentation/widgets/energy_trends_section.dart';
import 'package:ritmo/features/energy/presentation/widgets/quick_log_sheet.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/reflection/presentation/widgets/journal_timeline_section.dart';
import 'package:ritmo/features/reflection/presentation/widgets/reflection_hero.dart';
import 'package:ritmo/features/reflection/presentation/widgets/reflection_trends_section.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_hero.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_last_night_section.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_log_sheet.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_patterns_section.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_target_sheet.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_trends_section.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart';
import 'package:sqflite/sqflite.dart';

enum WellbeingSection { energy, sleep, reflection }

class WellbeingScreen extends StatefulWidget {

  const WellbeingScreen({
    super.key,
    this.initialSection = WellbeingSection.energy,
  });
  final WellbeingSection initialSection;

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

// Maps section enum to tab index
extension _WellbeingSectionExt on WellbeingSection {
  int get tabIndex {
    switch (this) {
      case WellbeingSection.energy: return 0;
      case WellbeingSection.sleep: return 1;
      case WellbeingSection.reflection: return 2;
    }
  }
}

class _WellbeingScreenState extends State<WellbeingScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, String> _settings = {};

  // Gating flags
  bool _energyEnabled = false;
  bool _sleepEnabled = false;

  // Tab navigation
  late TabController _tabController;
  late PageController _pageController;

  // Energy & Mood State
  List<EnergyLog> _energyLogs = [];
  List<MoodLog> _moodLogs = [];
  bool _isUserMenstruating = false;
  bool _isEnergyTuned = false;
  EnergyAnalyticsOutput? _energyOutput;
  MoodEngineOutput? _moodOutput;

  // Sleep State
  SleepTarget _sleepTarget = SleepTarget.defaultTarget();
  bool _isWinddownEnabled = false;
  int _winddownMinutes = 30;
  bool _sleepSetupDone = false;
  List<SleepLog> _sleepLogs = [];
  SleepEngineOutput? _sleepOutput;

  // Reflection State
  List<ReflectionEntry> _reflections = [];
  List<CheckinEntry> _checkins = [];
  List<JournalDay> _timelineDays = [];
  bool _todayCheckinDone = false;
  bool _todayReflectionDone = false;
  ReflectionEngineOutput? _reflectionOutput;
  bool _showAllReflectionLogs = false;

  // Trends switch (0: energy, 1: sleep, 2: reflection)
  int _activeTrendsTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(
        initialPage: widget.initialSection.tabIndex);
    _tabController.index = widget.initialSection.tabIndex;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
    RitmoEvents.routineChanges.addListener(_onRoutineChanges);
    _loadAllData();
  }

  void _onRoutineChanges() {
    if (mounted) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    RitmoEvents.routineChanges.removeListener(_onRoutineChanges);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch settings
      final settingsList = await db.query('app_settings');
      _settings = {for (final s in settingsList) s['key']! as String: s['value']! as String};

      _energyEnabled = _settings['module_energy_enabled'] == 'true';
      _sleepEnabled = _settings['module_sleep_enabled'] == 'true';

      // 2. Fetch energy & mood data
      final rawEnergy = await db.query('energy_logs', orderBy: 'loggedAt DESC');
      _energyLogs = rawEnergy.map(EnergyLog.fromMap).toList();

      final rawMood = await db.query('mood_logs', orderBy: 'loggedAt DESC');
      _moodLogs = rawMood.map(MoodLog.fromMap).toList();

      _isUserMenstruating = await CycleConsentBridge.isUserMenstruating();
      _isEnergyTuned = await CycleConsentBridge.isEnergyTuned();

      final dailyRhythm = await db.query('daily_rhythm', orderBy: 'date DESC');
      final routineCompletions = await db.query('routine_completions', orderBy: 'completionTime DESC');
      final sleepDiagList = await db.query('bedtime_diagnostics', orderBy: 'loggedAt DESC');

      if (_energyEnabled) {
        final energyEngine = EnergyAnalyticsEngine();
        _energyOutput = await energyEngine.calculate(EnergyAnalyticsEngineInput(
          energyLogs: rawEnergy,
          routineCompletions: routineCompletions,
          dailyRhythm: dailyRhythm,
          sleepDiagList: sleepDiagList,
          validityMinutes: int.tryParse(_settings['energy_validity_minutes'] ?? '180') ?? 180,
          defaultEnergyLevel: _settings['default_energy_level'] ?? 'MEDIUM',
          now: DateTime.now(),
        ));

        final moodEngine = MoodEngine();
        _moodOutput = await moodEngine.calculate(MoodEngineInput(
          moodLogs: _moodLogs,
          energyLogs: _energyLogs,
          today: DateTime.now(),
          isEnergyTuned: _isEnergyTuned,
          isUserMenstruating: _isUserMenstruating,
        ));
      }

      // 3. Fetch sleep target & data
      final bedtime = _settings['sleep_target_bedtime'] ?? '23:30';
      final wake = _settings['sleep_target_wake'] ?? '07:00';
      final duration = int.tryParse(_settings['sleep_target_duration_minutes'] ?? '450') ?? 450;
      _sleepTarget = SleepTarget(bedtime: bedtime, wake: wake, durationMinutes: duration);

      _isWinddownEnabled = _settings['sleep_winddown_reminder'] == 'true';
      _winddownMinutes = int.tryParse(_settings['sleep_winddown_minutes'] ?? '30') ?? 30;
      _sleepSetupDone = _settings['sleep_setup_done'] == 'true';

      final logsRes = await db.query('bedtime_diagnostics', orderBy: 'date DESC');
      _sleepLogs = logsRes.map(SleepLog.fromMap).toList();

      if (_sleepEnabled) {
        final sleepInput = SleepEngineInput(
          sleepLogs: _sleepLogs,
          target: _sleepTarget,
          energyLogs: rawEnergy,
          moodLogs: rawMood,
          today: DateTime.now(),
        );
        _sleepOutput = await SleepEngine().calculate(sleepInput);
      }

      // 4. Fetch reflection data
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      final reflectionMaps = await db.query(
        'daily_reflections',
        orderBy: 'date DESC',
        limit: 30,
      );
      _reflections = reflectionMaps.map(ReflectionEntry.fromMap).toList();
      _todayReflectionDone = _reflections.any((r) => r.date == todayStr);

      final checkinMaps = await db.query(
        'daily_checkins',
        orderBy: 'date DESC',
        limit: 30,
      );
      _checkins = checkinMaps.map(CheckinEntry.fromMap).toList();
      _todayCheckinDone = _checkins.any((c) => c.date == todayStr);

      _timelineDays = _buildTimelineDays(_reflections, _checkins);

      final allReflectionMaps = await db.query('daily_reflections', orderBy: 'date DESC');
      final allCheckinMaps = await db.query('daily_checkins', orderBy: 'date DESC');
      
      final reflectionInput = ReflectionEngineInput(
        dailyReflections: allReflectionMaps,
        dailyCheckins: allCheckinMaps,
        energyLogs: rawEnergy,
        moodLogs: rawMood,
        today: DateTime.now(),
      );

      _reflectionOutput = await RitmoEngineBus.instance.execute<ReflectionEngineInput, ReflectionEngineOutput>(
        ReflectionEngine,
        reflectionInput,
      );

    } catch (e, stack) {
      debugPrint('Error loading wellbeing unified data: $e\n$stack');
    }

    _reflectionOutput ??= ReflectionEngineOutput(
      currentStreak: 0,
      longestStreak: 0,
      entryCount: 0,
      completionRate: 0,
      avgMoodScore: 0,
      moodTrend: const [],
      themeFrequency: const {},
      correlationInsight: 'اطلاعات خودارزیابی موقتاً در دسترس نیست.',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<JournalDay> _buildTimelineDays(
    List<ReflectionEntry> reflections,
    List<CheckinEntry> checkins,
  ) {
    final allDates = <String>{};
    for (final r in reflections) {
      allDates.add(r.date);
    }
    for (final c in checkins) {
      allDates.add(c.date);
    }

    final sortedDates = allDates.toList()..sort((a, b) => b.compareTo(a));
    return sortedDates.map((dateStr) {
      final checkin = checkins.firstWhere(
        (c) => c.date == dateStr,
        orElse: () => CheckinEntry(date: dateStr, mood: 'NEUTRAL'),
      );
      final reflection = reflections.firstWhere(
        (r) => r.date == dateStr,
        orElse: () => ReflectionEntry(date: dateStr, moodScore: 3, createdAt: 0),
      );
      return JournalDay(
        dateIso: dateStr,
        checkin: checkin.mood == 'NEUTRAL' && checkin.note == null ? null : checkin,
        reflection: reflection.createdAt == 0 ? null : reflection,
      );
    }).toList();
  }

  Future<void> _activateModule(String settingKey) async {
    try {
      await ModuleManagementService.instance.setModuleEnabled(settingKey, true);
      await _loadAllData();
    } catch (e) {
      debugPrint('Error activating module $settingKey: $e');
    }
  }

  void _switchToSection(WellbeingSection section) {
    final idx = section.tabIndex;
    _tabController.animateTo(idx);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }


  void _showQuickLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickLogSheet(
        onSaved: _loadAllData,
      ),
    );
  }

  void _showSleepLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepLogSheet(
        target: _sleepTarget,
        onSaved: _loadAllData,
      ),
    );
  }

  void _showReflectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyReflectionSheet(
        onSaved: _loadAllData,
      ),
    );
  }

  void _showSleepTargetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepTargetSheet(
        currentTarget: _sleepTarget,
        isWinddownEnabled: _isWinddownEnabled,
        winddownMinutes: _winddownMinutes,
        onSaved: _loadAllData,
      ),
    );
  }

  void _showAiAssistantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiWellbeingAssistantSheet(
        energyEnabled: _energyEnabled,
        sleepEnabled: _sleepEnabled,
        currentEnergy: _energyOutput?.currentDynamicEnergy,
        explanations: _energyOutput?.currentDynamicEnergyExplanations,
        dominantMood: _moodOutput?.dominantMood,
        correlationInsight: _moodOutput?.correlationInsight,
        isUserMenstruating: _isUserMenstruating,
        isEnergyTuned: _isEnergyTuned,
        sleepTarget: _sleepTarget,
        sleepLogs: _sleepLogs,
        todayCheckinDone: _todayCheckinDone,
        todayReflectionDone: _todayReflectionDone,
        onSaved: _loadAllData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.buildBackgroundContainer(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: RitmoIcons.back(context, color: colors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'حال و تعادل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              centerTitle: true,
            ),
            body: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  RitmoSkeletonCard(height: 160),
                  SizedBox(height: 16),
                  RitmoSkeletonCard(height: 52),
                  SizedBox(height: 24),
                  RitmoSkeletonCard(height: 220),
                  SizedBox(height: 24),
                  RitmoSkeletonCard(height: 220),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final mainContent = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: RitmoIcons.back(context, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'حال و تعادل',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.border.withValues(alpha: 0.15)),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.sparkles, color: Color(0xff8B5CF6), size: 18),
                      onPressed: _showAiAssistantSheet,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Fixed Header (non-scrollable) ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  // 1. Balance Pulse Hero Card (with Wellbeing Index)
                  _buildBalancePulseHero(colors),
                  const SizedBox(height: 12),

                  // 2. Smart Insights Card
                  _buildInsightsCard(colors),
                  const SizedBox(height: 12),

                  // 3. Quick Action Row
                  _buildQuickActionRow(colors),
                  const SizedBox(height: 12),

                  // 4. Glassmorphic Tab Bar
                  _buildGlassTabBar(colors),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ─── Scrollable Tab Content ───────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  if (!_tabController.indexIsChanging) {
                    _tabController.animateTo(idx);
                  }
                },
                children: [
                  // Tab 0: Energy
                  RefreshIndicator(
                    color: const Color(0xff8B5CF6),
                    onRefresh: _loadAllData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      child: _buildEnergySection(colors),
                    ),
                  ),
                  // Tab 1: Sleep
                  RefreshIndicator(
                    color: const Color(0xff8B5CF6),
                    onRefresh: _loadAllData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      child: _buildSleepSection(colors),
                    ),
                  ),
                  // Tab 2: Reflection
                  RefreshIndicator(
                    color: const Color(0xff8B5CF6),
                    onRefresh: _loadAllData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildReflectionSection(colors),
                          const SizedBox(height: 24),
                          _buildUnifiedTrendsSection(colors),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.buildBackgroundContainer(
        context: context,
        child: mainContent,
      ),
    );
  }

  // ─── Glassmorphic Tab Bar ─────────────────────────────────────────────────
  Widget _buildGlassTabBar(RitmoColors colors) {
    final tabLabels = [
      (label: 'انرژی', icon: CupertinoIcons.bolt_fill,       color: const Color(0xffEC4899)),
      (label: 'خواب',  icon: CupertinoIcons.moon_stars_fill,  color: const Color(0xff8B5CF6)),
      (label: 'بازتاب', icon: CupertinoIcons.doc_text_fill,   color: const Color(0xff06B6D4)),
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff8B5CF6), Color(0xffEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff8B5CF6).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: [
          for (int i = 0; i < tabLabels.length; i++)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final t = tabLabels[i];
                final isSelected = _tabController.index == i;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        t.icon,
                        size: 14,
                        color: isSelected ? Colors.white : t.color.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Smart Cross-Domain Insights Card ────────────────────────────────────
  Widget _buildInsightsCard(RitmoColors colors) {
    final insight = _buildInsightText();
    if (insight == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xff8B5CF6).withValues(alpha: 0.12),
                const Color(0xffEC4899).withValues(alpha: 0.07),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xff8B5CF6).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: Color(0xff8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildInsightText() {
    // Prioritise sleep → energy correlation
    if (_sleepEnabled && _energyEnabled) {
      final corr = _sleepOutput?.sleepEnergyCorrelation;
      if (corr != null && corr < -0.3) {
        return 'کم‌خوابی دیشب ممکن است باعث افت انرژی امروز شده باشد.';
      }
      if (corr != null && corr > 0.4) {
        return 'خواب باکیفیت دیشب با سطح انرژی بالای امروز همبسته است.';
      }
    }
    // Sleep debt warning
    if (_sleepEnabled && (_sleepOutput?.sleepDebtMinutes ?? 0) > 60) {
      final debtH = ((_sleepOutput!.sleepDebtMinutes) / 60).toStringAsFixed(1);
      return 'بدهی خواب هفته: $debtH ساعت. یک خواب جبرانی کوتاه توصیه می‌شود.';
    }
    // Mood correlation insight from reflection engine
    final refInsight = _reflectionOutput?.correlationInsight;
    if (refInsight != null && refInsight.isNotEmpty) return refInsight;
    // Mood engine insight
    final moodInsight = _moodOutput?.correlationInsight;
    if (moodInsight != null && moodInsight.isNotEmpty) return moodInsight;
    return null;
  }

  // ─── Computes a 0-100 Wellbeing Index ─────────────────────────────────────
  double _computeWellbeingIndex() {
    double score = 0;
    var weight = 0;

    if (_energyEnabled && _energyOutput != null) {
      score += _energyOutput!.currentDynamicEnergy;
      weight++;
    }
    if (_sleepEnabled && _sleepOutput?.lastNight != null) {
      final dur = _sleepOutput!.lastNight!.durationMinutes / 60.0;
      final targetH = _sleepTarget.durationMinutes / 60.0;
      final sleepScore = ((dur / targetH) * 100).clamp(0.0, 100.0);
      score += sleepScore;
      weight++;
    }
    if (_reflectionOutput != null) {
      final reflScore =
          ((_reflectionOutput!.avgMoodScore / 5.0) * 100).clamp(0.0, 100.0);
      score += reflScore;
      weight++;
    }
    return weight == 0 ? 0.0 : (score / weight).clamp(0.0, 100.0);
  }

  Color _wellbeingIndexColor(double idx) {
    if (idx >= 75) return const Color(0xff22D3EE);
    if (idx >= 50) return const Color(0xff8B5CF6);
    if (idx >= 30) return const Color(0xffF59E0B);
    return const Color(0xffF43F5E);
  }

  String _wellbeingIndexLabel(double idx) {
    if (idx >= 75) return 'عالی';
    if (idx >= 50) return 'خوب';
    if (idx >= 30) return 'متوسط';
    return 'نیاز به توجه';
  }

  Widget _buildBalancePulseHero(RitmoColors colors) {
    final index = _computeWellbeingIndex();
    final idxColor = _wellbeingIndexColor(index);
    final idxLabel = _wellbeingIndexLabel(index);

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Left: Wellbeing Index circle ──────────────────────────
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: index / 100,
                      strokeWidth: 5,
                      backgroundColor: colors.textPrimary.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(idxColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index.toInt()}',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: idxColor,
                        ),
                      ),
                      Text(
                        idxLabel,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 9,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // ── Right: three metric tiles ────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Energy
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchToSection(WellbeingSection.energy),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.bolt_fill,
                              color: _energyEnabled
                                  ? const Color(0xffEC4899)
                                  : colors.textSecondary.withValues(alpha: 0.4),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'انرژی',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 9,
                                  color: colors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _energyEnabled
                                  ? (_energyOutput != null
                                      ? '${_energyOutput!.currentDynamicEnergy.toInt()}%'
                                      : '—')
                                  : 'غیرفعال',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _energyEnabled
                                    ? const Color(0xffEC4899)
                                    : colors.textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: colors.border.withValues(alpha: 0.2)),
                  // Sleep
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchToSection(WellbeingSection.sleep),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.moon_stars_fill,
                              color: _sleepEnabled
                                  ? const Color(0xff8B5CF6)
                                  : colors.textSecondary.withValues(alpha: 0.4),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'خواب',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 9,
                                  color: colors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sleepEnabled
                                  ? (_sleepOutput?.lastNight != null
                                      ? '${(_sleepOutput!.lastNight!.durationMinutes / 60.0).toStringAsFixed(1)}h'
                                      : '—')
                                  : 'غیرفعال',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _sleepEnabled
                                    ? const Color(0xff8B5CF6)
                                    : colors.textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: colors.border.withValues(alpha: 0.2)),
                  // Reflection
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchToSection(WellbeingSection.reflection),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.doc_text_fill,
                              color: Color(0xff06B6D4),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'چک‌این',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 9,
                                  color: colors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _todayCheckinDone ? '✓ شد' : 'نشده',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _todayCheckinDone
                                    ? const Color(0xff06B6D4)
                                    : colors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
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



  Widget _buildQuickActionRow(RitmoColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            label: 'ثبت انرژی',
            icon: CupertinoIcons.bolt_fill,
            color: const Color(0xffEC4899),
            onTap: _showQuickLogSheet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            label: 'ثبت خواب',
            icon: CupertinoIcons.moon_stars_fill,
            color: const Color(0xff8B5CF6),
            onTap: _showSleepLogSheet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            label: 'چک‌این امروز',
            icon: CupertinoIcons.doc_text_fill,
            color: const Color(0xff06B6D4),
            onTap: _showReflectionSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        RitmoHaptics.tap();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineActivationCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String settingKey,
    required RitmoColors colors,
  }) {
    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _activateModule(settingKey),
              child: const Text(
                'فعال‌سازی',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySection(RitmoColors colors) {
    const sectionColor = Color(0xffEC4899);
    final todayStart = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .millisecondsSinceEpoch;
    final todayEnd = todayStart + 24 * 60 * 60 * 1000;
    final todayEnergy = _energyLogs.where((l) => l.loggedAt >= todayStart && l.loggedAt < todayEnd).toList();
    final todayMood = _moodLogs.where((l) => l.loggedAt >= todayStart && l.loggedAt < todayEnd).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.bolt_fill, color: sectionColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'انرژی و حال روحی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_energyEnabled)
          _buildInlineActivationCard(
            title: 'فعال‌سازی ماژول انرژی و حال روحی',
            description: 'تحلیل نوسانات انرژی و ثبت خلق‌وخوی روزانه',
            icon: CupertinoIcons.bolt_fill,
            iconColor: sectionColor,
            settingKey: 'module_energy_enabled',
            colors: colors,
          )
        else ...[
          if (_energyOutput != null) ...[
            EnergyHero(
              currentEnergy: _energyOutput!.currentDynamicEnergy,
              explanations: _energyOutput!.currentDynamicEnergyExplanations,
              latestMoodLog: _moodLogs.isNotEmpty ? _moodLogs.first : null,
              onQuickLogTap: _showQuickLogSheet,
            ),
            const SizedBox(height: 16),
            EnergyTodaySection(
              todayEnergyLogs: todayEnergy,
              todayMoodLogs: todayMood,
              currentEnergy: _energyOutput?.currentDynamicEnergy ?? 65.0,
              defaultEnergyLevel: _settings['default_energy_level'] ?? 'MEDIUM',
            ),
            const SizedBox(height: 16),
            EnergyPatternsSection(
              peakPerformanceWindow: _energyOutput?.peakPerformanceWindow,
              mostProductiveWeekday: _energyOutput?.mostProductiveWeekday,
              mostFatiguedWindow: _energyOutput?.mostFatiguedWindow,
            ),
          ] else
            RitmoEmptyState(
              icon: CupertinoIcons.bolt,
              title: 'بدون داده انرژی',
              description: 'امروز هنوز داده انرژی ثبت نکرده‌اید.',
              ctaLabel: 'ثبت وضعیت فعلی',
              onCta: _showQuickLogSheet,
            ),
        ],
      ],
    );
  }

  Widget _buildSleepSection(RitmoColors colors) {
    const sectionColor = Color(0xff8B5CF6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.moon_stars_fill, color: sectionColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'خواب و بیداری',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_sleepEnabled)
          _buildInlineActivationCard(
            title: 'فعال‌سازی ماژول خواب و بیداری',
            description: 'ثبت ساعات خواب، بیداری و کیفیت خواب دیشب',
            icon: CupertinoIcons.moon_stars_fill,
            iconColor: sectionColor,
            settingKey: 'module_sleep_enabled',
            colors: colors,
          )
        else ...[
          if (!_sleepSetupDone)
            RitmoTheme.glassCardLight(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.moon_stars, size: 36, color: sectionColor),
                    const SizedBox(height: 12),
                    Text(
                      'هدف خواب خود را تعیین کنید 🌙',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'برای فعال‌سازی کامل بخش خواب و یادآورها، لطفاً هدف خواب و بیداری خود را ثبت کنید.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sectionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showSleepTargetSheet,
                      child: const Text('تعیین هدف خواب', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            )
          else ...[
            SleepHero(
              lastNight: _sleepOutput?.lastNight,
              target: _sleepTarget,
              onRefresh: _loadAllData,
            ),
            const SizedBox(height: 16),
            SleepLastNightSection(
              lastNight: _sleepOutput?.lastNight,
              target: _sleepTarget,
              isWinddownEnabled: _isWinddownEnabled,
              onRefresh: _loadAllData,
            ),
            const SizedBox(height: 16),
            SleepPatternsSection(
              consistencyScore: _sleepOutput?.consistencyScore ?? 100,
              avgDurationMinutes: _sleepOutput?.avgDurationMinutes ?? 0.0,
              sleepDebtMinutes: _sleepOutput?.sleepDebtMinutes ?? 0,
              bestBedtimeWindow: _sleepOutput?.bestBedtimeWindow ?? 'نامشخص',
              totalLogsCount: _sleepLogs.length,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReflectionSection(RitmoColors colors) {
    const sectionColor = Color(0xff06B6D4);
    final displayedTimelineDays = _showAllReflectionLogs ? _timelineDays : _timelineDays.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.doc_text_fill, color: sectionColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'خودارزیابی و بازتاب روزانه',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reflectionOutput != null) ...[
          ReflectionHero(
            stats: ReflectionStats(
              currentStreak: _reflectionOutput?.currentStreak ?? 0,
              longestStreak: _reflectionOutput?.longestStreak ?? 0,
              entryCount: _reflectionOutput?.entryCount ?? 0,
              completionRate: _reflectionOutput?.completionRate ?? 0.0,
              avgMoodScore: _reflectionOutput?.avgMoodScore ?? 0.0,
            ),
            todayCheckinDone: _todayCheckinDone,
            todayReflectionDone: _todayReflectionDone,
            onRefresh: _loadAllData,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 تاریخچه و دفتر یادداشت',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (_timelineDays.length > 3)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllReflectionLogs = !_showAllReflectionLogs;
                    });
                  },
                  child: Text(
                    _showAllReflectionLogs ? 'نمایش کمتر' : 'نمایش همه (${_timelineDays.length})',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: Color(0xff06B6D4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_timelineDays.isEmpty)
            RitmoEmptyState(
              icon: CupertinoIcons.doc_text,
              title: 'دفتر بازتاب خالی است',
              description: 'اولین بازتاب یا یادداشت خود را برای امروز ثبت کنید.',
              ctaLabel: 'شروع بازتاب امروز',
              onCta: _showReflectionSheet,
            )
          else
            JournalTimelineSection(
              days: displayedTimelineDays,
              onRefresh: _loadAllData,
            ),
        ] else
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildUnifiedTrendsSection(RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.chart_bar_alt_fill, color: Color(0xff8B5CF6), size: 20),
            const SizedBox(width: 8),
            Text(
              'روندها و تحلیل‌های تعادل',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Trends segment switcher
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildTrendsSegmentButton(0, 'انرژی و حال', colors),
              _buildTrendsSegmentButton(1, 'خواب و بیداری', colors),
              _buildTrendsSegmentButton(2, 'خودارزیابی', colors),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trends contents based on selected segment
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildActiveTrendsContent(colors),
        ),
      ],
    );
  }

  Widget _buildTrendsSegmentButton(int index, String label, RitmoColors colors) {
    final isSelected = _activeTrendsTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          RitmoHaptics.tap();
          setState(() {
            _activeTrendsTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTrendsContent(RitmoColors colors) {
    if (_activeTrendsTab == 0) {
      if (!_energyEnabled) {
        return _buildTrendsInactiveState(
          colors: colors,
          title: 'تحلیل روند انرژی در دسترس نیست',
          description: 'سیستم انرژی و حال روحی غیرفعال است. برای مشاهده نمودارها آن را فعال کنید.',
        );
      }
      return EnergyTrendsSection(
        energyLogs: _energyLogs,
        moodLogs: _moodLogs,
        dominantMood: _moodOutput?.dominantMood,
        correlationInsight: _moodOutput?.correlationInsight ?? 'داده کافی نیست.',
      );
    } else if (_activeTrendsTab == 1) {
      if (!_sleepEnabled) {
        return _buildTrendsInactiveState(
          colors: colors,
          title: 'تحلیل روند خواب در دسترس نیست',
          description: 'سیستم خواب و بیداری غیرفعال است. برای مشاهده الگوها و نمودارها آن را فعال کنید.',
        );
      }
      return SleepTrendsSection(
        durationTrend: _sleepOutput?.durationTrend ?? [],
        qualityTrend: _sleepOutput?.qualityTrend ?? [],
        sleepEnergyCorrelation: _sleepOutput?.sleepEnergyCorrelation,
        sleepMoodCorrelation: _sleepOutput?.sleepMoodCorrelation,
        correlationInsight: _sleepOutput?.correlationInsight ?? 'داده‌های کافی نیست.',
      );
    } else {
      if (_reflectionOutput == null) {
        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
      }
      return ReflectionTrendsSection(
        stats: ReflectionStats(
          currentStreak: _reflectionOutput?.currentStreak ?? 0,
          longestStreak: _reflectionOutput?.longestStreak ?? 0,
          entryCount: _reflectionOutput?.entryCount ?? 0,
          completionRate: _reflectionOutput?.completionRate ?? 0.0,
          avgMoodScore: _reflectionOutput?.avgMoodScore ?? 0.0,
        ),
        moodTrend: _reflectionOutput?.moodTrend ?? [],
        themeFrequency: _reflectionOutput?.themeFrequency ?? {},
        energyCorrelation: _reflectionOutput?.reflectionEnergyCorrelation,
        moodCorrelation: _reflectionOutput?.reflectionMoodCorrelation,
        correlationInsight: _reflectionOutput?.correlationInsight ?? '',
      );
    }
  }

  Widget _buildTrendsInactiveState({
    required RitmoColors colors,
    required String title,
    required String description,
  }) {
    return RitmoTheme.glassCardLight(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(CupertinoIcons.lock_fill, size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
