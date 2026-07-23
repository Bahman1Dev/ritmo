// lib/features/sports/presentation/providers/sports_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/sports/domain/repositories/sports_repository.dart';
import 'package:ritmo/features/sports/domain/services/readiness_calculator.dart';
import 'package:ritmo/features/sports/data/repositories/sports_repository_impl.dart';
import 'package:ritmo/features/sports/data/datasources/sports_local_datasource.dart';
import 'package:ritmo/features/sports/data/datasources/sports_local_datasource_impl.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'sports_providers.freezed.dart';
part 'sports_providers.g.dart';

// ──────────────────────────────────────────────────────────────
// Core Dependencies (manual providers — @riverpod can't handle
// abstract return types like Database / SportsRepository)
// ──────────────────────────────────────────────────────────────

final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.instance.database;
});

final sportsLocalDataSourceProvider =
    FutureProvider<SportsLocalDataSource>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SportsLocalDataSourceImpl(db);
});

final sportsRepositoryProvider =
    FutureProvider<SportsRepository>((ref) async {
  final ds = await ref.watch(sportsLocalDataSourceProvider.future);
  final db = await ref.watch(databaseProvider.future);
  return SportsRepositoryImpl(ds, db);
});


// ──────────────────────────────────────────────────────────────
// Sports Dashboard Controller
// ──────────────────────────────────────────────────────────────

@riverpod
class SportsDashboardController extends _$SportsDashboardController {
  @override
  Future<SportsDashboardState> build() async {
    final repo = await ref.watch(sportsRepositoryProvider.future);
    return _loadDashboard(repo);
  }

  Future<SportsDashboardState> _loadDashboard(SportsRepository repo) async {
    final isSetup = await repo.isSetupDone();

    if (!isSetup) {
      return const SportsDashboardState(
        isLoading: false,
      );
    }

    // Load all data in parallel
    final results = await Future.wait([
      repo.getTodaysPlan(),
      repo.getTodaysSession(),
      repo.getTodaysReadiness(),
      repo.getLocation(),
      repo.getGoalFocus(),
      repo.getRecentPrs(limit: 5),
      repo.getReadinessHistory(limit: 14),
    ]);

    final todayPlan = results[0] as TodayWorkoutPlan?;
    final todaysSession = results[1] as WorkoutSession?;
    final readiness = results[2] as ReadinessScore?;
    final location = results[3]! as SportsLocation;
    final goal = results[4]! as WorkoutGoal;
    recentPrs = (results[5]! as List<ProgressionRecord>);
    final readinessHistory = results[6]! as List<ReadinessScore>;

    // Weekly stats
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final volumeReport = await repo.getWeeklyVolumeReport(weekStart);
    weeklyVolume = volumeReport;

    // Streak
    final sessions = await repo.getSessions(
      from: DateTime.now().subtract(const Duration(days: 30)),
    );
    currentStreak = _calculateStreak(sessions);

    return SportsDashboardState(
      isSetupDone: true,
      isLoading: false,
      todayPlan: todayPlan,
      todaysSession: todaysSession,
      readiness: readiness,
      location: location,
      goal: goal,
      recentPrs: recentPrs,
      readinessHistory: readinessHistory,
      weeklyVolume: weeklyVolume,
      currentStreak: currentStreak,
    );
  }

  int _calculateStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;
    final now = DateTime.now();
    var streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);

    DateTime? completedDate(WorkoutSession s) =>
        s.completedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(s.completedAt!)
            : null;

    bool sameDay(DateTime? dt, DateTime ref) =>
        dt != null &&
        dt.year == ref.year &&
        dt.month == ref.month &&
        dt.day == ref.day;

    // Check if today has workout
    final todayHasWorkout = sessions.any(
        (s) => sameDay(completedDate(s), checkDate));

    if (todayHasWorkout) {
      streak = 1;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Check yesterday
      final yesterday = checkDate.subtract(const Duration(days: 1));
      final yesterdayHasWorkout = sessions.any(
          (s) => sameDay(completedDate(s), yesterday));

      if (yesterdayHasWorkout) {
        streak = 1;
        checkDate = yesterday.subtract(const Duration(days: 1));
      } else {
        return 0;
      }
    }

    while (true) {
      final hasWorkout = sessions.any(
          (s) => sameDay(completedDate(s), checkDate));

      if (hasWorkout) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Cached data
  List<ProgressionRecord> recentPrs = [];
  List<ReadinessScore> readinessHistory = [];
  WeeklyVolumeReport? weeklyVolume;
  int currentStreak = 0;

  // ──────────────────────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> markSetupDone() async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    await repo.markSetupDone();
    await refresh();
  }

  Future<void> saveReadiness(MorningCheckinInput input) async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    // Fetch recent sessions for context (not currently used in calculation)
    await repo.getSessions(
      from: DateTime.now().subtract(const Duration(days: 7)),
    );

    final readiness = ReadinessCalculator.calculate(
      date: _dateKey(DateTime.now()),
      sleepMinutes: input.sleepMinutes > 0 ? input.sleepMinutes : null,
      sleepQuality: input.sleepQuality,
      hrvRmssd: input.hrvRmssd,
      restingHr: input.restingHr,
      sorenessScore: input.sorenessScore ?? 0,
      fatigueScore: input.fatigueScore ?? 0,
      moodScore: input.moodScore ?? 0,
      isMenstrualPhase: input.isMenstrualPhase,
      last7DaysSessions: [],
    );

    await repo.saveReadinessScore(readiness);
    await refresh();
  }

  Future<void> startTodaysWorkout() async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    final plan = await repo.getTodaysPlan();
    if (plan == null || plan.isRestDay || plan.hasNoPlan) return;

    final session = WorkoutSession(
      id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now().millisecondsSinceEpoch,
      splitDayId: plan.splitDay.id,
      plannedTier: plan.suggestedTier,
      completedTier: plan.suggestedTier,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.startSession(session);
    await refresh();
  }

  Future<void> completeSession(WorkoutSession session) async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    final now = DateTime.now();
    await repo.completeSession(session.copyWith(
      completedAt: now.millisecondsSinceEpoch,
      actualDurationSeconds: now.difference(
        DateTime.fromMillisecondsSinceEpoch(session.startedAt),
      ).inSeconds,
    ));
    await refresh();
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

