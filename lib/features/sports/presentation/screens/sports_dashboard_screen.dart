// lib/features/sports/presentation/screens/sports_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/sports/presentation/providers/sports_providers.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_screen.dart';
import 'package:ritmo/features/sports/presentation/screens/readiness_checkin_sheet.dart';
import 'package:ritmo/features/sports/presentation/screens/progress_screen.dart';

class SportsDashboardScreen extends ConsumerWidget {
  const SportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportsDashboardControllerProvider);

    return Scaffold(
      backgroundColor: RitmoTheme.primaryBg,
      appBar: _buildAppBar(context, ref, state),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RitmoTheme.accent)),
        error: (e, _) => Center(child: Text('خطا: $e', style: const TextStyle(color: Colors.red))),
        data: (s) => s.isLoading
            ? const Center(child: CircularProgressIndicator(color: RitmoTheme.accent))
            : s.isSetupDone ? _buildMainContent(context, ref, s) : _buildSetupContent(context, ref),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, AsyncValue<SportsDashboardState> state) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('ریتمو ورزش', style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      )),
      centerTitle: true,
      actions: state.maybeWhen(
        data: (s) => s.isSetupDone ? [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.read(sportsDashboardControllerProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => _showSettings(context, ref),
          ),
        ] : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildSetupContent(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('خوش اومدی! 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          const Text('بیایم برنامه ورزشت رو بسازیم',
              style: TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 24),
          _SetupCard(onDone: () => ref.read(sportsDashboardControllerProvider.notifier).markSetupDone()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, SportsDashboardState s) {
    return RefreshIndicator(
      color: RitmoTheme.accent,
      onRefresh: () => ref.read(sportsDashboardControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, s),
            const SizedBox(height: 16),

            // Readiness Check-in Card (if not done today)
            if (s.readiness == null) _buildReadinessPrompt(context, ref, s) else _buildReadinessCard(s.readiness!),
            const SizedBox(height: 16),

            // Today's Workout Card
            if (s.todayPlan != null) _buildTodayWorkoutCard(context, ref, s),
            const SizedBox(height: 16),

            // Continuity Bar
            _buildContinuityBar(context, s),
            const SizedBox(height: 16),

            // Quick Stats
            _buildQuickStats(s),
            const SizedBox(height: 16),

            // Weekly Volume
            if (s.weeklyVolume != null) _buildWeeklyVolumeCard(s.weeklyVolume!),
            const SizedBox(height: 16),

            // Recent PRs
            if (s.recentPrs != null && s.recentPrs!.isNotEmpty) _buildRecentPrs(s.recentPrs!),
            const SizedBox(height: 16),

            // AI Banner
            _buildAiBanner(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SportsDashboardState s) {
    final weekday = DateTime.now().weekday;
    const dayNames = {1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه', 5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه'};

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${dayNames[weekday]} • ورزش',
                  style: const TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 2),
              Text(s.todayPlan?.isRestDay == true ? 'امروز استراحت 🌿' : 'امروز چی کار کنم؟ 🎯',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
            ],
          ),
        ),
        if (s.currentStreak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: RitmoTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RitmoTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              Text('${s.currentStreak} روز',
                  style: const TextStyle(fontSize: 11, color: RitmoTheme.accent, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ]),
          ),
      ],
    );
  }

  Widget _buildReadinessPrompt(BuildContext context, WidgetRef ref, SportsDashboardState s) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ReadinessCheckinSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [RitmoTheme.accent.withValues(alpha: 0.15), RitmoTheme.accent.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RitmoTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: RitmoTheme.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.wb_sunny_outlined, color: RitmoTheme.accent, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('چک‌ین صبحگاهی 🌅',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                  SizedBox(height: 4),
                  Text('چطور خوابیدی؟ بدن‌ت چطوره؟ ۳۰ ثانیه وقت بذار.',
                      style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Vazirmatn')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: RitmoTheme.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard(ReadinessScore r) {
    Color tierColor = Colors.greenAccent;
    switch (r.suggestedTier) {
      case WorkoutTier.full: tierColor = Colors.greenAccent;
      case WorkoutTier.light: tierColor = Colors.orangeAccent;
      case WorkoutTier.minimal: tierColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: tierColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Text(r.suggestedTier.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آمادگی امروز: ${r.score}/100',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                    Text(r.reason, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Vazirmatn')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('پیشنهاد: ${r.suggestedTier.label}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tierColor, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
          if (r.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(r.reason, style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontFamily: 'Vazirmatn'))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutCard(BuildContext context, WidgetRef ref, SportsDashboardState s) {
    final plan = s.todayPlan;
    if (plan == null) return const SizedBox();
    final session = s.todaysSession;
    final isLogged = session != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RitmoTheme.accent.withValues(alpha: isLogged ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RitmoTheme.accent.withValues(alpha: isLogged ? 0.2 : 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: RitmoTheme.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Text(plan.splitDay.targetMuscles.isNotEmpty ? plan.splitDay.targetMuscles.first.emoji : '🏋️',
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('برنامه امروز',
                        style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
                    Text(
                        plan.splitDay.targetMuscles.map((m) => '${m.emoji} ${m.label}').join('  +  '),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                  ],
                ),
              ),
              if (isLogged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('✓ ثبت شد', style: TextStyle(fontSize: 11, color: Colors.green, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Tier selector
          if (!isLogged) ...[
            const Text('نسخه تمرین امروز:', style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 8),
            Row(children: WorkoutTier.values.map((t) {
              final isSelected = t == plan.suggestedTier;
              final isSuggested = t == plan.suggestedTier;
              return Expanded(
                child: GestureDetector(
                  onTap: () {}, // TODO: implement tier change
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? t.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? t.color : Colors.white.withValues(alpha: 0.07),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Text(t.label,
                          style: TextStyle(
                              fontSize: 12, fontFamily: 'Vazirmatn',
                              color: isSelected ? (isSelected ? t.color : Colors.white) : Colors.white38,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      if (isSuggested)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: t.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text('پیشنهاد', style: TextStyle(fontSize: 8, color: t.color, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        ),
                    ]),
                  ),
                ),
              );

            }).toList()),
            const SizedBox(height: 6),
            Text(plan.tierReason, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 14),
          ],

          // Suggested exercises
          const Text('حرکات پیشنهادی:', style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              ...plan.exercises.take(8).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: RitmoTheme.accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RitmoTheme.accent.withValues(alpha: 0.15)),
                ),
                child: Text(e.exerciseName ?? e.exerciseId, style: TextStyle(fontSize: 11, color: RitmoTheme.accent.withValues(alpha: 0.85), fontFamily: 'Vazirmatn')),
              )),
              if (plan.exercises.length > 8)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text('+${plan.exercises.length - 8} حرکت دیگر', style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn')),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Action button
          ElevatedButton(
            onPressed: isLogged ? () => _showLogAgainDialog(context, ref) : () => _startWorkout(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLogged ? Colors.white12 : RitmoTheme.accent,
              foregroundColor: isLogged ? Colors.white60 : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(isLogged ? '✓ تمرین ثبت شد — ثبت مجدد' : 'ثبت تمرین امروز ⚡',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          ),
          if (!isLogged) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showCantTodaySheet(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white54, padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text('امروز نمی‌تونم 😓', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  void _startWorkout(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SSWorkoutSessionScreen(
      planId: 'default',
    )));
  }

  void _showLogAgainDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF0D1A15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('ثبت مجدد؟', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
      content: const Text('امروز قبلاً تمرین ثبت کردی. باز هم ثبت کنی؟', style: TextStyle(color: Colors.white70, fontFamily: 'Vazirmatn')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف', style: TextStyle(color: Colors.white38, fontFamily: 'Vazirmatn'))),
        TextButton(onPressed: () { Navigator.pop(context); _startWorkout(context, ref); }, child: const Text('بله، ثبت مجدد', style: TextStyle(color: RitmoTheme.accent, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _showCantTodaySheet(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => _CantTodaySheet());
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    // TODO: Settings screen
  }

  Widget _buildContinuityBar(BuildContext context, SportsDashboardState s) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥 تداوم هفتگی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                const Spacer(),
                Text('${s.currentStreak} روز', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RitmoTheme.accent, fontFamily: 'Vazirmatn')),
              ],
            ),
            const SizedBox(height: 12),
            // Simple 7-day bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = DateTime.now().subtract(Duration(days: 6 - i));
                // TODO: replace with real session lookup
                const textCol = Colors.white38;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Center(child: Text(_persianDayShort(day.weekday), style: const TextStyle(fontSize: 9, color: textCol, fontFamily: 'Vazirmatn'))),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _persianDayShort(int weekday) {
    const map = {1: 'د', 2: 'س', 3: 'چ', 4: 'پ', 5: 'ج', 6: 'ش', 7: 'ی'};
    return map[weekday] ?? '';
  }

  Widget _buildQuickStats(SportsDashboardState s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _buildStat('🏋️', '${s.weeklyVolume?.totalSessions ?? 0} جلسه', 'این هفته'),
          _divider(),
          _buildStat('⏱️', '${s.weeklyVolume?.totalVolumeKg.toInt() ?? 0} kg', 'حجم کل'),
          _divider(),
          _buildStat('🔥', '${s.currentStreak} روز', 'استریک'),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String val, String label) => Expanded(
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
      Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.white38, fontFamily: 'Vazirmatn')),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white10);

  Widget _buildWeeklyVolumeCard(WeeklyVolumeReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حجم تمرینی هفته', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: report.volumePerMuscle.entries.map((e) {
                final maxVol = report.volumePerMuscle.values.reduce((a, b) => a > b ? a : b);
                final h = maxVol > 0 ? (e.value / maxVol * 100).clamp(10, 100).toDouble() : 10.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: h,
                        decoration: BoxDecoration(
                          color: e.key.color.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(e.key.emoji, style: const TextStyle(fontSize: 14)),
                      Text('${e.value.toInt()}kg', style: const TextStyle(fontSize: 9, color: Colors.white60, fontFamily: 'Vazirmatn')),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPrs(List<ProgressionRecord> prs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆 رکوردهای اخیر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber, fontFamily: 'Vazirmatn')),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('مشاهده همه', style: TextStyle(color: Colors.amber, fontFamily: 'Vazirmatn'))),
          ]),
          const SizedBox(height: 8),
          ...prs.take(3).map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Text('🏆', style: TextStyle(fontSize: 16))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.exerciseName} — ${p.weightKg.toStringAsFixed(1)}kg × ${p.reps}', style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                Text(p.progressionType == 'weight_increase' ? 'افزایش وزن' : p.progressionType == 'rep_increase' ? 'افزایش تکرار' : 'پیشرفت', style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'Vazirmatn')),
              ])),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCoachChatScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple.withValues(alpha: 0.15), Colors.blue.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.psychology_outlined, color: Colors.purple, size: 26)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مربی هوش مصنوعی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
            Text('سوال داری؟ برنامه رو بررسی کنه یا انگیزه بده', style: TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Vazirmatn')),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 18),
        ]),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('🎯', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('راه‌اندازی ورزش', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('هدف، روزها و محل تمرین رو مشخص کن تا برنامه‌ات رو بسازیم', style: TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Vazirmatn'), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onDone, style: ElevatedButton.styleFrom(backgroundColor: RitmoTheme.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text('شروع کنیم ⚡', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'))),
      ]),
    );
  }
}

