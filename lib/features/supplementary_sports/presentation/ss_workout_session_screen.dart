import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_exercise_model.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_session_summary_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_notifier.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/bottom_sheet_container.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/selectable_card.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_muscle_image_resolver.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart';

// ─── MVI INTENTS ─────────────────────────────────────────────
sealed class SSWorkoutIntent {
  const SSWorkoutIntent();
}

class CompleteCurrentSet extends SSWorkoutIntent {
  const CompleteCurrentSet();
}

class SelectFeeling extends SSWorkoutIntent {
  const SelectFeeling(this.exerciseId, this.feeling);
  final String exerciseId;
  final Feeling feeling;
}

class DismissFeelingSheet extends SSWorkoutIntent {
  const DismissFeelingSheet();
}

class SwapExerciseIntent extends SSWorkoutIntent {
  const SwapExerciseIntent({
    required this.exerciseId,
    required this.newExerciseId,
    required this.newExerciseName,
  });
  final String exerciseId;
  final String newExerciseId;
  final String newExerciseName;
}

class FinishSession extends SSWorkoutIntent {
  const FinishSession();
}

class SkipRestTimer extends SSWorkoutIntent {
  const SkipRestTimer();
}

class PauseResumeTimer extends SSWorkoutIntent {
  const PauseResumeTimer();
}

class AddNoteToExercise extends SSWorkoutIntent {
  const AddNoteToExercise(this.exerciseId, this.note);
  final String exerciseId;
  final String note;
}

class GoToPreviousExercise extends SSWorkoutIntent {
  const GoToPreviousExercise();
}

class GoToNextExercise extends SSWorkoutIntent {
  const GoToNextExercise();
}

class UpdateSetWeightAndReps extends SSWorkoutIntent {
  const UpdateSetWeightAndReps({required this.setIndex, this.weight, this.reps, this.rir});
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
}

// ─── SET STATUS & ROW MODELS ─────────────────────────────────
enum SetStatus { pending, current, done }

class SetRow {

  SetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.restSeconds,
    this.status = SetStatus.pending,
  });

  factory SetRow.fromMap(Map<String, dynamic> m) => SetRow(
    setNumber: m['setNumber'] as int,
    weight: (m['weight'] as num).toDouble(),
    reps: m['reps'] as int,
    rir: m['rir'] as int,
    restSeconds: m['restSeconds'] as int,
    status: SetStatus.values[m['status'] as int],
  );
  final int setNumber;
  final double weight;
  final int reps;
  final int rir;
  final int restSeconds;
  final SetStatus status;

  SetRow copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    int? rir,
    int? restSeconds,
    SetStatus? status,
  }) {
    return SetRow(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      restSeconds: restSeconds ?? this.restSeconds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'setNumber': setNumber,
    'weight': weight,
    'reps': reps,
    'rir': rir,
    'restSeconds': restSeconds,
    'status': status.index,
  };
}

class SSExerciseChecklistEntry {

  SSExerciseChecklistEntry({
    required this.exercise,
    required this.referenceSets,
    required this.referenceReps,
    this.referenceWeight,
    this.status = ExerciseStatus.upcoming,
    this.feeling,
    this.optionalNote,
    List<SetRow>? setRows,
  }) : setRows = setRows ?? List.generate(
          referenceSets,
          (i) => SetRow(
            setNumber: i + 1,
            weight: referenceWeight ?? 0,
            reps: referenceReps,
            rir: 2,
            restSeconds: 90,
            status: i == 0 ? SetStatus.current : SetStatus.pending,
          ),
        );

