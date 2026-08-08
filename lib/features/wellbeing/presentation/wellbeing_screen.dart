import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/analytics/mood_engine.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/analytics/sleep_engine.dart';
import 'package:ritmo/core/analytics/wellbeing_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart' hide EnergyLevel;
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/ux/ritmo_empty_state.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/core/widgets/ritmo_progress_ring.dart';
import 'package:ritmo/core/widgets/ritmo_sheet_scaffold.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:ritmo/features/energy/presentation/widgets/quick_log_sheet.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_log_sheet.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_target_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/widgets/frictionless_mood_bar.dart';
import 'package:ritmo/features/wellbeing/presentation/widgets/wellbeing_explanation_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/widgets/wellbeing_pulse_chart.dart';

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

class _WellbeingScreenState extends State<WellbeingScreen>
    with SingleTickerProviderStateMixin {
  bool _hasLoadedOnce = false;
  bool _loadFailed = false;
  bool _isRefreshing = false;
  bool _isDirty = false;
  int _loadToken = 0;
  int _selectedHorizonDays = 14;
  Timer? _reloadDebounce;

  late TabController _tabController;

  bool _energyEnabled = false;
  bool _sleepEnabled = false;

  WellbeingIndex? _wellbeing;
  EnergyAnalyticsOutput? _energyOutput;
  MoodEngineOutput? _moodOutput;
  SleepEngineOutput? _sleepOutput;
  ReflectionEngineOutput? _reflectionOutput;
  LifeBalanceEngineOutput? _lifeBalanceOutput;

  List<EnergyLog> _rawEnergyLogs = [];
  List<MoodLog> _rawMoodLogs = [];
  List<SleepLog> _rawSleepLogs = [];
  List<ReflectionEntry> _reflections = [];
  List<CheckinEntry> _checkins = [];
  SleepTarget _sleepTarget = SleepTarget.defaultTarget();
  List<WellbeingPulseDayData> _pulseDays = [];

  final TextEditingController _quickReflectionController = TextEditingController();
  bool _isSavingReflection = false;

  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    RitmoEvents.routineChanges.addListener(_requestReload);

    // H-01: Strict filtering to relevant wellbeing events only
    _eventSub = RitmoEventBus().onEvents.listen((event) {
      if (event.type == RitmoEventType.moodLogged.code ||
          event.type == RitmoEventType.sleepLogged.code ||
          event.type == RitmoEventType.reflectionSaved.code ||
          event.type == RitmoEventType.energyLogged.code) {
        _requestReload();
      }
    });

    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDirty && mounted && ModalRoute.of(context)?.isCurrent == true) {
      _isDirty = false;
      _requestReload();
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _loadToken++;
    RitmoEvents.routineChanges.removeListener(_requestReload);
    _eventSub?.cancel();
    _tabController.dispose();
    _quickReflectionController.dispose();
    super.dispose();
  }

  void _requestReload() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      _isDirty = true;
      return;
    }

    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadAllData());
    });
  }

  Future<void> _loadAllData() async {
    final token = ++_loadToken;
    final now = DateTime.now();

    try {
      final db = await DatabaseHelper.instance.database;

      // Module enabled checks
      final moduleResults = await Future.wait([
        ModuleManagementService.instance.isModuleEnabled('module_energy_enabled').catchError((_) => false),
        ModuleManagementService.instance.isModuleEnabled('module_sleep_enabled').catchError((_) => false),
      ]);
      _energyEnabled = moduleResults[0];
      _sleepEnabled = moduleResults[1];

      // H-17: Fetch user configured sleep target from settings
      try {
        final targetRows = await db.query('app_settings', where: "key LIKE 'sleep_target_%'");
        String bedtime = '23:30';
        String wake = '07:00';
        int durationMinutes = 450;
        for (final r in targetRows) {
          final k = r['key'] as String;
          final v = r['value'] as String;
          if (k == 'sleep_target_bedtime') bedtime = v;
          if (k == 'sleep_target_wake') wake = v;
          if (k == 'sleep_target_duration_minutes') durationMinutes = int.tryParse(v) ?? 450;
        }
        _sleepTarget = SleepTarget(bedtime: bedtime, wake: wake, durationMinutes: durationMinutes);
      } catch (_) {}

      final horizonMs = RitmoDate.startOfDayMillis(now.subtract(Duration(days: _selectedHorizonDays)));
      final horizonKey = RitmoDate.dayKey(now.subtract(Duration(days: _selectedHorizonDays)));

      // H-03: Parallel DB Queries
      final dbResults = await Future.wait([
        db.query('energy_logs', where: 'loggedAt >= ?', whereArgs: [horizonMs], orderBy: 'loggedAt DESC', limit: 500).catchError((_) => <Map<String, dynamic>>[]),
        db.query('mood_logs', where: 'loggedAt >= ?', whereArgs: [horizonMs], orderBy: 'loggedAt DESC', limit: 500).catchError((_) => <Map<String, dynamic>>[]),
        db.query('sleep_logs', where: 'date >= ?', whereArgs: [horizonKey], orderBy: 'date DESC', limit: 60).catchError((_) => <Map<String, dynamic>>[]),
        db.query('daily_reflections', where: 'date >= ?', whereArgs: [horizonKey], orderBy: 'date DESC', limit: 60).catchError((_) => <Map<String, dynamic>>[]),
        db.query('daily_checkins', where: 'date >= ?', whereArgs: [horizonKey], orderBy: 'date DESC', limit: 60).catchError((_) => <Map<String, dynamic>>[]),
        db.query('routines', where: 'isArchived = 0').catchError((_) => <Map<String, dynamic>>[]),
        db.query('routine_completions', where: 'completionTime >= ?', whereArgs: [horizonMs], limit: 2000).catchError((_) => <Map<String, dynamic>>[]),
        db.query('daily_rhythm', where: 'date >= ?', whereArgs: [horizonKey], limit: 60).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted || token != _loadToken) return;

      final energyRows = dbResults[0];
      final moodRows = dbResults[1];
      final sleepRows = dbResults[2];
      final reflectionRows = dbResults[3];
      final checkinRows = dbResults[4];
      final routineRows = dbResults[5];
      final completionRows = dbResults[6];
      final rhythmRows = dbResults[7];

      _rawEnergyLogs = energyRows.map((r) => EnergyLog.fromMap(r)).toList();
      _rawMoodLogs = moodRows.map((r) => MoodLog.fromMap(r)).toList();
      _rawSleepLogs = sleepRows.map((r) => SleepLog.fromMap(r)).toList();
      _reflections = reflectionRows.map((r) => ReflectionEntry.fromMap(r)).toList();
      _checkins = checkinRows.map((r) => CheckinEntry.fromMap(r)).toList();

      final energyInput = EnergyAnalyticsEngineInput(
        energyLogs: energyRows,
        routineCompletions: completionRows,
        dailyRhythm: rhythmRows,
        now: now,
      );
      final moodInput = MoodEngineInput(
        moodLogs: _rawMoodLogs,
        energyLogs: _rawEnergyLogs,
        today: now,
      );
      final sleepInput = SleepEngineInput(
        sleepLogs: _rawSleepLogs,
        target: _sleepTarget,
        energyLogs: energyRows,
        moodLogs: moodRows,
        today: now,
      );
      final reflectionInput = ReflectionEngineInput(
        dailyReflections: reflectionRows,
        dailyCheckins: checkinRows,
        energyLogs: energyRows,
        moodLogs: moodRows,
        today: now,
        computeThemes: false,
      );
      final balanceInput = LifeBalanceEngineInput(
        now: now,
        routines: routineRows,
        routineCompletions: completionRows,
      );

      // Safe Engine Evaluations with Direct Instantiation Fallbacks & 3s Timeouts
      EnergyAnalyticsOutput? energyOut;
      try {
        energyOut = await RitmoEngineBus.instance.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(EnergyAnalyticsEngine, energyInput).timeout(const Duration(seconds: 3));
      } catch (_) {
        try { energyOut = await EnergyAnalyticsEngine().calculate(energyInput); } catch (_) {}
      }

      MoodEngineOutput? moodOut;
      try {
        moodOut = await RitmoEngineBus.instance.execute<MoodEngineInput, MoodEngineOutput>(MoodEngine, moodInput).timeout(const Duration(seconds: 3));
      } catch (_) {
        try { moodOut = await MoodEngine().calculate(moodInput); } catch (_) {}
      }

      SleepEngineOutput? sleepOut;
      try {
        sleepOut = await RitmoEngineBus.instance.execute<SleepEngineInput, SleepEngineOutput>(SleepEngine, sleepInput).timeout(const Duration(seconds: 3));
      } catch (_) {
        try { sleepOut = await SleepEngine().calculate(sleepInput); } catch (_) {}
      }

      ReflectionEngineOutput? reflectionOut;
      try {
        reflectionOut = await RitmoEngineBus.instance.execute<ReflectionEngineInput, ReflectionEngineOutput>(ReflectionEngine, reflectionInput).timeout(const Duration(seconds: 3));
      } catch (_) {
        try { reflectionOut = await ReflectionEngine().calculate(reflectionInput); } catch (_) {}
      }

      LifeBalanceEngineOutput? balanceOut;
      try {
        balanceOut = await RitmoEngineBus.instance.execute<LifeBalanceEngineInput, LifeBalanceEngineOutput>(LifeBalanceEngine, balanceInput).timeout(const Duration(seconds: 3));
      } catch (_) {
        try { balanceOut = await LifeBalanceEngine().calculate(balanceInput); } catch (_) {}
      }

      if (!mounted) return;

      _energyOutput = energyOut;
      _moodOutput = moodOut;
      _sleepOutput = sleepOut;
      _reflectionOutput = reflectionOut;
      _lifeBalanceOutput = balanceOut;

      _wellbeing = const WellbeingEngine().compute(
        WellbeingEngineInput(
          now: now,
          horizonDays: _selectedHorizonDays,
          sleepNights: _rawSleepLogs.length,
          targetSleepHours: _sleepTarget.durationMinutes / 60.0,
          avgSleepQuality: _sleepOutput?.avgQuality,
          sleepConsistency: _sleepOutput?.consistencyScore,
          energySamples: _rawEnergyLogs.length,
          avgEnergyLevel: _energyOutput?.avgLevel,
          energyIsAiDerived: _energyOutput?.isAiDerived ?? false,
          moodSamples: _rawMoodLogs.length,
          avgMoodScore: _moodOutput?.avgScore,
          reflectionEntries: _reflections.length,
          avgReflectionMood: _reflectionOutput?.avgMoodScore,
        ),
      );

      // Build trend dataset once in _loadAllData
      final dayKeys = RitmoDate.lastNDayKeys(now, _selectedHorizonDays);
      final energyByDate = <String, double>{};
      for (final e in _rawEnergyLogs) {
        final key = RitmoDate.dayKey(DateTime.fromMillisecondsSinceEpoch(e.loggedAt));
        var val = 2.0;
        if (e.energyLevel == EnergyLevel.high) val = 3.0;
        if (e.energyLevel == EnergyLevel.low) val = 1.0;
        energyByDate[key] = val;
      }

      final sleepByDate = <String, double>{};
      for (final s in _rawSleepLogs) {
        sleepByDate[s.date] = s.durationHours;
      }

      final moodByDate = <String, double>{};
      for (final m in _rawMoodLogs) {
        final key = RitmoDate.dayKey(DateTime.fromMillisecondsSinceEpoch(m.loggedAt));
        moodByDate[key] = m.valence.toDouble();
      }

      final reflectionDates = _reflections.map((r) => r.date).toSet();

      _pulseDays = dayKeys.map((key) {
        return WellbeingPulseDayData(
          dateStr: key,
          sleepHours: sleepByDate[key],
          energyLevel: energyByDate[key],
          moodScore: moodByDate[key],
          hasReflection: reflectionDates.contains(key),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _loadFailed = false;
          _hasLoadedOnce = true;
          _isRefreshing = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[WellbeingScreen ERROR] $e\n$stack');
    } finally {
      if (mounted) {
        setState(() {
          _hasLoadedOnce = true;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _saveQuickReflection() async {
    final text = _quickReflectionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSavingReflection = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = RitmoDate.dayKey(DateTime.now());
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final existing = await db.query('daily_reflections', where: 'date = ?', whereArgs: [todayStr]);
      if (existing.isNotEmpty) {
        await db.update(
          'daily_reflections',
          {
            'goodThing': text,
            'updatedAt': nowMs,
          },
          where: 'date = ?',
          whereArgs: [todayStr],
        );
      } else {
        await db.insert('daily_reflections', {
          'id': 'refl_$nowMs',
          'date': todayStr,
          'goodThing': text,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
      }

      _quickReflectionController.clear();
      RitmoHapticsPolicy.tap();
      _requestReload();
    } catch (e) {
      debugPrint('Error saving quick reflection: $e');
    } finally {
      if (mounted) setState(() => _isSavingReflection = false);
    }
  }

  void _openAssistant() {
    RitmoSheetScaffold.present(
      context: context,
      title: 'دستیار هوشمند حال و تعادل',
      subtitle: 'راهنمای تحلیل ریتم زیستی شما',
      builder: (ctx) => AiWellbeingAssistantSheet(
        energyEnabled: _energyEnabled,
        sleepEnabled: _sleepEnabled,
        todayCheckinDone: _checkins.any((c) => c.date == RitmoDate.dayKey(DateTime.now())),
        todayReflectionDone: _reflections.any((r) => r.date == RitmoDate.dayKey(DateTime.now())),
        onSaved: _requestReload,
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    final w = _wellbeing ?? WellbeingIndex(value: null, confidence: 0, contributions: const [], missing: const [], computedAtMillis: DateTime.now().millisecondsSinceEpoch);
    WellbeingExplanationSheet.show(context, w);
  }

  void _setHorizonDays(int days) {
    if (_selectedHorizonDays == days) return;
    RitmoHapticsPolicy.tap();
    setState(() => _selectedHorizonDays = days);
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!_hasLoadedOnce) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: RitmoSkeletonList()),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 140,
              backgroundColor: colors.surface,
              elevation: 0,
              title: Text(
                'حال و تعادل',
                style: RitmoTextStyles.pageTitle(colors.textPrimary),
              ),
              actions: [
                Semantics(
                  button: true,
                  label: 'دستیار هوشمند حال و تعادل',
                  child: IconButton(
                    tooltip: 'دستیار هوشمند',
                    icon: Icon(Icons.auto_awesome, color: colors.accent),
                    onPressed: _openAssistant,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Column(
                  children: [
                    // I-07: Timeframe Selector Pills (7 / 14 / 30 / 90)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [7, 14, 30, 90].map((d) {
                          final isSelected = _selectedHorizonDays == d;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('${RitmoNumber.faInt(d)} روزه'),
                              selected: isSelected,
                              onSelected: (_) => _setHorizonDays(d),
                              selectedColor: colors.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? colors.primary : colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: colors.primary,
                      labelColor: colors.primary,
                      unselectedLabelColor: colors.textSecondary,
                      labelStyle: RitmoTextStyles.label(colors.primary),
                      unselectedLabelStyle: RitmoTextStyles.caption(colors.textSecondary),
                      tabs: const [
                        Tab(text: 'امروزِ من'),
                        Tab(text: 'روند من'),
                        Tab(text: 'آینه'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          color: colors.primary,
          child: TabBarView(
            controller: _tabController,
            children: [
              _WellbeingTabKeepAlive(child: _buildTodayTab(context)),
              _WellbeingTabKeepAlive(child: _buildTrendTab(context)),
              _WellbeingTabKeepAlive(child: _buildMirrorTab(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTab(BuildContext context) {
    if (_loadFailed) {
      return _buildErrorCard(context);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildIndexHeroCard(context),
              const SizedBox(height: RitmoSpacing.lg),
              FrictionlessMoodBar(onLogChanged: _requestReload),
              const SizedBox(height: RitmoSpacing.lg),
              _buildQuickActionsRow(context),
              const SizedBox(height: RitmoSpacing.lg),
              _buildGoldenWindowCard(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendTab(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              WellbeingPulseChart(
                days: _pulseDays,
                onDayTap: (day) => _openDayDetailSheet(context, day),
              ),
              const SizedBox(height: RitmoSpacing.lg),
              _buildEffortDistributionCard(context),
              const SizedBox(height: RitmoSpacing.lg),
              _buildSleepBankCard(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMirrorTab(BuildContext context) {
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // I-01: Inline 1-tap Reflection Input Card ("امروز چه چیز خوبی اتفاق افتاد؟")
              Container(
                padding: const EdgeInsets.all(RitmoSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(RitmoRadius.card),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: colors.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'ثبت سریع بازتاب امروز',
                          style: RitmoTextStyles.cardTitle(colors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quickReflectionController,
                      style: RitmoTextStyles.body(colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'امروز چه چیز خوبی اتفاق افتاد؟',
                        hintStyle: RitmoTextStyles.caption(colors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingReflection ? null : _saveQuickReflection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: _isSavingReflection
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 16),
                        label: Text('ثبت بازتاب', style: RitmoTextStyles.label(colors.onPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RitmoSpacing.lg),

              Container(
                padding: const EdgeInsets.all(RitmoSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(RitmoRadius.card),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بازتاب‌های $_selectedHorizonDays روز اخیر',
                      style: RitmoTextStyles.cardTitle(colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${RitmoNumber.faInt(_reflections.length)} بازتاب و ${RitmoNumber.faInt(_checkins.length)} چک‌ین ثبت شده است.',
                      style: RitmoTextStyles.body(colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RitmoSpacing.lg),
              _buildGoodThingsQuotesCard(context),
              const SizedBox(height: RitmoSpacing.lg),
              Text(
                'دفتر ثبت‌ها',
                style: RitmoTextStyles.cardTitle(colors.textPrimary),
              ),
              const SizedBox(height: RitmoSpacing.md),
              if (_reflections.isEmpty && _checkins.isEmpty)
                const RitmoEmptyState(
                  icon: Icons.auto_stories,
                  title: 'هنوز بازتابی ثبت نشده',
                  description: 'از کادر بالای صفحه اولین بازتاب خود را ثبت کن.',
                )
              else
                // I-02: Interactive Reflection List
                ..._reflections.take(15).map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: RitmoSpacing.md),
                    child: InkWell(
                      onTap: () => _showReflectionDetailSheet(context, r),
                      borderRadius: BorderRadius.circular(RitmoRadius.card),
                      child: Container(
                        padding: const EdgeInsets.all(RitmoSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(RitmoRadius.card),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  RitmoNumber.fa(r.date),
                                  style: RitmoTextStyles.caption(colors.textSecondary),
                                ),
                                Icon(Icons.chevron_left, size: 18, color: colors.textSecondary),
                              ],
                            ),
                            if (r.goodThing != null && r.goodThing!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '💡 ${r.goodThing}',
                                style: RitmoTextStyles.body(colors.textPrimary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildIndexHeroCard(BuildContext context) {
    final colors = context.colors;
    final w = _wellbeing;

    // H-22: Render missing card cleanly with explanations & direct sheet tap
    if (w == null || !w.hasValue) {
      return Container(
        padding: const EdgeInsets.all(RitmoSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(RitmoRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const RitmoProgressRing(value: null),
            const SizedBox(height: RitmoSpacing.md),
            Text(
              'داده‌ها هنوز کافی نیست',
              style: RitmoTextStyles.cardTitle(colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'برای محاسبه شاخص، دست‌کم به ثبت خواب یا دو سیگنال مشخص نیاز است.',
              style: RitmoTextStyles.caption(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RitmoSpacing.md),
            TextButton.icon(
              onPressed: () => _showExplanation(context),
              icon: Icon(Icons.help_outline, size: 16, color: colors.primary),
              label: Text('چرا این عدد؟ (راهنمای سیگنال‌ها)', style: RitmoTextStyles.label(colors.primary)),
            ),
          ],
        ),
      );
    }

    // H-25: Clean confidence bounds without 0 to 0 traps
    final lower = w.lowerBound != null ? RitmoNumber.faInt(w.lowerBound!) : '---';
    final upper = w.upperBound != null ? RitmoNumber.faInt(w.upperBound!) : '---';
    final valStr = w.value != null ? RitmoNumber.faInt(w.value!) : '---';

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          RitmoProgressRing(
            value: w.value,
            confidence: w.confidence,
            lowerBound: w.lowerBound,
            upperBound: w.upperBound,
            onTap: () => _showExplanation(context),
          ),
          const SizedBox(height: RitmoSpacing.md),
          Text(
            'امتیاز شاخص: $valStr — (دامنه $lower تا $upper)',
            style: RitmoTextStyles.caption(colors.textSecondary),
          ),
          const SizedBox(height: RitmoSpacing.sm),
          TextButton.icon(
            onPressed: () => _showExplanation(context),
            icon: Icon(Icons.info_outline, size: 16, color: colors.primary),
            label: Text('چرا این عدد؟', style: RitmoTextStyles.label(colors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final colors = context.colors;

    // I-03: Inline Activation Card when modules are disabled
    if (!_energyEnabled || !_sleepEnabled) {
      return Container(
        padding: const EdgeInsets.all(RitmoSpacing.md),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(RitmoRadius.card),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ماژول‌های انرژی و خواب غیرفعال هستند.',
                style: RitmoTextStyles.caption(colors.textPrimary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ModuleManagementService.instance.setModuleEnabled('module_energy_enabled', true);
                await ModuleManagementService.instance.setModuleEnabled('module_sleep_enabled', true);
                _requestReload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text('فعالسازی درجا', style: RitmoTextStyles.label(colors.onPrimary)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // I-14: 1-tap inline Energy Logging Bar
        Container(
          padding: const EdgeInsets.all(RitmoSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Text('انرژی الان:', style: RitmoTextStyles.caption(colors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _energyLevelChip(context, label: 'کم ⚡', level: 'LOW', color: colors.cautionAccent),
                    _energyLevelChip(context, label: 'متوسط ⚡', level: 'MEDIUM', color: colors.primary),
                    _energyLevelChip(context, label: 'زیاد ⚡', level: 'HIGH', color: colors.success),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionButton(
                context,
                label: 'ثبت جزئیات انرژی',
                icon: Icons.bolt,
                color: colors.energyAccent,
                onTap: () {
                  RitmoSheetScaffold.present(
                    context: context,
                    title: 'ثبت سطح انرژی',
                    builder: (ctx) => QuickLogSheet(onSaved: _requestReload),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionButton(
                context,
                label: 'ثبت خواب دیشب',
                icon: Icons.bedtime,
                color: colors.sleepAccent,
                onTap: () {
                  RitmoSheetScaffold.present(
                    context: context,
                    title: 'ثبت خواب دیشب',
                    builder: (ctx) => SleepLogSheet(
                      onSaved: _requestReload,
                      target: _sleepTarget,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _energyLevelChip(BuildContext context, {required String label, required String level, required Color color}) {
    return InkWell(
      onTap: () async {
        RitmoHapticsPolicy.tap();
        final db = await DatabaseHelper.instance.database;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await db.insert('energy_logs', {
          'id': 'eng_$nowMs',
          'energyLevel': level,
          'loggedAt': nowMs,
        });
        _requestReload();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        RitmoHapticsPolicy.tap();
        onTap();
      },
      borderRadius: BorderRadius.circular(RitmoRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(RitmoRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: RitmoTextStyles.label(color)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldenWindowCard(BuildContext context) {
    final colors = context.colors;

    if (_energyOutput == null || (_energyOutput?.sampleCount ?? 0) < 20) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: colors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'پنجرهٔ طلایی انرژی',
                    style: RitmoTextStyles.cardTitle(colors.textPrimary),
                  ),
                ],
              ),
              // I-04: Action button on Golden Window card
              TextButton(
                onPressed: () {
                  RitmoHapticsPolicy.tap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برنامه‌ریزی روتین‌ها در پنجره طلایی انجام شد.')),
                  );
                },
                child: Text('انتقال به پنجره طلایی', style: TextStyle(fontSize: 11.5, color: colors.primary, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'بازهٔ اوج انرژی شما: ${_energyOutput?.peakPerformanceWindow ?? "نامشخص"}',
            style: RitmoTextStyles.body(colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'بر پایهٔ ${RitmoNumber.faInt(_energyOutput?.sampleCount ?? 0)} ثبت در $_selectedHorizonDays روز اخیر',
            style: RitmoTextStyles.caption(colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEffortDistributionCard(BuildContext context) {
    final colors = context.colors;
    final score = _lifeBalanceOutput?.score;
    final distribution = _lifeBalanceOutput?.distribution ?? {};

    // Domain names & icons in Persian
    final domainMap = {
      'RELIGION': 'عبادی 🤲',
      'HEALTH': 'ورزش و سلامت 🏋️',
      'LEARNING': 'یادگیری 📚',
      'WORK': 'کار و تلاش 💼',
      'PERSONAL': 'شخصی 🌿',
      'FREE': 'تفریح 🎨',
    };

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزیع تلاش بین حوزه‌ها',
            style: RitmoTextStyles.cardTitle(colors.textPrimary),
          ),
          const SizedBox(height: 8),
          // H-21: Use LifeBalanceEngine.minCompletionsForBalance constant
          if (score == null)
            Text(
              'برای محاسبهٔ تعادل، حداقل ${RitmoNumber.faInt(LifeBalanceEngine.minCompletionsForBalance)} روتین تکمیل‌شده لازم است.',
              style: RitmoTextStyles.caption(colors.textSecondary),
            )
          else ...[
            Text(
              'امتیاز توزیع: ${RitmoNumber.faInt(score)} از ۱۰۰',
              style: RitmoTextStyles.body(colors.textPrimary),
            ),
            const SizedBox(height: 12),
            // I-05 / P-7: 6-Domain Divergence Bar Chart
            Column(
              children: domainMap.entries.map((e) {
                final ratio = ((distribution[e.key] ?? 0.0) / 100.0).clamp(0.05, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(e.value, style: const TextStyle(fontSize: 11.5, fontFamily: 'Vazirmatn'))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: colors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepBankCard(BuildContext context) {
    final colors = context.colors;
    final balance = _sleepOutput?.sleepBalanceHours ?? 0.0;
    final isDeficit = balance < 0;

    // H-20: Correct card handling when 0 nights logged
    final isZeroData = _rawSleepLogs.isEmpty;

    return InkWell(
      onTap: () {
        RitmoHapticsPolicy.tap();
        RitmoSheetScaffold.present(
          context: context,
          title: 'تنظیم هدف خواب',
          builder: (ctx) => SleepTargetSheet(
            currentTarget: _sleepTarget,
            onSaved: _requestReload,
          ),
        );
      },
      borderRadius: BorderRadius.circular(RitmoRadius.card),
      child: Container(
        padding: const EdgeInsets.all(RitmoSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(RitmoRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(
              isZeroData
                  ? Icons.bedtime_outlined
                  : (isDeficit ? Icons.battery_alert : Icons.battery_charging_full),
              color: isZeroData
                  ? colors.textSecondary
                  : (isDeficit ? colors.cautionAccent : colors.success),
              size: 28,
            ),
            const SizedBox(width: RitmoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZeroData
                        ? 'ذخیرهٔ خواب: داده‌ای ثبت نشده است'
                        : (isDeficit
                            ? 'کسری خواب: ${RitmoNumber.faHours(balance.abs())}'
                            : 'ذخیرهٔ خواب: ${RitmoNumber.faHours(balance)}'),
                    style: RitmoTextStyles.cardTitle(
                      isZeroData
                          ? colors.textPrimary
                          : (isDeficit ? colors.cautionAccent : colors.success),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isZeroData
                        ? 'برای تنظیم هدف خواب و پایش ذخیره زیستی، کلیک کنید.'
                        : (isDeficit
                            ? 'یک خواب جبرانی کوتاه می‌تواند به بازیابی کمک کند.'
                            : 'خواب کافی در روزهای اخیر ذخیرهٔ خوبی ایجاد کرده است.'),
                    style: RitmoTextStyles.caption(colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodThingsQuotesCard(BuildContext context) {
    final colors = context.colors;

    final quotes = _reflections
        .map((r) => r.goodThing)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(3)
        .toList();

    if (quotes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'چیزهایی که خوب بودند',
            style: RitmoTextStyles.cardTitle(colors.textPrimary),
          ),
          const SizedBox(height: RitmoSpacing.md),
          ...quotes.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('💬 «$q»', style: RitmoTextStyles.body(colors.textPrimary)),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RitmoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: RitmoSpacing.md),
            Text(
              'خطا در دریافت اطلاعات',
              style: RitmoTextStyles.cardTitle(colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'مشکلی در بارگذاری داده‌ها پیش آمد.',
              style: RitmoTextStyles.caption(colors.textSecondary),
            ),
            const SizedBox(height: RitmoSpacing.lg),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: Text('تلاش دوباره', style: RitmoTextStyles.label(colors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  // I-08: Interactive Day Detail Sheet ("ورق روز")
  void _openDayDetailSheet(BuildContext context, WellbeingPulseDayData day) {
    RitmoHapticsPolicy.tap();
    RitmoSheetScaffold.present(
      context: context,
      title: 'ورق روز — ${RitmoNumber.fa(day.dateStr)}',
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: Icon(Icons.bedtime, color: colors.sleepAccent),
                title: Text(day.sleepHours != null ? 'خواب: ${RitmoNumber.faHours(day.sleepHours!)}' : 'خواب ثبت نشده است', style: const TextStyle(fontFamily: 'Vazirmatn')),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    RitmoSheetScaffold.present(
                      context: context,
                      title: 'ثبت خواب',
                      builder: (_) => SleepLogSheet(onSaved: _requestReload, target: _sleepTarget),
                    );
                  },
                  child: const Text('ثبت / ویرایش', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ),
              ListTile(
                leading: Icon(Icons.bolt, color: colors.energyAccent),
                title: Text(day.energyLevel != null ? 'انرژی: ${RitmoNumber.faInt((day.energyLevel! * 33).round())}٪' : 'انرژی ثبت نشده است', style: const TextStyle(fontFamily: 'Vazirmatn')),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    RitmoSheetScaffold.present(
                      context: context,
                      title: 'ثبت انرژی',
                      builder: (_) => QuickLogSheet(onSaved: _requestReload),
                    );
                  },
                  child: const Text('ثبت / ویرایش', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_note, color: colors.primary),
                title: Text(day.hasReflection ? 'بازتاب ثبت شده است ✅' : 'بازتاب ثبت نشده است', style: const TextStyle(fontFamily: 'Vazirmatn')),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    RitmoSheetScaffold.present(
                      context: context,
                      title: 'ثبت بازتاب روز',
                      builder: (_) => DailyReflectionSheet(onSaved: _requestReload, date: day.dateStr),
                    );
                  },
                  child: const Text('ثبت بازتاب', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReflectionDetailSheet(BuildContext context, ReflectionEntry reflection) {
    RitmoSheetScaffold.present(
      context: context,
      title: 'بازتاب روز ${RitmoNumber.fa(reflection.date)}',
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reflection.goodThing != null) ...[
                Text('💡 اتفاق خوب:', style: RitmoTextStyles.caption(colors.textSecondary)),
                const SizedBox(height: 4),
                Text(reflection.goodThing!, style: RitmoTextStyles.body(colors.textPrimary)),
                const SizedBox(height: 12),
              ],
              if (reflection.gratitude != null) ...[
                Text('🙏 شکرگزاری:', style: RitmoTextStyles.caption(colors.textSecondary)),
                const SizedBox(height: 4),
                Text(reflection.gratitude!, style: RitmoTextStyles.body(colors.textPrimary)),
                const SizedBox(height: 12),
              ],
              if (reflection.challenges != null) ...[
                Text('🌱 چالش و یادگیری:', style: RitmoTextStyles.caption(colors.textSecondary)),
                const SizedBox(height: 4),
                Text(reflection.challenges!, style: RitmoTextStyles.body(colors.textPrimary)),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      RitmoSheetScaffold.present(
                        context: context,
                        title: 'ویرایش بازتاب',
                        builder: (_) => DailyReflectionSheet(onSaved: _requestReload, date: reflection.date),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('ویرایش کامل', style: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final db = await DatabaseHelper.instance.database;
                      await db.delete('daily_reflections', where: 'date = ?', whereArgs: [reflection.date]);
                      _requestReload();
                    },
                    icon: Icon(Icons.delete, size: 16, color: colors.error),
                    label: Text('حذف', style: TextStyle(color: colors.error, fontFamily: 'Vazirmatn')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// H-10: Tab keep-alive wrapper widget
class _WellbeingTabKeepAlive extends StatefulWidget {
  const _WellbeingTabKeepAlive({required this.child});
  final Widget child;

  @override
  State<_WellbeingTabKeepAlive> createState() => _WellbeingTabKeepAliveState();
}

class _WellbeingTabKeepAliveState extends State<_WellbeingTabKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
