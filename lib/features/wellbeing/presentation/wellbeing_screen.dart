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
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/core/widgets/ritmo_progress_ring.dart';
import 'package:ritmo/core/widgets/ritmo_sheet_scaffold.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:ritmo/features/energy/presentation/widgets/quick_log_sheet.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_log_sheet.dart';
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
  bool _isRefreshing = false;
  bool _loadFailed = false;
  int _loadToken = 0;
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
  final SleepTarget _sleepTarget = SleepTarget.defaultTarget();

  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    RitmoEvents.routineChanges.addListener(_requestReload);
    _eventSub = RitmoEventBus().onEvents.listen((_) => _requestReload());

    _loadAllData();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _loadToken++;
    RitmoEvents.routineChanges.removeListener(_requestReload);
    _eventSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _requestReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadAllData());
    });
  }

  Future<void> _loadAllData() async {
    final token = ++_loadToken;
    if (mounted) setState(() => _isRefreshing = true);

    final now = DateTime.now();

    try {
      final db = await DatabaseHelper.instance.database;

      try {
        _energyEnabled = await ModuleManagementService.instance.isModuleEnabled('module_energy_enabled');
      } catch (_) {
        _energyEnabled = false;
      }

      try {
        _sleepEnabled = await ModuleManagementService.instance.isModuleEnabled('module_sleep_enabled');
      } catch (_) {
        _sleepEnabled = false;
      }

      final horizonMs = RitmoDate.startOfDayMillis(now.subtract(const Duration(days: 14)));
      final horizonKey = RitmoDate.dayKey(now.subtract(const Duration(days: 14)));

      List<Map<String, dynamic>> energyRows = [];
      try {
        energyRows = await db.query(
          'energy_logs',
          where: 'loggedAt >= ?',
          whereArgs: [horizonMs],
          orderBy: 'loggedAt DESC',
          limit: 500,
        );
      } catch (_) {}

      List<Map<String, dynamic>> moodRows = [];
      try {
        moodRows = await db.query(
          'mood_logs',
          where: 'loggedAt >= ?',
          whereArgs: [horizonMs],
          orderBy: 'loggedAt DESC',
          limit: 500,
        );
      } catch (_) {}

      List<Map<String, dynamic>> sleepRows = [];
      try {
        sleepRows = await db.query(
          'sleep_logs',
          where: 'date >= ?',
          whereArgs: [horizonKey],
          orderBy: 'date DESC',
          limit: 60,
        );
      } catch (_) {}

      List<Map<String, dynamic>> reflectionRows = [];
      try {
        reflectionRows = await db.query(
          'daily_reflections',
          where: 'date >= ?',
          whereArgs: [horizonKey],
          orderBy: 'date DESC',
          limit: 60,
        );
      } catch (_) {}

      List<Map<String, dynamic>> checkinRows = [];
      try {
        checkinRows = await db.query(
          'daily_checkins',
          where: 'date >= ?',
          whereArgs: [horizonKey],
          orderBy: 'date DESC',
          limit: 60,
        );
      } catch (_) {}

      List<Map<String, dynamic>> routineRows = [];
      try {
        routineRows = await db.query('routines', where: 'isArchived = 0');
      } catch (_) {}

      List<Map<String, dynamic>> completionRows = [];
      try {
        completionRows = await db.query(
          'routine_completions',
          where: 'completionTime >= ?',
          whereArgs: [horizonMs],
          limit: 2000,
        );
      } catch (_) {}

      List<Map<String, dynamic>> rhythmRows = [];
      try {
        rhythmRows = await db.query(
          'daily_rhythm',
          where: 'date >= ?',
          whereArgs: [horizonKey],
          limit: 60,
        );
      } catch (_) {}

      if (!mounted || token != _loadToken) return;

      _rawEnergyLogs = energyRows.map((r) {
        try {
          return EnergyLog.fromMap(r);
        } catch (_) {
          return null;
        }
      }).whereType<EnergyLog>().toList();

      _rawMoodLogs = moodRows.map((r) {
        try {
          return MoodLog.fromMap(r);
        } catch (_) {
          return null;
        }
      }).whereType<MoodLog>().toList();

      _rawSleepLogs = sleepRows.map((r) {
        try {
          return SleepLog.fromMap(r);
        } catch (_) {
          return null;
        }
      }).whereType<SleepLog>().toList();

      _reflections = reflectionRows.map((r) {
        try {
          return ReflectionEntry.fromMap(r);
        } catch (_) {
          return null;
        }
      }).whereType<ReflectionEntry>().toList();

      _checkins = checkinRows.map((r) {
        try {
          return CheckinEntry.fromMap(r);
        } catch (_) {
          return null;
        }
      }).whereType<CheckinEntry>().toList();

      RitmoEngineBus? bus;
      try {
        bus = RitmoEngineBus.instance;
      } catch (_) {}

      try {
        final input = EnergyAnalyticsEngineInput(
          energyLogs: energyRows,
          routineCompletions: completionRows,
          dailyRhythm: rhythmRows,
          now: now,
        );
        _energyOutput = bus != null
            ? await bus.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(EnergyAnalyticsEngine, input)
            : await EnergyAnalyticsEngine().calculate(input);
      } catch (_) {}

      try {
        final input = MoodEngineInput(
          moodLogs: _rawMoodLogs,
          energyLogs: _rawEnergyLogs,
          today: now,
        );
        _moodOutput = bus != null
            ? await bus.execute<MoodEngineInput, MoodEngineOutput>(MoodEngine, input)
            : await MoodEngine().calculate(input);
      } catch (_) {}

      try {
        final input = SleepEngineInput(
          sleepLogs: _rawSleepLogs,
          target: _sleepTarget,
          energyLogs: energyRows,
          moodLogs: moodRows,
          today: now,
        );
        _sleepOutput = bus != null
            ? await bus.execute<SleepEngineInput, SleepEngineOutput>(SleepEngine, input)
            : await SleepEngine().calculate(input);
      } catch (_) {}

      try {
        final input = ReflectionEngineInput(
          dailyReflections: reflectionRows,
          dailyCheckins: checkinRows,
          energyLogs: energyRows,
          moodLogs: moodRows,
          today: now,
          computeThemes: false,
        );
        _reflectionOutput = bus != null
            ? await bus.execute<ReflectionEngineInput, ReflectionEngineOutput>(ReflectionEngine, input)
            : await ReflectionEngine().calculate(input);
      } catch (_) {}

      try {
        final input = LifeBalanceEngineInput(
          now: now,
          routines: routineRows,
          routineCompletions: completionRows,
        );
        _lifeBalanceOutput = bus != null
            ? await bus.execute<LifeBalanceEngineInput, LifeBalanceEngineOutput>(LifeBalanceEngine, input)
            : await LifeBalanceEngine().calculate(input);
      } catch (_) {}

      try {
        _wellbeing = const WellbeingEngine().compute(
          WellbeingEngineInput(
            now: now,
            horizonDays: 14,
            sleepNights: _rawSleepLogs.length,
            avgSleepHours: _sleepOutput != null && _rawSleepLogs.isNotEmpty
                ? _sleepOutput!.avgDurationMinutes / 60.0
                : null,
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
      } catch (_) {}

      if (!mounted || token != _loadToken) return;

      setState(() {
        _loadFailed = false;
        _hasLoadedOnce = true;
        _isRefreshing = false;
      });
    } catch (e, stack) {
      debugPrint('[WellbeingScreen ERROR] $e\n$stack');
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loadFailed = false;
        _hasLoadedOnce = true;
        _isRefreshing = false;
      });
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
              expandedHeight: 110,
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
              bottom: TabBar(
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
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          color: colors.primary,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(context),
              _buildTrendTab(context),
              _buildMirrorTab(context),
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
    final dayKeys = RitmoDate.lastNDayKeys(DateTime.now(), 14);
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

    final pulseDays = dayKeys.map((key) {
      return WellbeingPulseDayData(
        dateStr: key,
        sleepHours: sleepByDate[key],
        energyLevel: energyByDate[key],
        moodScore: moodByDate[key],
        hasReflection: reflectionDates.contains(key),
      );
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              WellbeingPulseChart(days: pulseDays),
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
              Container(
                padding: const EdgeInsets.all(RitmoSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(RitmoRadius.card),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دو هفتهٔ تو در یک نگاه',
                      style: RitmoTextStyles.cardTitle(colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${RitmoNumber.faInt(_reflections.length)} بازتاب و ${RitmoNumber.faInt(_checkins.length)} چک‌ین در ۱۴ روز اخیر ثبت شده است.',
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
                  description: 'اولین بازتاب یا حال امروزت را ثبت کن تا در آینه ببینی.',
                )
              else
                ..._reflections.take(10).map((r) => Container(
                      margin: const EdgeInsets.only(bottom: RitmoSpacing.md),
                      padding: const EdgeInsets.all(RitmoSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(RitmoRadius.card),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            RitmoNumber.fa(r.date),
                            style: RitmoTextStyles.caption(colors.textSecondary),
                          ),
                          if (r.goodThing != null && r.goodThing!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '💡 ${r.goodThing}',
                              style: RitmoTextStyles.body(colors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    )),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildIndexHeroCard(BuildContext context) {
    final colors = context.colors;
    final w = _wellbeing;

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
            const SizedBox(height: 4),
            Text(
              'حداقل ۳ روز اطلاعات ثبت کن تا شاخص حال و تعادل محاسبه شود.',
              style: RitmoTextStyles.caption(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
            onTap: () => WellbeingExplanationSheet.show(context, w),
          ),
          const SizedBox(height: RitmoSpacing.md),
          Text(
            'تقریباً ${RitmoNumber.faInt(w.value ?? 0)} — دامنهٔ ${RitmoNumber.faInt(w.lowerBound ?? 0)} تا ${RitmoNumber.faInt(w.upperBound ?? 0)}',
            style: RitmoTextStyles.caption(colors.textSecondary),
          ),
          const SizedBox(height: RitmoSpacing.sm),
          TextButton.icon(
            onPressed: () => WellbeingExplanationSheet.show(context, w),
            icon: Icon(Icons.info_outline, size: 16, color: colors.primary),
            label: Text('چرا این عدد؟', style: RitmoTextStyles.label(colors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        if (_energyEnabled)
          Expanded(
            child: _quickActionButton(
              context,
              label: 'ثبت انرژی',
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
        if (_energyEnabled && _sleepEnabled) const SizedBox(width: 12),
        if (_sleepEnabled)
          Expanded(
            child: _quickActionButton(
              context,
              label: 'ثبت خواب',
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
            children: [
              Icon(Icons.wb_sunny_outlined, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'پنجرهٔ طلایی انرژی',
                style: RitmoTextStyles.cardTitle(colors.textPrimary),
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
            'بر پایهٔ ${RitmoNumber.faInt(_energyOutput?.sampleCount ?? 0)} ثبت در ۱۴ روز اخیر',
            style: RitmoTextStyles.caption(colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEffortDistributionCard(BuildContext context) {
    final colors = context.colors;
    final score = _lifeBalanceOutput?.score;

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
          if (score == null)
            Text(
              'برای محاسبهٔ تعادل، حداقل ۱۰ روتین تکمیل‌شده لازم است.',
              style: RitmoTextStyles.caption(colors.textSecondary),
            )
          else
            Text(
              'امتیاز توزیع: ${RitmoNumber.faInt(score)} از ۱۰۰',
              style: RitmoTextStyles.body(colors.textPrimary),
            ),
        ],
      ),
    );
  }

  Widget _buildSleepBankCard(BuildContext context) {
    final colors = context.colors;
    final balance = _sleepOutput?.sleepBalanceHours ?? 0.0;
    final isDeficit = balance < 0;

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            isDeficit ? Icons.battery_alert : Icons.battery_charging_full,
            color: isDeficit ? colors.cautionAccent : colors.success,
            size: 28,
          ),
          const SizedBox(width: RitmoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeficit
                      ? 'کسری خواب: ${RitmoNumber.faHours(balance.abs())}'
                      : 'ذخیرهٔ خواب: ${RitmoNumber.faHours(balance)}',
                  style: RitmoTextStyles.cardTitle(
                    isDeficit ? colors.cautionAccent : colors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDeficit
                      ? 'یک خواب جبرانی کوتاه می‌تواند به بازیابی کمک کند.'
                      : 'خواب کافی ۱۴ روز اخیر ذخیرهٔ خوبی ایجاد کرده است.',
                  style: RitmoTextStyles.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
}