class _CantTodaySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reasons = [
      ('🤒', 'بیمارم / حالت بد'),
      ('⏰', 'وقت ندارم / شلوغم'),
      ('😴', 'خیلی خسته‌ام / نخوابیده‌ام'),
      ('🤕', 'درد / آسیب داریم'),
      ('🧘', 'استراحت باختی / دیلود'),
      ('🚫', 'سایر دلایل'),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: Color(0xFF0D1A15), borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: Colors.white12))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('امروز نمی‌تونم تمرین کنم 😓', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 8),
        const Text('دلیل رو انتخاب کن تا برنامه‌ات تنظیم بشه', style: TextStyle(fontSize: 12, color: Colors.white54, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 20),
        ...reasons.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: Row(children: [
                Text(r.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500))),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف', style: TextStyle(color: Colors.white38, fontFamily: 'Vazirmatn', fontSize: 13))),
      ]),
    );
  }
}

// AiCoach placeholder
class AiCoachChatScreen extends StatelessWidget {
  const AiCoachChatScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(
        backgroundColor: RitmoTheme.primaryBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'مربی هوش مصنوعی',
            style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'چت مربی AI - در حال توسعه',
            style: TextStyle(color: Colors.white54, fontFamily: 'Vazirmatn'),
          ),
        ),
      );
}
