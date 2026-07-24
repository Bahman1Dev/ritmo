// lib/features/sports/presentation/sports_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/logic/workout_suggester.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';
import 'package:ritmo/features/sports/movement/domain/movement_budget.dart';
import 'package:ritmo/features/sports/movement/presentation/movement_log_sheet.dart';
import 'package:ritmo/features/sports/movement/presentation/widgets/weekly_budget_card.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_cant_today_sheet.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_recovery_card.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_setup_card.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_split_editor.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_today_workout_card.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_screen.dart';
import 'package:sqflite/sqflite.dart';

class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  bool _isLoading = true;

  // Setup & Split
  bool _isSetupDone = false;
  TodayWorkoutSuggestion? _todaySuggestion;
  bool _isTodayLogged = false;

  // Budget Snapshot
  MovementBudgetSnapshot? _budgetSnapshot;

  // Recovery
  bool _recoveryLogged = false;
  int _recSoreness = 1;
  int _recFatigue = 1;
  int _recHydration = 2;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final snapshot = await MovementBudgetService.instance.getCurrentWeekSnapshot();

      _isSetupDone = await WorkoutSuggester.isSetupDone(db);
      if (_isSetupDone) {
        _todaySuggestion = await WorkoutSuggester.buildToday(db);
        _isTodayLogged = await WorkoutSuggester.isTodayLogged(db);
      }
      _budgetSnapshot = snapshot;
      _recoveryLogged = await WorkoutSuggester.isTodayRecoveryLogged(db);
      await _loadRecovery(db);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRecovery(Database db) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final rows = await db.query(
        'workout_recovery_logs',
        where: 'date = ?',
        whereArgs: [dateKey],
        orderBy: 'loggedAt DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        _recSoreness = rows.first['soreness'] as int? ?? 1;
        _recFatigue = rows.first['fatigue'] as int? ?? 1;
        _recHydration = rows.first['hydration'] as int? ?? 2;
      }
    } catch (_) {}
  }

  void _openMovementLog() {
    RitmoHaptics.tap();
    showMovementLogSheet(
      context,
      onLogged: _loadAll,
    );
  }

  void _openStrengthSession() {
    RitmoHaptics.tap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SSWorkoutSessionScreen(planId: 'default'),
      ),
    ).then((_) => _loadAll());
  }

  void _openCantTodaySheet() {
    RitmoHaptics.tap();
    showSportsCantTodaySheet(
      context,
      onReasonSelected: (_) {
        RitmoHaptics.success();
        _loadAll();
      },
    );
  }

  void _openSplitEditor() async {
    final db = await DatabaseHelper.instance.database;
    final split = await WorkoutSuggester.readSplit(db);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SportsSplitEditor(
        split: split,
        onChanged: _loadAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('هاب حرکت و ورزش', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: _openSplitEditor,
            tooltip: 'تنظیم برنامهٔ تفکیکی',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TOP: WEEKLY MOVEMENT BUDGET CARD ---
                    if (_budgetSnapshot != null)
                      WeeklyBudgetCard(
                        snapshot: _budgetSnapshot!,
                        onTap: _openMovementLog,
                      ),
                    const SizedBox(height: 16),

                    // --- COLUMN 1: 🏋️ STRENGTH WORKOUT COLUMN ---
                    Text(
                      '🏋️ ستون ۱ — تمرین ساختاریافته قدرتی',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: colors.onBackground),
                    ),
                    const SizedBox(height: 8),
                    if (!_isSetupDone)
                      SportsSetupCard(onDone: _loadAll)
                    else if (_todaySuggestion != null)
                      SportsTodayWorkoutCard(
                        suggestion: _todaySuggestion!,
                        isTodayLogged: _isTodayLogged,
                        onLog: _openStrengthSession,
                        onEditSplit: _openSplitEditor,
                        onCantToday: _openCantTodaySheet,
                      ),
                    const SizedBox(height: 20),

                    // --- COLUMN 2: 🚶 MOVEMENT ACTIVITIES COLUMN ---
                    Text(
                      '🚶 ستون ۲ — فعالیت‌های حرکتی و روزمره',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: colors.onBackground),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'هر فعالیت بدنی هدفمند (شنا، کوه‌نوردی، دویدن، پیاده‌روی، فوتبال...) را اینجا ثبت کن.',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _openMovementLog,
                              icon: const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 18),
                              label: const Text(
                                'ثبت فعالیت ⚡',
                                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- COLUMN 3: 🌿 RECOVERY & READINESS COLUMN ---
                    Text(
                      '🌿 ستون ۳ — ریکاوری و آمادگی بدنی',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: colors.onBackground),
                    ),
                    const SizedBox(height: 8),
                    SportsRecoveryCard(
                      alreadyLogged: _recoveryLogged,
                      initialSoreness: _recSoreness,
                      initialFatigue: _recFatigue,
                      initialHydration: _recHydration,
                      onSaved: _loadAll,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