@freezed
abstract class SportsDashboardState with _$SportsDashboardState {
  const factory SportsDashboardState({
    @Default(false) bool isSetupDone,
    @Default(true) bool isLoading,
    TodayWorkoutPlan? todayPlan,
    WorkoutSession? todaysSession,
    ReadinessScore? readiness,
    @Default(SportsLocation.home) SportsLocation location,
    @Default(WorkoutGoal.hypertrophy) WorkoutGoal goal,
    List<ProgressionRecord>? recentPrs,
    List<ReadinessScore>? readinessHistory,
    WeeklyVolumeReport? weeklyVolume,
    @Default(0) int currentStreak,
    String? error,
  }) = _SportsDashboardState;

  factory SportsDashboardState.fromJson(Map<String, dynamic> json) =>
      _$SportsDashboardStateFromJson(json);
}

// ──────────────────────────────────────────────────────────────
// Session Controller
// ──────────────────────────────────────────────────────────────

@riverpod
class WorkoutSessionController extends _$WorkoutSessionController {
  @override
  Future<WorkoutSessionState> build(String sessionId) async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    final session = await repo.getSessionById(sessionId);
    if (session == null) throw 'Session not found';

    final exercises = await repo.getPerformedExercises(sessionId);
    return WorkoutSessionState(
      session: session,
      exercises: exercises,
      currentExerciseIndex: 0,
      isComplete: false,
    );
  }

  Future<void> completeSet(String exerciseId, PerformedSet set) async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    await repo.savePerformedSet(set);

    final currentState = state.requireValue;
    final nextIndex = currentState.exercises.indexWhere(
        (e) => e.id != exerciseId);

    state = AsyncData(currentState.copyWith(
      exercises: currentState.exercises
          .map((e) => e.id == exerciseId
              ? e.copyWith(
                  totalVolumeKg:
                      e.totalVolumeKg + set.weightKg * set.reps,
                )
              : e)
          .toList(),
      currentExerciseIndex:
          nextIndex >= 0 ? nextIndex : currentState.currentExerciseIndex,
    ));
  }

  Future<void> skipExercise(String exerciseId) async {
    final currentState = state.requireValue;
    final nextIndex = currentState.exercises.indexWhere(
        (e) => e.id != exerciseId);
    state = AsyncData(currentState.copyWith(
      currentExerciseIndex:
          nextIndex >= 0 ? nextIndex : currentState.currentExerciseIndex,
    ));
  }

  Future<void> finishWorkout() async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    final currentState = state.requireValue;

    final now = DateTime.now();
    final startedDt = DateTime.fromMillisecondsSinceEpoch(
        currentState.session.startedAt);
    final completedSession = currentState.session.copyWith(
      completedAt: now.millisecondsSinceEpoch,
      actualDurationSeconds: now.difference(startedDt).inSeconds,
      totalVolumeKg: currentState.exercises.fold(
          0.0, (sum, e) => sum + e.totalVolumeKg),
      totalSets: currentState.exercises.length,
      completedTier: currentState.session.plannedTier,
      updatedAt: now.millisecondsSinceEpoch,
    );

    await repo.completeSession(completedSession);
    ref.invalidate(sportsDashboardControllerProvider);
  }
}


@freezed
abstract class WorkoutSessionState with _$WorkoutSessionState {
  const factory WorkoutSessionState({
    required WorkoutSession session,
    required List<PerformedExercise> exercises,
    @Default(0) int currentExerciseIndex,
    @Default(false) bool isComplete,
  }) = _WorkoutSessionState;

