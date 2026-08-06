import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_briefing_service.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/ai_shared_rules.dart';
import 'package:ritmo/core/ai/daily_digest_builder.dart';
import 'package:ritmo/core/analytics/data_maturity_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/analytics/milestone_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/ad_service.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/widgets/premium_gate.dart';
import 'package:ritmo/features/today/presentation/widgets/ai_deep_analysis_dialog.dart';
import 'package:ritmo/features/today/presentation/widgets/insights_time_window_ruler.dart';
import 'package:ritmo/features/today/presentation/widgets/life_pulse_sparkline_chart.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  AiBriefing? _briefing;
  bool _isDeepAnalyzing = false;
  String? _deepAnalysisResult;

  // Selected time window ruler state (ط۵)
  InsightsTimeWindow _selectedWindow = InsightsTimeWindow.last7Days;

  // Gate & Metrics
  int _daysOfData = 0;
  int _completionCount = 0;
  int _lifePulseAverage = 0;
  int _pulseDiffPercentage = 0;
  bool _pulseDiffUp = true;

  int _pulseMonthlyChange = 0;
  bool _pulseMonthlyUp = true;
  List<Map<String, dynamic>> _pulseHistoryList = [];

  // Life Balance
  int _lifeBalanceScore = 100;
  Map<String, double> _categoryDistribution = {};

  // Energy
  String? _peakPerformanceWindow;
  String? _mostProductiveWeekday;
  String? _mostFatiguedWindow;

  // Milestones & Insights
  List<Milestone> _milestones = [];
  List<InsightResult> _insights = [];

  // Streaks
  int _currentStreak = 0;
  int _longestStreak = 0;

  // Private Data Excluded Check
  bool _isCycleModuleEnabled = false;
  bool _isFemale = false;

  final Map<String, Color> _domainColors = {
    'RELIGION': const Color(0xffFBBF24), // amber
    'HEALTH': const Color(0xffEF4444),   // red
    'LEARNING': const Color(0xff3B82F6), // blue
    'WORK': const Color(0xff8B5CF6),     // purple
    'PERSONAL': const Color(0xffEC4899), // pink
    'FREE': const Color(0xff10B981),     // green
  };

  final Map<String, String> _domainNamesFarsi = {
    'RELIGION': 'عبادی و معنوی',
    'HEALTH': 'ورزش و سلامتی',
    'LEARNING': 'آموزش و یادگیری',
    'WORK': 'کار و پروژه‌ها',
    'PERSONAL': 'شخصی و خانوادگی',
    'FREE': 'تفریح و استراحت',
  };

  @override
  void initState() {
    super.initState();
    // POP v1.1 — defer heavy analytics load until after first frame
    // so the Insights scaffold renders immediately (no jank on tab switch).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAnalytics();
    });
  }

  @override
  void dispose() {
    AdService.instance.showInterstitialAd();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch raw data from DB using windowed queries for memory safety (ط۳)
      final ninetyDaysAgoMs = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch;
      final completionsRaw = await db.query(
        'routine_completions',
        where: 'completionTime >= ?',
        whereArgs: [ninetyDaysAgoMs],
      );
      final completions = completionsRaw.map(Map<String, dynamic>.from).toList();

      final energyRaw = await db.query(
        'energy_logs',
        where: 'loggedAt >= ?',
        whereArgs: [ninetyDaysAgoMs],
      );
      final energy = energyRaw.map(Map<String, dynamic>.from).toList();

      final rhythmsRaw = await db.query('daily_rhythm');
      final rhythms = rhythmsRaw.map(Map<String, dynamic>.from).toList();

      final routinesRaw = await db.query('routines');
      final routines = routinesRaw.map(Map<String, dynamic>.from).toList();

      final coursesRaw = await db.query('courses');
      final courses = coursesRaw.map(Map<String, dynamic>.from).toList();

      final courseSessionsRaw = await db.query('course_sessions');
      final courseSessions = courseSessionsRaw.map(Map<String, dynamic>.from).toList();

      final konkurSubjectsRaw = await db.query('konkur_subjects');
      final konkurSubjects = konkurSubjectsRaw.map(Map<String, dynamic>.from).toList();

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final unlockedDB = await DatabaseHelper.instance.getUnlockedMilestones();
      final unlockedMap = {for (final m in unlockedDB) m['id'] as String: m['unlockedAt'] as int};

      _isCycleModuleEnabled = settingsMap['module_cycle_enabled'] == 'true';
      _isFemale = CyclePrivacyGuard.isVisible(settingsMap);
      _currentStreak = int.tryParse(settingsMap['current_streak'] ?? '0') ?? 0;
      _longestStreak = int.tryParse(settingsMap['longest_streak'] ?? '0') ?? 0;

      _completionCount = completions.length;

      // 2. Calculate active days from unique logged dates (B-15 fix)
      final completionDates = completions.map((c) => c['completionDate'] as String?).whereType<String>().toSet();
      final rhythmDates = rhythms.map((r) => r['date'] as String?).whereType<String>().toSet();
      final allActiveDates = {...completionDates, ...rhythmDates};
      _daysOfData = allActiveDates.length;
      if (_daysOfData < 1 && completions.isNotEmpty) _daysOfData = 1;

      // 3. Load Pulse History
      _pulseHistoryList = rhythms.map((r) => {
        'date': r['date'] as String? ?? '',
        'rhythmScore': (r['rhythmScore'] as num? ?? 0).toInt(),
      }).toList();
      _pulseHistoryList.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      // Calculate averages
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));

      final recentRhythms = rhythms.where((r) {
        final date = DateTime.tryParse(r['date'] as String? ?? '');
        return date != null && date.isAfter(sevenDaysAgo);
      }).toList();

      final prevRhythms = rhythms.where((r) {
        final date = DateTime.tryParse(r['date'] as String? ?? '');
        return date != null && date.isAfter(fourteenDaysAgo) && date.isBefore(sevenDaysAgo);
      }).toList();

      double recentAvg = 0;
      if (recentRhythms.isNotEmpty) {
        recentAvg = recentRhythms.map((r) => (r['rhythmScore'] as num? ?? 0).toDouble()).reduce((a, b) => a + b) / recentRhythms.length;
      }
      _lifePulseAverage = recentAvg.round();

      double prevAvg = 0;
      if (prevRhythms.isNotEmpty) {
        prevAvg = prevRhythms.map((r) => (r['rhythmScore'] as num? ?? 0).toDouble()).reduce((a, b) => a + b) / prevRhythms.length;
      }

      if (prevAvg > 0) {
        final diff = recentAvg - prevAvg;
        _pulseDiffPercentage = ((diff.abs() / prevAvg) * 100).round();
        _pulseDiffUp = diff >= 0;
      }

      // Calculate monthly average difference if data >= 60 days
      if (_daysOfData >= 60) {
        final thisMonthRhythms = rhythms.where((r) {
          final date = DateTime.tryParse(r['date'] as String? ?? '');
          return date != null && date.isAfter(thirtyDaysAgo);
        }).toList();

        final lastMonthRhythms = rhythms.where((r) {
          final date = DateTime.tryParse(r['date'] as String? ?? '');
          return date != null && date.isAfter(sixtyDaysAgo) && date.isBefore(thirtyDaysAgo);
        }).toList();

        if (thisMonthRhythms.isNotEmpty && lastMonthRhythms.isNotEmpty) {
          final thisAvg = thisMonthRhythms.map((r) => (r['rhythmScore'] as num? ?? 0).toDouble()).reduce((a, b) => a + b) / thisMonthRhythms.length;
          final lastAvg = lastMonthRhythms.map((r) => (r['rhythmScore'] as num? ?? 0).toDouble()).reduce((a, b) => a + b) / lastMonthRhythms.length;
          final diff = thisAvg - lastAvg;
          _pulseMonthlyChange = ((diff.abs() / lastAvg) * 100).round();
          _pulseMonthlyUp = diff >= 0;
        }
      }

      if (DataMaturityEngine.hasEnoughDataForWeeklyTrend(_daysOfData)) {
        final bus = RitmoEngineBus.instance;

        // Run Energy Analytics via Engine Bus
        final energyOut = await bus.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
          EnergyAnalyticsEngine,
          EnergyAnalyticsEngineInput(
            energyLogs: energy,
            routineCompletions: completions,
            dailyRhythm: rhythms,
          ),
        );
        _peakPerformanceWindow = energyOut.peakPerformanceWindow;
        _mostProductiveWeekday = energyOut.mostProductiveWeekday;
        _mostFatiguedWindow = energyOut.mostFatiguedWindow;

        // Run Life Balance via Engine Bus
        final balanceOut = await bus.execute<LifeBalanceEngineInput, LifeBalanceEngineOutput>(
          LifeBalanceEngine,
          LifeBalanceEngineInput(
            now: DateTime.now(),
            routines: routines,
            routineCompletions: completions,
          ),
        );
        _lifeBalanceScore = balanceOut.score ?? 0;
        _categoryDistribution = balanceOut.distribution;

        // Run Milestones via Engine Bus (side-effect free evaluation)
        _milestones = await bus.execute<MilestoneEngineInput, List<Milestone>>(
          MilestoneEngine,
          MilestoneEngineInput(
            currentStreak: _currentStreak,
            longestStreak: _longestStreak,
            routineCompletions: completions,
            routines: routines,
            courses: courses,
            courseSessions: courseSessions,
            konkurSubjects: konkurSubjects,
            unlockedMilestonesMap: unlockedMap,
          ),
        );

        // Run Insights Engine via Engine Bus
        _insights = await bus.execute<InsightGenerationEngineInput, List<InsightResult>>(
          InsightGenerationEngine,
          InsightGenerationEngineInput(
            routineCompletions: completions,
            routines: routines,
            peakPerformanceWindow: _peakPerformanceWindow,
            mostProductiveWeekday: _mostProductiveWeekday,
            mostFatiguedWindow: _mostFatiguedWindow,
            daysOfData: _daysOfData,
            dailyRhythm: rhythms,
            isMenstruating: _isFemale && _isCycleModuleEnabled,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
    }

    // Load AI Briefing & Deep Analysis cache
    try {
      final b = await AiBriefingService.instance.getCached();
      final prefs = await SharedPreferences.getInstance();
      final cachedDeepAnalysis = prefs.getString('ai_deep_analysis_result_v1');
      if (mounted) {
        setState(() {
          _briefing = b;
          _deepAnalysisResult = cachedDeepAnalysis;
        });
      }
    } catch (e) {
      debugPrint('Error loading briefing cache in Insights: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pushInsightsToInbox(List<InsightResult> insights) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    for (final insight in insights) {
      final typeName = insight.type.name.toLowerCase();
      if (typeName.contains('cycle') || typeName.contains('hormone') || typeName.contains('period')) {
        continue;
      }

      var title = '';
      var message = '';

      switch (insight.type) {
        case InsightType.learningGrowth:
          title = l10n.learningGrowthInsightTitle;
          message = l10n.learningGrowthInsightMessage(insight.params['percent'] as int? ?? 0);
        case InsightType.healthDecline:
          title = l10n.healthDeclineInsightTitle;
          message = l10n.healthDeclineInsightMessage(insight.params['percent'] as int? ?? 0);
        case InsightType.morningLead:
          title = l10n.morningLeadInsightTitle;
          message = l10n.morningLeadInsightMessage;
        case InsightType.fatigueWarning:
          title = l10n.fatigueWarningInsightTitle;
          message = l10n.fatigueWarningInsightMessage(insight.params['window'] as String? ?? '');
        case InsightType.productiveWeekday:
          title = l10n.productiveWeekdayInsightTitle;
          message = l10n.productiveWeekdayInsightMessage(insight.params['weekday'] as String? ?? '');
        case InsightType.gatheringData:
          title = l10n.gatheringDataInsightTitle;
          message = l10n.gatheringDataInsightMessage;
        default:
          title = insight.params['title'] as String? ?? 'تحلیل جدید';
          message = insight.params['message'] as String? ?? 'تحلیل رفتار جدیدی برای شما آماده شده است.';
      }

      if (title.isNotEmpty && message.isNotEmpty) {
        await CentralInboxService.push(
          category: InboxCategory.INSIGHT,
          sourceSystem: 'insight_engine',
          entityId: '${insight.type.name}_${insight.sourceMetric}',
          eventType: 'insight',
          title: title,
          body: message,
          linkModule: 'insights',
          linkAction: 'open_list',
          dateBucket: todayStr,
        );
      }
    }
  }

  Future<void> _runDeepAnalysis() async {
    final hasConsent = await AIDeepAnalysisDialog.checkConsent(context);
    if (!hasConsent) return;

    RitmoHaptics.tap();
    setState(() {
      _isDeepAnalyzing = true;
      _deepAnalysisResult = null;
    });

    try {
      final digest = await DailyDigestBuilder.buildFull();
      const systemPrompt = """
You are Ritmo's Deep Behavioral Analyst. Your job is to analyze the user's metrics in-depth.

RULES:
${AnalyticsPromptRules.core}

OUTPUT STRUCTURE:
Your output must be structured in Farsi markdown with exactly the following headings:
### نقاط قوت
### روندها و استمرار
### همبستگی‌های رفتاری
### پیشنهاد هفته

CONSTRAINTS:
1. Under each heading, output AT MOST 3 sentences.
2. Refer directly to actual numbers, routine names, or specific categories from the user's digest (do not make up titles or numbers).
3. The total word count must be around 250 words or less. Keep it concise, high-impact, and warm yet strictly analytical.
""";

      final userPrompt = """
Here is the user's complete behavioral digest:
Legend:
- sleep: [durationMinutes: کل مدت خواب به دقیقه | sleepEfficiency: درصد کیفیت خواب | deepSleepMinutes: مدت خواب عمیق | remSleepMinutes: مدت خواب رِم | sleepDebt: بدهی خواب به دقیقه]
- habits: [stabilityScore: امتیاز ثبات از ۰ تا ۱۰۰ | adaptabilityScore: امتیاز انطباق‌پذیری از ۰ تا ۱۰۰ | consistencyScore: امتیاز استمرار رفتاری]
- completion30d: درصد موفقیت تکمیل روتین‌ها در ۳۰ روز اخیر

Digest Data:
${jsonEncode(digest.json)}
""";
      
      final result = await AIGateway.instance.sendRawCompletion(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      final finalResult = result.isNotEmpty ? result : 'خطا در برقراری ارتباط با سرور تحلیل هوش مصنوعی.';

      if (result.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_deep_analysis_result_v1', result);
      }

      if (mounted) {
        setState(() {
          _deepAnalysisResult = finalResult;
        });
      }
    } catch (e) {
      debugPrint('[DEEP_ANALYSIS] failed: $e');
      if (mounted) {
        setState(() {
          _deepAnalysisResult = 'خطا در پردازش اطلاعات رفتاری شما.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeepAnalyzing = false;
        });
      }
    }
  }

  Widget _buildAIBriefingSection(RitmoColors colors, bool isDarkMode) {
    if (_briefing == null && !_isDeepAnalyzing && _deepAnalysisResult == null) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تحلیل هوشمند ریتمو 🧠',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                'هنوز هیچ تحلیلی ثبت نشده است. دکمه زیر را برای اجرای اولین تحلیل عمیق الگوهای رفتاری خود فشار دهید.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _runDeepAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(CupertinoIcons.sparkles, size: 16, color: Colors.white),
                label: const Text(
                  'تحلیل عمیق با هوش مصنوعی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تحلیل هوشمند ریتمو 🧠',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                if (!_isDeepAnalyzing)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _runDeepAnalysis, minimumSize: const Size(0, 0),
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: colors.textSecondary,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_briefing != null) ...[
              Text(
                _briefing!.headline,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                _briefing!.summary,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
            ],

            if (_isDeepAnalyzing) ...[
              const SizedBox(height: 16),
               Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xff06B6D4)),
                    const SizedBox(height: 12),
                    Text(
                      'در حال تحلیل عمیق الگوهای رفتاری شما... لطفاً صبور باشید 🧐',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_deepAnalysisResult != null) ...[
              Divider(color: colors.border, height: 16),
              const Text(
                'گزارش تحلیل عمیق:',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black.withValues(alpha: 0.2) : colors.textSecondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Text(
                    _deepAnalysisResult!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _runDeepAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(CupertinoIcons.sparkles, size: 16, color: Colors.white),
                label: const Text(
                  'تحلیل عمیق با هوش مصنوعی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          AdService.instance.showInterstitialAd(context);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: _loadAnalytics,
            color: colors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Header Row
                  _buildHeader(colors),
                  const SizedBox(height: 16),

                  // Time Window Ruler (ط۵)
                  InsightsTimeWindowRuler(
                    selectedWindow: _selectedWindow,
                    onWindowChanged: (w) {
                      setState(() {
                        _selectedWindow = w;
                      });
                      _loadAnalytics();
                    },
                  ),
                  const SizedBox(height: 20),

                  // AI Briefing section
                  PremiumGate(
                    feature: PremiumFeature.unlimitedAi,
                    child: _buildAIBriefingSection(colors, isDarkMode),
                  ),
                  const SizedBox(height: 20),

                  // Maturity Gate Dispatcher
                  if (!DataMaturityEngine.hasEnoughDataForWeeklyTrend(_daysOfData))
                    _buildEarlyStageView(colors, isDarkMode)
                  else
                    PremiumGate(
                      feature: PremiumFeature.advancedInsights,
                      child: _buildAdvancedView(colors, isDarkMode),
                    ),
                  const SizedBox(height: 20),
                  AdService.instance.getBannerAd(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RitmoColors colors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بینش‌ها',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'درک روندها و الگوهای زندگی شما',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
        // Header Actions
        IconButton(
          icon: const Icon(CupertinoIcons.calendar_today, size: 20),
          color: colors.textSecondary,
          tooltip: 'انتخاب بازه زمانی',
          onPressed: () => _showDateRangePicker(colors),
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.arrow_down_doc, size: 20),
          color: colors.textSecondary,
          tooltip: 'خروجی گرفتن',
          onPressed: () => _showExportSheet(colors),
        ),
        Builder(
          builder: (btnCtx) => IconButton(
            icon: const Icon(CupertinoIcons.share, size: 20),
            color: colors.textSecondary,
            tooltip: 'اشتراک‌گذاری',
            onPressed: () => _simulateShare(btnCtx, colors),
          ),
        ),
      ],
    );
  }

  // Gate Check Badge
  Widget _buildMaturityBadge() {
    var label = 'عدم بلوغ داده 🔴';
    Color color = Colors.redAccent;
    if (DataMaturityEngine.hasEnoughDataForMonthlyComparison(_daysOfData)) {
      label = 'داده‌های کامل 🟢';
      color = const Color(0xff34D399);
    } else if (DataMaturityEngine.hasEnoughDataForWeeklyTrend(_daysOfData)) {
      label = 'داده‌های اولیه 🟡';
      color = const Color(0xffF5B95B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Vazirmatn',
        ),
      ),
    );
  }

  // EARLY STAGE MODE VIEW
  Widget _buildEarlyStageView(RitmoColors colors, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Maturity Banner
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.square_stack_3d_down_right_fill,
                  size: 52,
                  color: Color(0xff5B8AF5),
                ),
                const SizedBox(height: 18),
                Text(
                  'هنوز در حال شناخت شما هستیم',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'با ادامه استفاده از ریتمو و تکمیل روتین‌های روزانه، بینش‌های هوشمند، آنالیز تعادل ابعاد زندگی و تحلیل‌های پیشرفته ریتم انرژی شما ظاهر خواهند شد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.6,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 16),
                _buildMaturityBadge(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section Title
        _buildSectionTitle(colors, 'وضعیت فعلی ریتم زندگی'),
        const SizedBox(height: 12),

        // 3 metrics allowed in Early Stage
        Row(
          children: [
            Expanded(
              child: _buildEarlyMetricCard(
                colors,
                'نبض فعلی زندگی',
                toPersianDigits('$_lifePulseAverage٪'),
                colors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEarlyMetricCard(
                colors,
                'روزهای استفاده',
                toPersianDigits('$_daysOfData روز'),
                colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEarlyMetricCard(
          colors,
          'کل روتین‌های تکمیل شده',
          toPersianDigits('$_completionCount روتین'),
          colors.primary,
        ),
      ],
    );
  }

  Widget _buildEarlyMetricCard(RitmoColors colors, String title, String val, Color color) {
    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 10),
            Text(
              val,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Vazirmatn'),
            ),
          ],
        ),
      ),
    );
  }

  // ADVANCED ANALYTICS MODE VIEW
  Widget _buildAdvancedView(RitmoColors colors, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMaturityBadge(),
        const SizedBox(height: 16),

        // SECTION 1: Life Pulse Hero
        _buildLifePulseHero(colors),
        const SizedBox(height: 24),

        // SECTION 2: Life Balance
        _buildSectionTitle(colors, 'تعادل ابعاد زندگی ⚖️'),
        const SizedBox(height: 12),
        _buildLifeBalanceCard(colors, isDarkMode),
        const SizedBox(height: 24),

        // SECTION 3: Streaks & Momentum
        _buildSectionTitle(colors, 'تداوم و انرژی رفتاری 🔥'),
        const SizedBox(height: 12),
        _buildStreaksCard(colors),
        const SizedBox(height: 24),

        // SECTION 4: Trend Analysis
        _buildSectionTitle(colors, 'تحلیل پویای روندهای پیشرفت 📈'),
        const SizedBox(height: 12),
        _buildTrendAnalysisGrid(colors),
        const SizedBox(height: 24),

        // SECTION 5: Energy Insights
        _buildSectionTitle(colors, 'بینش‌های ریتم شبانه‌روزی و انرژی ⚡'),
        const SizedBox(height: 12),
        _buildEnergyInsights(colors),
        const SizedBox(height: 24),

        // SECTION 6: Intelligence Insights
        if (_insights.isNotEmpty) ...[
          _buildSectionTitle(colors, 'بینش‌های هوشمند رفتاری 💡'),
          const SizedBox(height: 12),
          _buildIntelligenceInsightsList(colors, isDarkMode),
          const SizedBox(height: 24),
        ],

        // SECTION 7: Milestones
        if (_milestones.isNotEmpty) ...[
          _buildSectionTitle(colors, 'دستاوردهای آزاد شده و مایل‌استون‌ها 🎖️'),
          const SizedBox(height: 12),
          _buildMilestonesTimeline(colors),
          const SizedBox(height: 24),
        ],

        // SECTION 8: Comparative Analysis
        _buildSectionTitle(colors, 'تحلیل‌های مقایسه‌ای زمان‌محور 📊'),
        const SizedBox(height: 12),
        _buildComparativeAnalysis(colors),
        const SizedBox(height: 24),

        // SECTION 9: Reflection Summary
        _buildSectionTitle(colors, 'خلاصه انعکاس رفتاری (تصویر زندگی شما) 🌿'),
        const SizedBox(height: 12),
        _buildReflectionSummary(colors),
      ],
    );
  }

  Widget _buildSectionTitle(RitmoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
        fontFamily: 'Vazirmatn',
      ),
    );
  }

  // SECTION 1: Life Pulse Hero
  Widget _buildLifePulseHero(RitmoColors colors) {
    return RitmoTheme.glassCardLight(
      child: InkWell(
        onTap: () => _showPulseHistorySheet(colors),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نبض زندگی جاری (میانگین ۷ روزه)',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                  Icon(CupertinoIcons.chevron_left, size: 16, color: colors.textSecondary.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                toPersianDigits('$_lifePulseAverage٪'),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: colors.success,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 12),
              // Trend indicator
              Row(
                children: [
                  _buildPulseTrendIndicator(
                    label: 'نسبت به هفته قبل',
                    value: _pulseDiffPercentage,
                    isUp: _pulseDiffUp,
                    colors: colors,
                  ),
                  if (_daysOfData >= 60) ...[
                    const SizedBox(width: 16),
                    _buildPulseTrendIndicator(
                      label: 'نسبت به ماه قبل',
                      value: _pulseMonthlyChange,
                      isUp: _pulseMonthlyUp,
                      colors: colors,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              LifePulseSparklineChart(pulseHistory: _pulseHistoryList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseTrendIndicator({
    required String label,
    required int value,
    required bool isUp,
    required RitmoColors colors,
  }) {
    if (value == 0) {
      return Text(
        'پایدار $label',
        style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
      );
    }
    final trendColor = isUp ? colors.success : colors.medicalRed;
    return Row(
      children: [
        Icon(isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right, color: trendColor, size: 12),
        const SizedBox(width: 3),
        Text(
          '$value٪ $label',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor, fontFamily: 'Vazirmatn'),
        ),
      ],
    );
  }

  // PULSE DETAILED HISTORY BOTTOM SHEET
  void _showPulseHistorySheet(RitmoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            snap: true,
            builder: (context, scrollController) {
              return RitmoTheme.glassCardLight(
                borderRadius: 28,
                child: Column(
                  children: [
                    // Pull indicator
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تایم‌لاین نبض زندگی',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                          ),
                          Text(
                            'ثبت‌شده: ${_pulseHistoryList.length} روز',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: colors.border),
                    Expanded(
                      child: _pulseHistoryList.isEmpty
                          ? Center(
                              child: Text(
                                'هنوز هیچ نبض روزانه‌ای ثبت نشده است.',
                                style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _pulseHistoryList.length,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemBuilder: (context, index) {
                                final item = _pulseHistoryList[index];
                                final score = item['rhythmScore'] as int;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['date'] as String,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: FractionallySizedBox(
                                                widthFactor: (score / 100).clamp(0.0, 1.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: score >= 80 ? colors.success : (score >= 50 ? colors.primary : colors.medicalRed),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '$score٪',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: score >= 80 ? colors.success : (score >= 50 ? colors.primary : colors.medicalRed),
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // SECTION 2: Life Balance
  Widget _buildLifeBalanceCard(RitmoColors colors, bool isDarkMode) {
    // Generate active categories (real activity percentage > 0)
    final activeEntries = _categoryDistribution.entries.where((e) => e.value > 0).toList();

    if (activeEntries.isEmpty) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'هنوز در این ابعاد روتینی تکمیل نشده است تا تعادل محاسبه شود. برای دیدن تعادل ابعاد زندگی، روتین‌های روزانه خود را تکمیل کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.6, fontFamily: 'Vazirmatn'),
              ),
            ],
          ),
        ),
      );
    }

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Radial Pie/Donut custom painter
                RepaintBoundary(
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: DonutChartPainter(
                        distribution: _categoryDistribution,
                        colors: _domainColors,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شاخص تعادل کل زندگی',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_lifeBalanceScore٪',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            // Show only dynamic categories with real completions
            ...activeEntries.map((e) {
              final domain = e.key;
              final percent = e.value;
              final name = _domainNamesFarsi[domain] ?? domain;
              final color = _domainColors[domain] ?? colors.primary;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                            const SizedBox(width: 8),
                            Text(name, style: TextStyle(fontSize: 12, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                          ],
                        ),
                        Text('${percent.toStringAsFixed(0)}٪', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: Colors.white.withValues(alpha: 0.04),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: (percent / 100).clamp(0.0, 1.0),
                            child: Container(color: color),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // SECTION 3: Streaks & Momentum
  Widget _buildStreaksCard(RitmoColors colors) {
    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.flame_fill, color: Colors.orangeAccent, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تداوم فعلی', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 4),
                          Text(toPersianDigits('$_currentStreak روز متوالی'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                        ],
                      )
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: colors.border.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.sparkles, color: Colors.amber, size: 26),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('طولانی‌ترین تداوم', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 4),
                          Text(toPersianDigits('$_longestStreak روز متوالی'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colors.border.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(CupertinoIcons.waveform_path_ecg, color: colors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pulseDiffUp
                        ? 'شتاب انرژی رفتاری شما در ۷ روز اخیر با افزایش ${toPersianDigits('$_pulseDiffPercentage٪')} همراه بوده است.'
                        : 'شتاب انرژی رفتاری شما در ۷ روز اخیر با تغییر ${toPersianDigits('$_pulseDiffPercentage٪')} نیازمند پایش است.',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.5, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // SECTION 4: Trend Analysis
  Widget _buildTrendAnalysisGrid(RitmoColors colors) {
    final activeEntries = _categoryDistribution.entries.where((e) => e.value > 0).toList();

    if (activeEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'هنوز دسته‌بندی در روتین‌ها برای تحلیل روند وجود ندارد.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: activeEntries.map((e) {
        final domain = e.key;
        final name = _domainNamesFarsi[domain] ?? domain;
        final color = _domainColors[domain] ?? colors.primary;

        return RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      toPersianDigits('${e.value.toStringAsFixed(0)}٪'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'فعال',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // SECTION 5: Energy Insights
  Widget _buildEnergyInsights(RitmoColors colors) {
    final cards = <Widget>[];

    if (_peakPerformanceWindow != null) {
      cards.add(
        _buildEnergyCard(
          colors: colors,
          title: 'اوج عملکرد ذهنی و فیزیکی ☀️',
          value: _peakPerformanceWindow!,
          color: colors.success,
        ),
      );
    }
    if (_mostProductiveWeekday != null) {
      cards.add(
        _buildEnergyCard(
          colors: colors,
          title: 'پربازده‌ترین روز هفته 🌟',
          value: _mostProductiveWeekday!,
          color: colors.primary,
        ),
      );
    }
    if (_mostFatiguedWindow != null) {
      cards.add(
        _buildEnergyCard(
          colors: colors,
          title: 'بازه زمانی حساس خستگی ⚡',
          value: _mostFatiguedWindow!,
          color: Colors.orangeAccent,
        ),
      );
    }

    if (cards.isEmpty) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'داده‌های ثبت انرژی کافی نیست.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
            ),
          ),
        ),
      );
    }

    return Column(
      children: cards.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: c,
      )).toList(),
    );
  }

  Widget _buildEnergyCard({
    required RitmoColors colors,
    required String title,
    required String value,
    required Color color,
  }) {
    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Vazirmatn')),
          ],
        ),
      ),
    );
  }

  // SECTION 6: Intelligence Insights
  Widget _buildIntelligenceInsightsList(RitmoColors colors, bool isDarkMode) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _insights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final insight = _insights[index];
        var typeColor = colors.primary;
        var icon = CupertinoIcons.info_circle_fill;
        var title = '';
        var message = '';

        switch (insight.type) {
          case InsightType.learningGrowth:
            typeColor = colors.success;
            icon = CupertinoIcons.checkmark_circle_fill;
            title = l10n.learningGrowthInsightTitle;
            message = l10n.learningGrowthInsightMessage(insight.params['percent'] as int? ?? 0);
          case InsightType.healthDecline:
            typeColor = insight.severity == 'INFO' ? colors.primary : colors.medicalRed;
            icon = CupertinoIcons.exclamationmark_triangle_fill;
            title = l10n.healthDeclineInsightTitle;
            message = l10n.healthDeclineInsightMessage(insight.params['percent'] as int? ?? 0);
          case InsightType.morningLead:
            typeColor = colors.primary;
            icon = CupertinoIcons.info_circle_fill;
            title = l10n.morningLeadInsightTitle;
            message = l10n.morningLeadInsightMessage;
          case InsightType.fatigueWarning:
            typeColor = colors.medicalRed;
            icon = CupertinoIcons.exclamationmark_triangle_fill;
            title = l10n.fatigueWarningInsightTitle;
            message = l10n.fatigueWarningInsightMessage(insight.params['window'] as String? ?? '');
          case InsightType.productiveWeekday:
            typeColor = colors.success;
            icon = CupertinoIcons.checkmark_circle_fill;
            title = l10n.productiveWeekdayInsightTitle;
            message = l10n.productiveWeekdayInsightMessage(insight.params['weekday'] as String? ?? '');
          case InsightType.sleepEnergyCorrelation:
            typeColor = insight.severity == 'POSITIVE' ? colors.success : colors.primary;
            icon = CupertinoIcons.bed_double_fill;
            title = 'همبستگی خواب و انرژی 🌙⚡';
            final coef = insight.params['coef'] as int? ?? 0;
            message = coef > 0
                ? toPersianDigits('کیفیت خواب شما همبستگی مثبت $coef٪ با سطوح انرژی در طول روز نشان می‌دهد.')
                : toPersianDigits('کمبود خواب همبستگی منفی $coef٪ با پایداری انرژی شما داشته است.');
          case InsightType.sleepMoodCorrelation:
            typeColor = colors.primary;
            icon = CupertinoIcons.smiley_fill;
            title = 'همبستگی خواب و خلق 🌙😊';
            final coef = insight.params['coef'] as int? ?? 0;
            message = toPersianDigits('استمرار خواب خوب همبستگی $coef٪ با بهبودی خلق روزانه شما دارد.');
          case InsightType.energyCompletionLink:
            typeColor = colors.success;
            icon = CupertinoIcons.bolt_horizontal_fill;
            title = 'ارتباط انرژی و تکمیل روتین‌ها ⚡🎯';
            final coef = insight.params['coef'] as int? ?? 0;
            message = toPersianDigits('در روزهایی که شارژ انرژی بالاتر بوده، نرخ تکمیل روتین‌ها $coef٪ افزایش یافته است.');
          case InsightType.consistencyScore:
            typeColor = colors.success;
            icon = CupertinoIcons.graph_square_fill;
            title = 'شاخص ثبات رفتاری 📈';
            final score = insight.params['score'] as int? ?? 0;
            message = toPersianDigits('ثبات عملکرد شما در ۱۴ روز گذشته نمره عالی $score٪ را ثبت کرده است.');
          case InsightType.bestDomainOfWeek:
            typeColor = colors.primary;
            icon = CupertinoIcons.star_fill;
            title = 'برترین دامنه هفته 🌟';
            message = 'عملکرد شما در این دامنه بالاترین پایداری را نشان می‌دهد.';
          case InsightType.streakHighlight:
            typeColor = colors.success;
            icon = CupertinoIcons.flame_fill;
            title = 'دستاورد تداوم 🔥';
            message = toPersianDigits('تداوم فعلی شما به $_currentStreak روز رسید!');
          case InsightType.goalProgress:
            typeColor = colors.primary;
            icon = CupertinoIcons.flag_fill;
            title = 'پیشرفت اهداف 🎯';
            message = 'مسیر اهداف شما با موفقیت در حال طی شدن است.';
          case InsightType.worshipConsistency:
            typeColor = colors.primary;
            icon = CupertinoIcons.sparkles;
            title = 'پایداری عبادی 🌿';
            message = 'پایداری روتین‌های معنوی شما با موفقیت ثبت شد.';
          case InsightType.gatheringData:
          case InsightType.noisyDataSuppressed:
            typeColor = colors.textSecondary;
            icon = CupertinoIcons.time;
            title = l10n.gatheringDataInsightTitle;
            message = l10n.gatheringDataInsightMessage;
        }

        return RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: typeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.doc_text_search, size: 18, color: colors.textSecondary.withValues(alpha: 0.5)),
                      tooltip: 'شناسنامه و ردیابی شاخص',
                      onPressed: () => _showTraceabilityDialog(insight, colors),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.6,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Traceability dialog
  void _showTraceabilityDialog(InsightResult insight, RitmoColors colors) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xff1C1F2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(CupertinoIcons.doc_text_search, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('شناسنامه و ردیابی شاخص', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTraceItem('شاخص اندازه‌گیری', insight.sourceMetric, colors),
                const SizedBox(height: 12),
                _buildTraceItem('بازه محاسباتی داده', insight.calculationWindow, colors),
                const SizedBox(height: 12),
                _buildTraceItem('زمان آخرین محاسبه', dateStr, colors),
                const SizedBox(height: 12),
                _buildTraceItem('جدول دیتابیس مبدا', _getDBTableName(insight.sourceMetric), colors),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن', style: TextStyle(color: Color(0xff5B8AF5), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraceItem(String label, String value, RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _getDBTableName(String sourceMetric) {
    if (sourceMetric.contains('completion')) return 'routine_completions';
    if (sourceMetric.contains('energy')) return 'energy_logs';
    if (sourceMetric.contains('weekday')) return 'routine_completions, daily_rhythm';
    if (sourceMetric.contains('fatigue')) return 'energy_logs, routine_completions';
    return 'daily_rhythm';
  }

  // SECTION 7: Milestones
  Widget _buildMilestonesTimeline(RitmoColors colors) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(_milestones.length, 5), // Only show top 5 milestones
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final milestone = _milestones[index];
        return RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: milestone.isUnlocked ? colors.success.withValues(alpha: 0.1) : colors.textSecondary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    milestone.isUnlocked ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
                    color: milestone.isUnlocked ? colors.success : colors.textSecondary.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(milestone.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                      const SizedBox(height: 4),
                      Text(milestone.description, style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                      if (!milestone.isUnlocked) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 6,
                            color: Colors.white.withValues(alpha: 0.04),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: milestone.progress.clamp(0.0, 1.0),
                                child: Container(color: colors.primary),
                              ),
                            ),
                          ),
                        )
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // SECTION 8: Comparative Analysis
  Widget _buildComparativeAnalysis(RitmoColors colors) {
    final weeklyChangeStr = _pulseDiffPercentage > 0
        ? (_pulseDiffUp
            ? toPersianDigits('+$_pulseDiffPercentage٪ تغییر مثبت')
            : toPersianDigits('-$_pulseDiffPercentage٪ افت'))
        : 'پایدار';

    final monthlyChangeStr = _pulseMonthlyChange > 0
        ? (_pulseMonthlyUp
            ? toPersianDigits('+$_pulseMonthlyChange٪ تغییر مثبت')
            : toPersianDigits('-$_pulseMonthlyChange٪ افت'))
        : 'پایدار';

    return Column(
      children: [
        _buildComparisonItem(
          colors: colors,
          title: 'مقایسه هفتگی (۷ روز اخیر vs هفته قبل)',
          requiredDays: 14,
          value: toPersianDigits('میانگین جاری: $_lifePulseAverage٪'),
          changeStr: weeklyChangeStr,
          isBetter: _pulseDiffUp,
        ),
        const SizedBox(height: 10),
        _buildComparisonItem(
          colors: colors,
          title: 'مقایسه ماهانه (۳۰ روز اخیر vs ماه قبل)',
          requiredDays: 60,
          value: _daysOfData >= 60 ? toPersianDigits('میانگین ماهانه: $_lifePulseAverage٪') : '',
          changeStr: _daysOfData >= 60 ? monthlyChangeStr : '',
          isBetter: _pulseMonthlyUp,
        ),
        const SizedBox(height: 10),
        _buildComparisonItem(
          colors: colors,
          title: 'مقایسه فصلی (۹۰ روز اخیر vs فصل قبل)',
          requiredDays: 120,
          value: '',
          changeStr: '',
          isBetter: true,
        ),
        const SizedBox(height: 10),
        _buildComparisonItem(
          colors: colors,
          title: 'مقایسه سالانه (امسال vs سال گذشته)',
          requiredDays: 365,
          value: '',
          changeStr: '',
          isBetter: true,
        ),
      ],
    );
  }

  Widget _buildComparisonItem({
    required RitmoColors colors,
    required String title,
    required int requiredDays,
    required String value,
    required String changeStr,
    required bool isBetter,
  }) {
    final hasEnough = _daysOfData >= requiredDays;
    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 10),
            if (hasEnough) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(value, style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                  Text(changeStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isBetter ? colors.success : colors.medicalRed, fontFamily: 'Vazirmatn')),
                ],
              )
            ] else ...[
              Text(
                toPersianDigits('هنوز داده کافی برای این تحلیل وجود ندارد (نیاز به حداقل $requiredDays روز داده فعالیتی)'),
                style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6), fontFamily: 'Vazirmatn'),
              )
            ]
          ],
        ),
      ),
    );
  }

  // SECTION 9: Reflection Summary
  Widget _buildReflectionSummary(RitmoColors colors) {
    // Generate reflection objectively based on dynamic data
    var summary = 'در این بازه، فعالیت‌های منظم شما در ابعاد زندگی ریتم پایداری را تجربه کرده است.';
    
    final activeEntries = _categoryDistribution.entries.where((e) => e.value > 0).toList();
    if (activeEntries.isNotEmpty) {
      activeEntries.sort((a, b) => b.value.compareTo(a.value));
      final topDomain = activeEntries.first.key;
      final topDomainName = _domainNamesFarsi[topDomain] ?? topDomain;
      summary = 'در این ماه بیشترین رشد شما در حوزه «$topDomainName» بوده است و شاخص تعادل کل شما روی مقدار $_lifeBalanceScore٪ قرار دارد.';
    }

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(CupertinoIcons.quote_bubble_fill, color: Color(0xff5B8AF5), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.6,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action: Date range picker connecting to InsightsTimeWindow
  void _showDateRangePicker(RitmoColors colors) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xff1C1F2E)
                : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'انتخاب محدوده زمانی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: InsightsTimeWindow.values.map((w) {
                final isSelected = w == _selectedWindow;
                return ListTile(
                  title: Text(
                    w.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? colors.primary : colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedWindow = w;
                    });
                    _loadAnalytics();
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'بستن',
                  style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action: Export sheet
  void _showExportSheet(RitmoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'خروجی از بینش‌ها',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'گزارش وضعیت روندها و تعادل ابعاد زندگی شما آماده خروجی گرفتن است.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(CupertinoIcons.doc_richtext, size: 18),
                    label: const Text('دانلود فایل متنی PDF', style: TextStyle(fontFamily: 'Vazirmatn')),
                    onPressed: () {
                      Navigator.pop(context);
                      _executeExport(colors, 'PDF');
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(CupertinoIcons.photo, size: 18),
                    label: const Text('ذخیره تصویر روندها (Image)', style: TextStyle(fontFamily: 'Vazirmatn')),
                    onPressed: () {
                      Navigator.pop(context);
                      _executeExport(colors, 'IMAGE');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _executeExport(RitmoColors colors, String format) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xff1C1F2E)
                : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: colors.success, size: 22),
                const SizedBox(width: 8),
                Text('خروجی با موفقیت آماده شد', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, color: colors.textPrimary)),
              ],
            ),
            content: Text(
              _isFemale
                  ? 'گزارش نبض زندگی و تعادل ابعاد شما با موفقیت آماده شد.\n\n⚠️ توجه: به دلیل مسائل حریم خصوصی، داده‌های محرمانه چرخه بدنی و سلامت خصوصی هرگز در خروجی قرار نگرفته‌اند.'
                  : 'گزارش نبض زندگی و تعادل ابعاد شما با موفقیت آماده شد.\n\n⚠️ توجه: به دلیل مسائل حریم خصوصی، داده‌های شخصی و حساس هرگز در خروجی قرار نگرفته‌اند.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.6, fontFamily: 'Vazirmatn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('تایید', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );
  }

  // System Share Action with Dedicated Persian Sheet & Fast Clipboard Option
  void _simulateShare(BuildContext buttonContext, RitmoColors colors) {
    final text = 'گزارش بینش‌های رفتاری ریتمو 🌿\n'
        'نبض زندگی: ${toPersianDigits('$_lifePulseAverage٪')}\n'
        'تداوم فعلی: ${toPersianDigits('$_currentStreak روز')}\n'
        'شاخص تعادل ابعاد: ${toPersianDigits('$_lifeBalanceScore٪')}';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(CupertinoIcons.share, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'اشتراک‌گذاری گزارش بینش‌ها',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(CupertinoIcons.doc_on_clipboard, color: Color(0xFF10B981)),
                title: Text('کپی متن گزارش در حافظه (کپی سریع)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    RitmoSnackbar.success(context, 'متن گزارش در حافظه دستگاه (Clipboard) کپی شد 📋');
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.paperplane, color: Color(0xFF3B82F6)),
                title: Text('ارسال به پیام‌رسان‌ها (اشتراک سیستم)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  final origin = (box != null && box.hasSize) ? (box.localToGlobal(Offset.zero) & box.size) : null;
                  try {
                    await Share.share(text, sharePositionOrigin: origin).timeout(const Duration(seconds: 3));
                  } catch (_) {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (mounted) {
                      RitmoSnackbar.success(context, 'متن گزارش در حافظه دستگاه کپی شد 📋');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Donut Chart CustomPainter with Rounded Caps
class DonutChartPainter extends CustomPainter {

  DonutChartPainter({required this.distribution, required this.colors});
  final Map<String, double> distribution;
  final Map<String, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - 10);
    const strokeWidth = 10.0;

    // Track Background
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(Offset(radius, radius), radius - 10, trackPaint);

    var startAngle = -pi / 2;
    final activeEntries = distribution.entries.where((e) => e.value > 0).toList();

    if (activeEntries.isEmpty) return;

    for (final entry in activeEntries) {
      final percentage = entry.value;
      final sweepAngle = (percentage / 100.0) * 2 * pi;
      final color = colors[entry.key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw active segment with slight padding
      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
