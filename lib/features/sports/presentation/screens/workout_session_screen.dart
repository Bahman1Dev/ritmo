// lib/features/sports/presentation/screens/workout_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/presentation/providers/sports_providers.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

class WorkoutSessionScreen extends ConsumerWidget {

  const WorkoutSessionScreen({
    super.key,
    required this.sessionId,
    required this.title,
  });
  final String sessionId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSessionControllerProvider(sessionId));

    return state.when(
      loading: () => const Scaffold(
        backgroundColor: RitmoTheme.primaryBg,
        body: Center(child: CircularProgressIndicator(color: RitmoTheme.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: RitmoTheme.primaryBg,
        body: Center(child: Text('خطا: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (sessionState) => _SessionView(sessionState: sessionState, title: title),
    );
  }
}

class _SessionView extends ConsumerStatefulWidget {
  const _SessionView({required this.sessionState, required this.title});
  final WorkoutSessionState sessionState;
  final String title;

  @override
  ConsumerState<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends ConsumerState<_SessionView> {
  bool _restTimerVisible = false;
  int _restSeconds = 90;

  @override
  Widget build(BuildContext context) {
    final state = widget.sessionState;

    return Scaffold(
      backgroundColor: const Color(0xFF0A110E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white70, size: 22),
            onPressed: _toggleRestTimer,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            _buildProgressHeader(state),
            const SizedBox(height: 12),

            // Rest Timer Banner
            if (_restTimerVisible)
              _RestTimerBanner(
                seconds: _restSeconds,
                onSkip: () {
                  setState(() {
                    _restTimerVisible = false;
                    _restSeconds = 90;
                  });
                },
                onAdd: () => setState(() => _restSeconds += 30),
                onSub: () => setState(() => _restSeconds = (_restSeconds - 15).clamp(15, 300)),
              ),

            // Exercise List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.exercises.length,
                itemBuilder: (context, index) => _ExerciseCard(
                  exercise: state.exercises[index],
                  isCurrent: index == state.currentExerciseIndex,
                  onSetComplete: (set) => _onSetComplete(state.exercises[index].id, set),
                  onSwap: () => _showSwapSheet(state.exercises[index]),
                ),
              ),
            ),

            // Finish Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: state.isComplete ? _finishWorkout : _finishEarly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isComplete ? RitmoTheme.accent : Colors.white12,
                  foregroundColor: state.isComplete ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  state.isComplete ? 'پایان موفقیت‌آمیز تمرین 🎉' : 'پایان زودهنگام تمرین',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(WorkoutSessionState state) {
    final total = state.exercises.length;
    final done = state.exercises.where((e) => e.isPr).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Text('پیشرفت جلسه:', style: TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Vazirmatn')),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: total == 0 ? 0 : done / total,
                  child: Container(height: 6, decoration: BoxDecoration(color: RitmoTheme.accent, borderRadius: BorderRadius.circular(3))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$done/$total', style: const TextStyle(color: RitmoTheme.accent, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        ],
      ),
    );
  }

  Future<void> _onSetComplete(String exerciseId, PerformedSet set) async {
    RitmoHaptics.tap();
    final repo = await ref.read(sportsRepositoryProvider.future);
    await repo.savePerformedSet(set);

    // Check if exercise is complete
    setState(() {
      _restTimerVisible = true;
      _restSeconds = 90;
    });
    _tickRestTimer();
  }

  void _tickRestTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_restTimerVisible) return;
      if (_restSeconds <= 1) {
        setState(() => _restTimerVisible = false);
        return;
      }
      setState(() => _restSeconds--);
      _tickRestTimer();
    });
  }

  void _toggleRestTimer() {
    setState(() => _restTimerVisible = !_restTimerVisible);
  }

  void _showSwapSheet(PerformedExercise exercise) {
    // TODO: Implement exercise swap
  }

  Future<void> _finishWorkout() async {
    RitmoHaptics.success();
    final sessionId = widget.sessionState.session.id;
    await ref.read(workoutSessionControllerProvider(sessionId).notifier).finishWorkout();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _finishEarly() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('پایان زودهنگام؟', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        content: const Text('تمرین کامل نشده. مطمئنی می‌خوای تموم کنی؟', style: TextStyle(color: Colors.white70, fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف', style: TextStyle(color: Colors.white38, fontFamily: 'Vazirmatn'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله، تمومش کن', style: TextStyle(color: Colors.red, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm ?? false) {
      _finishWorkout();
    }
  }
}

class _RestTimerBanner extends StatefulWidget {

  const _RestTimerBanner({
    required this.seconds,
    required this.onSkip,
    required this.onAdd,
    required this.onSub,
  });
  final int seconds;
  final VoidCallback onSkip;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  @override
  State<_RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends State<_RestTimerBanner> {
  @override
  Widget build(BuildContext context) {
    final mins = widget.seconds ~/ 60;
    final secs = widget.seconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('⏱️ استراحت بین ست‌ها', style: TextStyle(fontSize: 13, color: Colors.orange, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              Text('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timerBtn('+30s', widget.onAdd, Icons.add),
              _timerBtn('-15s', widget.onSub, Icons.remove),
              _timerBtn(' رد کردن ', widget.onSkip, Icons.skip_next, isSkip: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerBtn(String label, VoidCallback onTap, IconData icon, {bool isSkip = false}) {
    return GestureDetector(
      onTap: () { RitmoHaptics.tap(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSkip ? Colors.white12 : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSkip ? Colors.white12 : Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSkip ? Colors.white54 : Colors.orange),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isSkip ? Colors.white54 : Colors.orange, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {

  const _ExerciseCard({
    required this.exercise,
    required this.isCurrent,
    required this.onSetComplete,
    required this.onSwap,
  });
  final PerformedExercise exercise;
  final bool isCurrent;
  final Function(PerformedSet) onSetComplete;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final isDone = exercise.isPr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? RitmoTheme.accent.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? RitmoTheme.accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exercise Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent ? RitmoTheme.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCurrent ? Icons.fitness_center : (isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                  color: isCurrent ? RitmoTheme.accent : (isDone ? Colors.green : Colors.white38),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      '${exercise.primaryMuscle.emoji} ${exercise.primaryMuscle.label}',
                      style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('✓ تمام', style: TextStyle(fontSize: 10, color: Colors.green, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Sets
          // Sets placeholder (sets managed via state)


          // Add set button (if not done)
          if (!isDone) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _addSet(exercise.id),
              icon: const Icon(Icons.add, size: 18, color: RitmoTheme.accent),
              label: const Text('افزودن ست', style: TextStyle(color: RitmoTheme.accent, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ],
        ],
      ),
    );
  }

  void _addSet(String exerciseId) {
    // TODO: Add set logic
  }
}