  factory WorkoutSessionState.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionStateFromJson(json);
}

// ──────────────────────────────────────────────────────────────
// Split Builder Controller
// ──────────────────────────────────────────────────────────────

@riverpod
class SplitBuilderController extends _$SplitBuilderController {
  @override
  SplitBuilderState build() {
    return const SplitBuilderState(
      goal: WorkoutGoal.hypertrophy,
      frequency: 4,
      location: SportsLocation.home,
      selectedDays: [1, 2, 4, 5], // Mon, Tue, Thu, Fri
      splits: {},
      currentWeek: 1,
      mesocycleWeeks: 6,
      progressionType: ProgressionType.doubleProgression,
      deloadFrequency: 4,
    );
  }

  void setGoal(WorkoutGoal goal) => state = state.copyWith(goal: goal);
  void setFrequency(int freq) => state = state.copyWith(frequency: freq);
  void setLocation(SportsLocation loc) => state = state.copyWith(location: loc);
  void toggleDay(int day) {
    final days = Set<int>.from(state.selectedDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(selectedDays: days.toList()..sort());
  }

  void setMesocycleWeeks(int weeks) => state = state.copyWith(mesocycleWeeks: weeks);
  void setProgression(ProgressionType type) => state = state.copyWith(progressionType: type);
  void setDeloadFreq(int freq) => state = state.copyWith(deloadFrequency: freq);

  void nextStep() {
    if (state.currentStep.index < SplitBuilderStep.values.length - 1) {
      state = state.copyWith(currentStep: SplitBuilderStep.values[state.currentStep.index + 1]);
    }
  }

  void prevStep() {
    if (state.currentStep.index > 0) {
      state = state.copyWith(currentStep: SplitBuilderStep.values[state.currentStep.index - 1]);
    }
  }

  Future<void> saveSplit() async {
    final repo = await ref.read(sportsRepositoryProvider.future);
    // Create plan
    final plan = WorkoutPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: 'My ${state.goal.label} Plan',
      goal: state.goal,
      frequency: state.frequency,
      mesocycleLengthWeeks: state.mesocycleWeeks,
      currentWeek: 1,
      progressionType: state.progressionType,
      deloadFrequencyWeeks: state.deloadFrequency,
      isActive: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await repo.savePlan(plan);
    await repo.setActivePlan(plan.id);

    // Create split days for mesocycle
    for (var week = 1; week <= state.mesocycleWeeks; week++) {
      for (final day in state.selectedDays) {
        final splitDay = WorkoutSplitDay(
          id: 'sd_${plan.id}_w${week}_d$day',
          splitId: plan.id,
          weekday: day,
          weekInMesocycle: week,
          dayName: _dayName(day),
          isRest: false,
          targetMuscles: _defaultMusclesForDay(day, state.goal),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await repo.saveSplitDay(splitDay);
      }
    }
  }


  List<MuscleGroup> _defaultMusclesForDay(int day, WorkoutGoal goal) {
    // Simple defaults - can be enhanced
    final upper = [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps];
    final lower = [MuscleGroup.legs, MuscleGroup.abs];

    if (goal == WorkoutGoal.strength) {
      return day.isOdd ? upper : lower;
    }
    // Hypertrophy: Upper/Lower
    return day.isOdd ? upper : lower;
  }

  String _dayName(int day) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day];
  }
}

@freezed
abstract class SplitBuilderState with _$SplitBuilderState {
  const factory SplitBuilderState({
    required WorkoutGoal goal, required int frequency, required SportsLocation location, required List<int> selectedDays, required Map<String, List<MuscleGroup>> splits, required int currentWeek, required int mesocycleWeeks, required ProgressionType progressionType, required int deloadFrequency, @Default(SplitBuilderStep.goal) SplitBuilderStep currentStep,
  }) = _SplitBuilderState;

  factory SplitBuilderState.fromJson(Map<String, dynamic> json) =>
      _$SplitBuilderStateFromJson(json);
}

enum SplitBuilderStep {
  goal('هدف'),
  frequency('فرکانس'),
  days('روزها'),
  location('محل'),
  advanced('پیشرفته'),
  review('مرور و ذخیره');

  const SplitBuilderStep(this.label);
  final String label;
}

// ──────────────────────────────────────────────────────────────
// Input Models
// ──────────────────────────────────────────────────────────────

class MorningCheckinInput {
  const MorningCheckinInput({
    this.sleepMinutes = 0,
    this.sleepQuality,
    this.hrvRmssd,
    this.restingHr,
    this.sorenessScore,
    this.fatigueScore,
    this.moodScore,
    this.isMenstrualPhase = false,
  });

  final int sleepMinutes;
  final int? sleepQuality;
  final int? hrvRmssd;
  final int? restingHr;
  final int? sorenessScore;
  final int? fatigueScore;
  final int? moodScore;
  final bool isMenstrualPhase;
}