import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/logic/workout_suggester.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';
import 'package:ritmo/features/sports/presentation/ai_coach_chat_screen.dart';
import 'package:ritmo/features/sports/presentation/progress_screen.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_ai_banner.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_cant_today_sheet.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_continuity_bar.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_quick_log_sheet.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_recovery_card.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_setup_card.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_split_editor.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_today_workout_card.dart';
import 'package:ritmo/features/sports/presentation/workout_session_screen.dart';
import 'package:sqflite/sqflite.dart';

class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  static const _primaryBg = Color(0xff091410);
  static const _accent    = Color(0xff00F5A0);

  bool _isLoading = true;

  // Setup
  bool _isSetupDone = false;

  // Today
  TodayWorkoutSuggestion? _todaySuggestion;
  bool _isTodayLogged = false;

  // Stats
  int _weekSessions   = 0;
  int _weekMinutes    = 0;
  int _currentStreak  = 0;
  List<bool> _last7DaysContinuity = List.filled(7, false);

  // Split
  Map<int, SplitDay> _split = {};

  // Recovery
  bool _recoveryLogged = false;
  int  _recSoreness    = 1;
  int  _recFatigue     = 1;
  int  _recHydration   = 2;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      await Future.wait([
        _loadSetup(db),
        _loadStats(db),
        _loadRecovery(db),
      ]);
      if (_isSetupDone) {
        await _loadTodaySuggestion(db);
      }
    } catch (e) {
      debugPrint('SportsScreen _loadAll error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSetup(Database db) async {
    _isSetupDone = await WorkoutSuggester.isSetupDone(db);
    _split = await WorkoutSuggester.readSplit(db);
  }

  Future<void> _loadTodaySuggestion(Database db) async {
    _todaySuggestion  = await WorkoutSuggester.buildToday(db);
    _isTodayLogged    = await WorkoutSuggester.isTodayLogged(db);
  }

  Future<void> _loadStats(Database db) async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)); // شروع هفته (دوشنبه)
      final startMs = start.millisecondsSinceEpoch;

      final rows = await db.query('workout_logs',
          where: 'loggedAt >= ?', whereArgs: [startMs]);
      _weekSessions = rows.length;
      _weekMinutes  = rows.fold(0,
          (s, r) => s + ((r['durationMinutes'] as int?) ?? 0));

      // streak ساده: روزهای متوالی با تمرین
      var streak = 0;
      var last7 = List<bool>.filled(7, false);
      for (var i = 0; i < 30; i++) {
        final d   = DateTime(now.year, now.month, now.day - i);
        final dMs = d.millisecondsSinceEpoch;
        final nMs = d.add(const Duration(days: 1)).millisecondsSinceEpoch;
        final logged = await db.query('workout_logs',
            where: 'loggedAt >= ? AND loggedAt < ?',
            whereArgs: [dMs, nMs], limit: 1);
        
        if (i < 7) {
          last7[6 - i] = logged.isNotEmpty;
        }

        if (logged.isNotEmpty) {
          streak++;
        } else if (i > 0) {
          break; // break early for streak, but wait, we need last 7 days!
        }
      }
      
      // We shouldn't break if i < 7 because we need the full 7-day history.
      // Let's refactor the streak logic:
      streak = 0;
      last7 = List.filled(7, false);
      var streakBroken = false;
      for (var i = 0; i < 30; i++) {
        final d   = DateTime(now.year, now.month, now.day - i);
        final dMs = d.millisecondsSinceEpoch;
        final nMs = d.add(const Duration(days: 1)).millisecondsSinceEpoch;
        final logged = await db.query('workout_logs',
            where: 'loggedAt >= ? AND loggedAt < ?',
            whereArgs: [dMs, nMs], limit: 1);
        
        if (i < 7) {
          last7[6 - i] = logged.isNotEmpty;
        }

        if (!streakBroken) {
          if (logged.isNotEmpty) {
            streak++;
          } else if (i > 0) {
            streakBroken = true;
          }
        }
      }
      
      _currentStreak = streak;
      _last7DaysContinuity = last7;
    } catch (_) {}
  }

  Future<void> _loadRecovery(Database db) async {
    try {
      final today  = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final rows = await db.query('workout_recovery_logs',
          where: 'date = ?', whereArgs: [dateKey],
          orderBy: 'loggedAt DESC', limit: 1);
      if (rows.isNotEmpty) {
        _recoveryLogged = true;
        _recSoreness  = rows.first['soreness']  as int? ?? 1;
        _recFatigue   = rows.first['fatigue']   as int? ?? 1;
        _recHydration = rows.first['hydration'] as int? ?? 2;
      } else {
        _recoveryLogged = false;
      }
    } catch (_) {}
  }

  void _onSetupDone() {
    RitmoHaptics.success();
    _loadAll();
  }

  void _openLogSheet() {
    if (_todaySuggestion != null && _todaySuggestion!.groups.contains(MuscleGroup.rest)) {
      // اگر پیشنهاد استراحته، همون شیت رو باز کن
      showSportsQuickLogSheet(
        context,
        presetTier: _todaySuggestion?.suggestedTier,
        presetGroups: _todaySuggestion?.groups,
        onLogged: () {
          RitmoHaptics.success();
          _loadAll();
        },
      );
    } else {
      // وارد صفحه نشست تمرین بشو
      RitmoHaptics.tap();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WorkoutSessionScreen(
            dayId: 'today',
            title: 'تمرین امروز',
            initialExercises: [], // این باید از دیتابیس (plan) پر بشه
          ),
        ),
      ).then((_) {
        // پس از برگشت، رفرش کن
        _loadAll();
      });
    }
  }

  void _openCantToday() {
    showSportsCantTodaySheet(
      context,
      onReasonSelected: (reason) {
        RitmoHaptics.success();
        // TODO: Save missed reason or adjust plan
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دلیل ثبت شد: $reason')));
      },
    );
  }

  void _goToSplit() {
    // اسکرول به بخش برنامه — چون همه در یه صفحه‌ی scrollable هستن
    _splitKey.currentContext?.let((ctx) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
    });
  }

  final GlobalKey _splitKey = GlobalKey();

  Future<void> _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0d1a15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ریست همه تنظیمات ورزش؟',
            style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: 15)),
        content: const Text(
            'برنامه هفتگی پاک می‌شه و دوباره از اول تنظیم می‌کنی.\nتاریخچه تمرینات حفظ می‌مونه.',
            style: TextStyle(color: Colors.white54, fontFamily: 'Vazirmatn', fontSize: 12.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف',
                  style: TextStyle(color: Colors.white38, fontFamily: 'Vazirmatn'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ریست',
                  style: TextStyle(color: Colors.red, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm ?? false) {
      final db = await DatabaseHelper.instance.database;
      await WorkoutSuggester.resetSetup(db);
      RitmoHaptics.warning();
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.right_chevron, color: Colors.white),
          onPressed: () { RitmoHaptics.tap(); Navigator.pop(context); },
        ),
        title: const Text('ریتمو ورزش',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16,
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_isSetupDone)
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.white38, size: 20),
              tooltip: 'ریست تنظیمات',
              onPressed: _resetAll,
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : RefreshIndicator(
                color: _accent,
                backgroundColor: const Color(0xff0d1a15),
                onRefresh: _loadAll,
                child: _isSetupDone ? _buildMainContent() : _buildSetupContent(),
              ),
      ),
    );
  }

  // ─── صفحه اول راه‌اندازی ───────────────────────────────────────
  Widget _buildSetupContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('خوش اومدی! 👋',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white, fontFamily: 'Vazirmatn')),
              SizedBox(height: 4),
              Text('بریم برنامه ورزشیت رو بسازیم',
                  style: TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn')),
            ]),
          ),
          const SizedBox(height: 16),
          SportsSetupCard(onDone: _onSetupDone),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── صفحه اصلی ─────────────────────────────────────────────────
  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ۱. هدر — سلام + آمار سریع
          _buildHeader(),

          // ۲. کارت «امروز چی کار کنم؟»
          if (_todaySuggestion != null)
            SportsTodayWorkoutCard(
              suggestion: _todaySuggestion!,
              isTodayLogged: _isTodayLogged,
              onLog: _openLogSheet,
              onEditSplit: _goToSplit,
              onCantToday: _openCantToday,
            ),

          // تداوم هفتگی (قابل کلیک برای ورود به صفحه پیشرفت)
          GestureDetector(
            onTap: () {
              RitmoHaptics.tap();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgressScreen(
                    currentStreak: _currentStreak,
                    last7DaysLogged: _last7DaysContinuity,
                    recentFeelingsEmojis: const ['🙂', '😌', '🙂'], // دیتای موکاپ
                    readyToProgressExercises: const ['پرس سینه دمبل', 'اسکات'], // دیتای موکاپ
                  ),
                ),
              );
            },
            child: SportsContinuityBar(last7DaysLogged: _last7DaysContinuity),
          ),

          // بنر مربی هوش مصنوعی
          SportsAiBanner(
            onOpenChat: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiCoachChatScreen()));
            },
          ),

          // ۳. آمار هفته
          _buildWeekStats(),

          // ۴. برنامه هفتگی
          KeyedSubtree(
            key: _splitKey,
            child: SportsSplitEditor(
              split: _split,
              onChanged: _loadAll,
            ),
          ),

          // ۵. خوداظهاری ریکاوری
          SportsRecoveryCard(
            alreadyLogged: _recoveryLogged,
            initialSoreness: _recSoreness,
            initialFatigue: _recFatigue,
            initialHydration: _recHydration,
            onSaved: _loadAll,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final weekday = DateTime.now().weekday;
    const dayNames = {1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه',
        5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه'};

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${dayNames[weekday]} • ریتمو ورزش',
                style: const TextStyle(fontSize: 12.5, color: Colors.white38,
                    fontFamily: 'Vazirmatn')),
            const SizedBox(height: 2),
            const Text('امروز چی کار کنم؟ 🎯',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Vazirmatn')),
          ]),
        ),
        if (_currentStreak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              Text('$_currentStreak روز',
                  style: const TextStyle(fontSize: 10, color: _accent,
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildWeekStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        _buildStat('🏋️', '$_weekSessions جلسه', 'این هفته'),
        _divider(),
        _buildStat('⏱️', '$_weekMinutes دق', 'تمرین کل'),
        _divider(),
        _buildStat('🔥', '$_currentStreak روز', 'استریک'),
      ]),
    );
  }

  Widget _buildStat(String emoji, String val, String label) {
    return Expanded(
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: Colors.white, fontFamily: 'Vazirmatn')),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white38,
            fontFamily: 'Vazirmatn')),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white10);
}

// helper extension
extension _ContextLet<T> on T? {
  void let(void Function(T) block) {
    if (this != null) block(this as T);
  }
}