  factory SSExerciseChecklistEntry.fromMap(Map<String, dynamic> map) {
    final rawRows = map['setRows'] as List<dynamic>?;
    return SSExerciseChecklistEntry(
      exercise: SsExerciseModel.fromMap(Map<String, dynamic>.from(map['exercise'] as Map)),
      referenceSets: map['referenceSets'] as int,
      referenceReps: map['referenceReps'] as int,
      referenceWeight: map['referenceWeight'] as double?,
      status: ExerciseStatus.values.firstWhere((e) => e.toString() == map['status']),
      feeling: map['feeling'] != null
          ? Feeling.values.firstWhere((e) => e.toString() == map['feeling'])
          : null,
      optionalNote: map['optionalNote'] as String?,
      setRows: rawRows?.map((r) => SetRow.fromMap(Map<String, dynamic>.from(r as Map))).toList(),
    );
  }
  final SsExerciseModel exercise;
  final int referenceSets;
  final int referenceReps;
  final double? referenceWeight;
  final ExerciseStatus status;
  final Feeling? feeling;
  final String? optionalNote;
  final List<SetRow> setRows;

  SSExerciseChecklistEntry copyWith({
    SsExerciseModel? exercise,
    int? referenceSets,
    int? referenceReps,
    double? referenceWeight,
    ExerciseStatus? status,
    Feeling? feeling,
    String? optionalNote,
    List<SetRow>? setRows,
  }) {
    return SSExerciseChecklistEntry(
      exercise: exercise ?? this.exercise,
      referenceSets: referenceSets ?? this.referenceSets,
      referenceReps: referenceReps ?? this.referenceReps,
      referenceWeight: referenceWeight ?? this.referenceWeight,
      status: status ?? this.status,
      feeling: feeling ?? this.feeling,
      optionalNote: optionalNote ?? this.optionalNote,
      setRows: setRows ?? this.setRows,
    );
  }

  Map<String, dynamic> toMap() => {
    'exercise': exercise.toMap(),
    'referenceSets': referenceSets,
    'referenceReps': referenceReps,
    'referenceWeight': referenceWeight,
    'status': status.toString(),
    'feeling': feeling?.toString(),
    'optionalNote': optionalNote,
    'setRows': setRows.map((r) => r.toMap()).toList(),
  };

  int get currentSetIndex => setRows.indexWhere((s) => s.status == SetStatus.current);
  int get completedSetsCount => setRows.where((s) => s.status == SetStatus.done).length;
}

// ─────────────────────────────────────────────────────────────
// Redesigned Modern Glassmorphism Active Session Screen
// ─────────────────────────────────────────────────────────────
class SSWorkoutSessionScreen extends ConsumerStatefulWidget {

  const SSWorkoutSessionScreen({
    super.key,
    required this.planId,
    this.dayName = 'تمرین امروز',
  });
  final String planId;
  final String dayName;

  @override
  ConsumerState<SSWorkoutSessionScreen> createState() => _SSWorkoutSessionScreenState();
}

class _SSWorkoutSessionScreenState extends ConsumerState<SSWorkoutSessionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  late AnimationController _pulseAnimController;

  SSWorkoutPlanKey get _key => SSWorkoutPlanKey(planId: widget.planId, dayName: widget.dayName);

  List<SSExerciseChecklistEntry> get _exercises => ref.read(ssWorkoutProvider(_key)).exercises;
  int get _currentExerciseIndex => ref.read(ssWorkoutProvider(_key)).currentExerciseIndex;
  bool get _isLoading => ref.read(ssWorkoutProvider(_key)).isLoading;
  bool get _isResting => ref.read(ssWorkoutProvider(_key)).isResting;
  bool get _isTimerPaused => ref.read(ssWorkoutProvider(_key)).isTimerPaused;
  int get _restRemainingSeconds => ref.read(ssWorkoutProvider(_key)).restRemainingSeconds;
  int get _restTotalSeconds => ref.read(ssWorkoutProvider(_key)).restTotalSeconds;
  bool get _handsFreeMode => ref.read(ssWorkoutProvider(_key)).handsFreeMode;
  int get _elapsedSeconds => ref.read(ssWorkoutProvider(_key)).elapsedSeconds;

  String? _userGender;

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(ssWorkoutProvider(_key).notifier).init();
    });
  }

  Future<void> _fetchUserGender() async {
    try {
      final gender = await DatabaseHelper.instance.getUserGender();
      if (mounted) setState(() => _userGender = gender);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(ssWorkoutProvider(_key).notifier).handleLifecycleResumed();
    }
  }

  String _formatElapsed(int elapsedSeconds) {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return toPersianDigits(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
    }
    return toPersianDigits('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
  }

  void _dispatchIntent(SSWorkoutIntent intent) {
    HapticFeedback.selectionClick();
    ref.read(ssWorkoutProvider(_key).notifier).dispatch(intent);
  }

  Future<void> _showSwapBottomSheet() async {
    final current = _exercises[_currentExerciseIndex];
    try {
      final db = await DatabaseHelper.instance.database;
      final profileMapList = await db.query('ss_user_profile', limit: 1);
      if (profileMapList.isEmpty) return;
      final profile = SsUserProfile.fromMap(profileMapList.first);

      final results = await SSPlanGenerator.getSwapCandidates(
        db,
        current.exercise.id,
        profile,
      );

      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('حرکت جایگزین مناسبی یافت نشد.', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          ),
        );
        return;
      }

      if (mounted) {
        unawaited(
          showModalBottomSheet(
            context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => BottomSheetContainer(
            title: 'تعویض حرکت ورزشی',
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final row = results[i];
                final score = ((row['similarityScore'] as num? ?? 0) * 100).round();
                return SelectableCard(
                  title: '${row['name']} — $score٪ شباهت عضلانی',
                  selected: false,
                  onClick: () {
                    Navigator.pop(ctx);
                    _dispatchIntent(SwapExerciseIntent(
                      exerciseId: current.exercise.id,
                      newExerciseId: row['id'].toString(),
                      newExerciseName: row['name'].toString(),
                    ));
                  },
                );
              },
            ),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error showing swap sheet: $e');
    }
  }

  void _showNoteSheet() {
    final current = _exercises[_currentExerciseIndex];
    final ctrl = TextEditingController(text: current.optionalNote ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BottomSheetContainer(
          title: 'یادداشت این حرکت',
          child: Column(
            children: [
              TextField(
                controller: ctrl,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثلاً: وزنه سنگین بود، ست آخر کمک گرفتم...',
                  hintStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'ذخیره یادداشت',
                onPressed: () {
                  Navigator.pop(ctx);
                  _dispatchIntent(AddNoteToExercise(
                    current.exercise.id,
                    ctrl.text,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiCoachSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SSAiCoachSheet(),
    );
  }

  Future<void> _onClosePressed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'انصراف از تمرین؟ ⚠️',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: const Text(
            'با خروج از این صفحه، پیشرفت تمرین ذخیره‌نشده لغو خواهد شد.',
            style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ادامه تمرین', style: TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFF10B981))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج و لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
    if (ok ?? false) {
      await ref.read(ssWorkoutProvider(_key).notifier).abandonSession();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _finishAndLogWorkout() async {
    try {
      final result = await ref.read(ssWorkoutProvider(_key).notifier).finishAndLogWorkout();
      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SSSessionSummaryScreen(
                sessionId: result['sessionId'] as String,
                completedCount: result['completedCount'] as int,
                totalCount: result['totalCount'] as int,
                durationSeconds: result['durationSeconds'] as int,
                overallFeeling: result['overallFeeling'] as Feeling?,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error finishing session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'ذخیره تمرین ناموفق بود. لطفا دوباره تلاش کنید.',
                style: TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showFeelingBottomSheet(SSWorkoutState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BottomSheetContainer(
          title: 'این حرکت چطور بود؟',
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  _feelingButton(context, '😌', 'راحت', Feeling.easy, state),
                  const SizedBox(width: 8),
                  _feelingButton(context, '🙂', 'مناسب', Feeling.good, state),
                  const SizedBox(width: 8),
                  _feelingButton(context, '😓', 'سخت', Feeling.hard, state),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'برای ثبت دقیق‌تر شدت تمرین شما در الگوریتم هوشمند',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (ref.read(ssWorkoutProvider(_key)).isShowingFeelingSheet) {
        ref.read(ssWorkoutProvider(_key).notifier).dispatch(const DismissFeelingSheet());
      }
    });
  }

  Widget _feelingButton(BuildContext ctx, String emoji, String label, Feeling feeling, SSWorkoutState state) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          _dispatchIntent(SelectFeeling(
            state.exercises[state.currentExerciseIndex].exercise.id,
            feeling,
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _categoryLabel {
    if (_exercises.isEmpty) return 'تمرین';
    final cat = _exercises[_currentExerciseIndex].exercise.category;
    const map = {
      'chest': 'سینه و بالاتنه',
      'back': 'پشت و زیربغل',
      'legs': 'پا و باسن',
      'shoulders': 'سرشانه',
      'arms': 'بازو',
      'core': 'شکم و پهلو',
      'cardio': 'کاردیو',
      'stretch': 'کشش و یوگا',
    };
    return map[cat] ?? cat;
  }

  // ═══════════════════════ MAIN BUILD ═══════════════════════
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ssWorkoutProvider(_key));

    ref.listen<bool>(
      ssWorkoutProvider(_key).select((s) => s.isShowingFeelingSheet),
      (previous, next) {
        if (next) {
          _showFeelingBottomSheet(state);
        }
      },
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF10B981)),
              SizedBox(height: 16),
              Text(
                'درحال آماده‌سازی آمادگی جسمانی...',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _onClosePressed,
          ),
        ),
        body: const Center(
          child: Text(
            'هیچ حرکتی برای این برنامه یافت نشد.',
            style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
          ),
        ),
      );
    }

    final entry = _exercises[_currentExerciseIndex];

    Widget mainContent;
    if (_handsFreeMode) {
      mainContent = _buildHandsFreeHud(entry, state);
    } else {
      mainContent = Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _buildTopHUDHeader(entry, state),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHeroVisualStage(entry),
                        const SizedBox(height: 16),
                        _buildSetLoggingMatrix(entry),
                        const SizedBox(height: 16),
                        _buildRirExplanationBanner(),
                        const SizedBox(height: 100), // padding for bottom dock
                      ],
                    ),
                  ),
                ),
                _buildBottomFloatingDock(entry),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onClosePressed();
      },
      child: Stack(
        children: [
          mainContent,
          if (_isResting || state.status == SSWorkoutSessionStatus.resting)
            _buildRestingOverlay(state, entry),
          if (state.status == SSWorkoutSessionStatus.preparing)
            _buildPreparingOverlay(state),
          if (state.status == SSWorkoutSessionStatus.countdown)
            _buildCountdownOverlay(state),
          if (state.status == SSWorkoutSessionStatus.changeSides)
            _buildChangeSidesOverlay(state),
          if (state.status == SSWorkoutSessionStatus.completed)
            _buildCompletedOverlay(state),
        ],
      ),
    );
  }

  // ─── 1. TOP HUD HEADER ───────────────────────────────────────
  Widget _buildTopHUDHeader(SSExerciseChecklistEntry entry, SSWorkoutState state) {
    final completedCount = _exercises.where((e) => e.status == ExerciseStatus.done).length;
    final totalCount = _exercises.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                onPressed: _onClosePressed,
              ),
              const SizedBox(width: 4),
              // Session Duration Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Exercise counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  toPersianDigits('حرکت ${_currentExerciseIndex + 1} از $totalCount'),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // AI Coach Quick Button
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined, color: Color(0xFF06B6D4), size: 24),
                onPressed: _showAiCoachSheet,
              ),
              // Hands-Free Toggle
              IconButton(
                icon: Icon(
                  _handsFreeMode ? CupertinoIcons.zoom_out : CupertinoIcons.zoom_in,
                  color: _handsFreeMode ? const Color(0xFFF59E0B) : Colors.white70,
                  size: 22,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(ssWorkoutProvider(_key).notifier).toggleHandsFreeMode();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Smooth Animated Progress Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. HERO VISUAL STAGE (Lottie + Exercise Info) ───────────
  Widget _buildHeroVisualStage(SSExerciseChecklistEntry entry) {
    final muscleImage = SSMuscleImageResolver.resolve(entry.exercise.id, _userGender);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info bar inside card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Muscle map thumbnail
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(muscleImage, fit: BoxFit.cover),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _categoryLabel,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.exercise.equipment != null && entry.exercise.equipment!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.exercise.equipment!,
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: Color(0xFF06B6D4),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.exercise.name,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.exercise.nameEn != null && entry.exercise.nameEn!.isNotEmpty)
                        Text(
                          entry.exercise.nameEn!,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lottie Player Container
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SSExerciseAnimationCard(
              category: entry.exercise.category,
              exerciseId: entry.exercise.id,
            ),
          ),

          // Footer Tags (Impact, Noise, Target sets)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stageTag(
                  Icons.layers_outlined,
                  toPersianDigits('${entry.referenceSets} ست × ${entry.referenceReps} تکرار'),
                ),
                _stageTag(
                  entry.exercise.impact >= 2 ? Icons.directions_run : Icons.accessibility,
                  entry.exercise.impact >= 2 ? 'برخورد بالا' : 'آرام/کم‌برخورد',
                ),
                _stageTag(
                  entry.exercise.noisy >= 2 ? Icons.volume_up : Icons.volume_off,
                  entry.exercise.noisy >= 2 ? 'پرصدا' : 'بی‌صدا',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  // ─── 3. INTERACTIVE SET LOGGING MATRIX ───────────────────────
  Widget _buildSetLoggingMatrix(SSExerciseChecklistEntry entry) {
    final currentSetIndex = entry.currentSetIndex;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'ثبت ست‌های تمرین',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                toPersianDigits('${entry.completedSetsCount} از ${entry.referenceSets} تکمیل شده'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _DarkHeaderCell('ست')),
                Expanded(flex: 2, child: _DarkHeaderCell('وزنه (کیلو)')),
                Expanded(flex: 2, child: _DarkHeaderCell('تکرار')),
                Expanded(child: _DarkHeaderCell('RIR')),
                Expanded(flex: 2, child: _DarkHeaderCell('وضعیت')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Set Rows
          ...entry.setRows.map((row) => _buildDarkSetRow(row, entry)),

          const SizedBox(height: 16),

          // Complete Active Set CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentSetIndex != -1 ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: Icon(
                currentSetIndex != -1 ? CupertinoIcons.checkmark_alt_circle_fill : Icons.done_all,
                size: 22,
              ),
              label: Text(
                currentSetIndex != -1
                    ? 'ثبت و تکمیل ست ${toPersianDigits((currentSetIndex + 1).toString())}'
                    : 'همه ست‌ها انجام شد! 🏆',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: currentSetIndex != -1
                  ? () => _dispatchIntent(const CompleteCurrentSet())
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkSetRow(SetRow row, SSExerciseChecklistEntry entry) {
    final isCurrent = row.status == SetStatus.current;
    final isDone = row.status == SetStatus.done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : (isDone ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFF0F172A)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Set #
          Expanded(
            child: Center(
              child: Text(
                toPersianDigits('${row.setNumber}'),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCurrent ? const Color(0xFF10B981) : Colors.white70,
                ),
              ),
            ),
          ),

          // Weight (editable via stepper or picker)
          Expanded(
            flex: 2,
            child: isCurrent
                ? _stepperCell(
                    valueText: toPersianDigits(row.weight == row.weight.roundToDouble()
                        ? '${row.weight.round()}'
                        : row.weight.toStringAsFixed(1)),
                    onMinus: () => _dispatchIntent(UpdateSetWeightAndReps(
                      setIndex: row.setNumber - 1,
                      weight: max(0, row.weight - 2.5),
                    )),
                    onPlus: () => _dispatchIntent(UpdateSetWeightAndReps(
                      setIndex: row.setNumber - 1,
                      weight: row.weight + 2.5,
                    )),
                  )
                : Center(
                    child: Text(
                      toPersianDigits('${row.weight.round()} kg'),
                      style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, fontSize: 13),
                    ),
                  ),
          ),

          // Reps (editable via stepper)
          Expanded(
            flex: 2,
            child: isCurrent
                ? _stepperCell(
                    valueText: toPersianDigits('${row.reps}'),
                    onMinus: () => _dispatchIntent(UpdateSetWeightAndReps(
                      setIndex: row.setNumber - 1,
                      reps: max(1, row.reps - 1),
                    )),
                    onPlus: () => _dispatchIntent(UpdateSetWeightAndReps(
                      setIndex: row.setNumber - 1,
                      reps: row.reps + 1,
                    )),
                  )
                : Center(
                    child: Text(
                      toPersianDigits('${row.reps} تکرار'),
                      style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, fontSize: 13),
                    ),
                  ),
          ),

          // RIR Dropdown/Display
          Expanded(
            child: Center(
              child: isCurrent
                  ? _rirDropdownDark(row)
                  : Text(
                      isDone ? toPersianDigits('${row.rir}') : '-',
                      style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54, fontSize: 13),
                    ),
            ),
          ),

          // Status Check / Icon
          Expanded(
            flex: 2,
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                  : (isCurrent
                      ? const Icon(Icons.play_circle_fill, color: Color(0xFF10B981), size: 22)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.white30, size: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperCell({
    required String valueText,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onMinus,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.remove, size: 16, color: Colors.white70),
            ),
          ),
          Text(
            valueText,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          InkWell(
            onTap: onPlus,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.add, size: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rirDropdownDark(SetRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: row.rir,
        isDense: true,
        dropdownColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
        underline: const SizedBox(),
        items: [0, 1, 2, 3, 4, 5].map((v) {
          return DropdownMenuItem(
            value: v,
            child: Text(
              toPersianDigits('$v'),
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) {
            _dispatchIntent(UpdateSetWeightAndReps(setIndex: row.setNumber - 1, rir: v));
          }
        },
      ),
    );
  }

  // ─── RIR Banner ──────────────────────────────────────────────
  Widget _buildRirExplanationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'شاخص RIR (تکرار در زاپاس): تعداد تکراری که قبل از ناتوانی کامل عضلانی می‌توانید انجام دهید.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. FLOATING BOTTOM DOCK ─────────────────────────────────
  Widget _buildBottomFloatingDock(SSExerciseChecklistEntry entry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Previous exercise
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
            onPressed: _currentExerciseIndex > 0
                ? () => _dispatchIntent(const GoToPreviousExercise())
                : null,
          ),

          Expanded(
            child: _dockActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'تعویض',
              onTap: _showSwapBottomSheet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dockActionButton(
              icon: Icons.edit_note_rounded,
              label: 'یادداشت',
              onTap: _showNoteSheet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dockActionButton(
              icon: Icons.smart_toy_outlined,
              label: 'مربی AI',
              onTap: _showAiCoachSheet,
            ),
          ),

          // Next exercise
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
            onPressed: _currentExerciseIndex < _exercises.length - 1
                ? () => _dispatchIntent(const GoToNextExercise())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _dockActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. FULL-STAGE REST MODE OVERLAY ─────────────────────────
  Widget _buildRestingOverlay(SSWorkoutState state, SSExerciseChecklistEntry entry) {
    final progress = _restTotalSeconds > 0 ? (_restRemainingSeconds / _restTotalSeconds) : 0.0;
    final curIdx = entry.currentSetIndex;
    final hasNextSet = curIdx != -1 && curIdx + 1 < entry.setRows.length;
    final nextSet = hasNextSet ? entry.setRows[curIdx + 1] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19).withValues(alpha: 0.96),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'استراحت و تنفس عمیق 🧘‍♂️',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Giant Circular Progress Timer
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        backgroundColor: const Color(0xFF1E293B),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          toPersianDigits('$_restRemainingSeconds'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'ثانیه استراحت',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Timer Controls (+15s / Skip)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(
                        _isTimerPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      label: Text(
                        _isTimerPaused ? 'ادامه' : 'توقف',
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _dispatchIntent(const PauseResumeTimer()),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _dispatchIntent(const SkipRestTimer()),
                      child: const Text(
                        'شروع ست بعدی ⏭',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Up Next Set Preview Card
                if (nextSet != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141C2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ست بعدی: ست ${toPersianDigits(nextSet.setNumber.toString())}',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              entry.exercise.name,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _nextSetMetric('وزنه', toPersianDigits('${nextSet.weight.round()} kg')),
                            _nextSetMetric('تکرار', toPersianDigits('${nextSet.reps} تکرار')),
                            _nextSetMetric('RIR', toPersianDigits('${nextSet.rir}')),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nextSetMetric(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  // ─── OVERLAYS FOR WORKOUT STATES ─────────────────────────────
  Widget _buildPreparingOverlay(SSWorkoutState state) {
    if (state.exercises.isEmpty) return const SizedBox();
    final entry = state.exercises[state.currentExerciseIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19).withValues(alpha: 0.95),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'آماده باشید! حرکت اول',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 8),
              Text(
                entry.exercise.name,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SSExerciseAnimationCard(
                category: entry.exercise.category,
                exerciseId: entry.exercise.id,
                height: 200,
              ),
              const SizedBox(height: 32),
              Text(
                toPersianDigits('شروع تمرین تا ${state.timerRemainingSeconds} ثانیه...'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 22,
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'شروع بدون معطلی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _dispatchIntent(const SkipRestTimer()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay(SSWorkoutState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19).withValues(alpha: 0.96),
      body: Center(
        child: Text(
          toPersianDigits(state.timerRemainingSeconds.toString()),
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 140,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeSidesOverlay(SSWorkoutState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.96),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew_rounded, size: 90, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'تعویض جهت! 🔄',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'شروع حرکت برای سمت مقابل',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay(SSWorkoutState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19).withValues(alpha: 0.96),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉🏆✨', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'تمرین شما با موفقیت تمام شد!',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _finishAndLogWorkout,
              child: const Text(
                'مشاهده خلاصه تمرین',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HANDS-FREE HUD ──────────────────────────────────────────
  Widget _buildHandsFreeHud(SSExerciseChecklistEntry entry, SSWorkoutState state) {
    final curSetIdx = entry.currentSetIndex;
    final curSet = curSetIdx != -1 ? entry.setRows[curSetIdx] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: _onClosePressed,
                    ),
                    const Text(
                      'حالت ورزشی Hands-Free 🦾',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.zoom_out, color: Color(0xFFF59E0B)),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(ssWorkoutProvider(_key).notifier).toggleHandsFreeMode();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.exercise.name,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'درحال اجرای حرکت ${_currentExerciseIndex + 1} از ${_exercises.length}',
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.white38),
                      ),
                      const SizedBox(height: 36),

                      if (_isResting) ...[
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: _restTotalSeconds > 0 ? _restRemainingSeconds / _restTotalSeconds : 0.0,
                                strokeWidth: 6,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('استراحت', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                Text(
                                  toPersianDigits('$_restRemainingSeconds'),
                                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const Text('ثانیه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white38)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 68,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: const BorderSide(color: Colors.white24, width: 1.5),
                            ),
                            onPressed: () => _dispatchIntent(const SkipRestTimer()),
                            child: const Text(
                              'رد کردن استراحت ⏭',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ] else if (curSet != null) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141C2E),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ست شماره ${toPersianDigits(curSet.setNumber.toString())}',
                                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _handsFreeMetric('وزن هدف', '${curSet.weight}', 'کیلوگرم'),
                                  Container(width: 1, height: 60, color: Colors.white10),
                                  _handsFreeMetric('تکرار هدف', '${curSet.reps}', 'تکرار'),
                                  Container(width: 1, height: 60, color: Colors.white10),
                                  _handsFreeMetric('RIR هدف', '${curSet.rir}', 'زاپاس'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 76,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 28, color: Colors.white),
                            onPressed: () => _dispatchIntent(const CompleteCurrentSet()),
                            label: Text(
                              'ثبت ست ${toPersianDigits(curSet.setNumber.toString())}',
                              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handsFreeMetric(String title, String val, String unit) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white38)),
        const SizedBox(height: 6),
        Text(toPersianDigits(val), style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(unit, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white38)),
      ],
    );
  }
}

class _DarkHeaderCell extends StatelessWidget {
  const _DarkHeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
      ),
      textAlign: TextAlign.center,
    );
  }
}
