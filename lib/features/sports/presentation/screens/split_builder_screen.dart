// lib/features/sports/presentation/screens/split_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/sports/presentation/providers/sports_providers.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

class SplitBuilderScreen extends ConsumerWidget {
  const SplitBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitBuilderControllerProvider);

    return Scaffold(
      backgroundColor: RitmoTheme.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('سازنده برنامه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          if (state.currentStep.index > 0)
            TextButton(
              onPressed: () => ref.read(splitBuilderControllerProvider.notifier).prevStep(),
              child: const Text('قبلی', style: TextStyle(color: Colors.white70, fontFamily: 'Vazirmatn', fontSize: 13)),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Step Indicator
            _buildStepIndicator(state),
            const SizedBox(height: 24),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStepContent(context, ref, state),
              ),
            ),

            // Navigation Buttons
            _buildNavigationButtons(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(SplitBuilderState state) {
    return Column(
      children: [
        Row(
          children: SplitBuilderStep.values.map((step) {
            final isActive = step.index <= state.currentStep.index;
            final isCurrent = step == state.currentStep;
            return Expanded(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 28 : 20,
                    height: isCurrent ? 28 : 20,
                    decoration: BoxDecoration(
                      color: isActive ? RitmoTheme.accent : Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? RitmoTheme.accent : Colors.white12, width: 2),
                    ),
                    child: isActive
                        ? Center(child: Text('${step.index + 1}', style: TextStyle(fontSize: isCurrent ? 12 : 10, fontWeight: FontWeight.bold, color: isCurrent ? Colors.black : Colors.white, fontFamily: 'Vazirmatn')))
                        : null,
                  ),
                  if (step != SplitBuilderStep.review)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isActive ? RitmoTheme.accent : Colors.white12,
                      ),
                    ),
                ],
              ),
            );
            }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          state.currentStep.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
        ),
        Text(
          _stepDescription(state.currentStep),
          style: const TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Vazirmatn'),
        ),
      ],
    );
  }

  String _stepDescription(SplitBuilderStep step) {
    switch (step) {
      case SplitBuilderStep.goal: return 'هدف اصلی تمریناتت چیه؟';
      case SplitBuilderStep.frequency: return 'چند روز در هفته می‌تونی تمرین کنی؟';
      case SplitBuilderStep.days: return 'کدوم روزها رو ترجیح میدی؟';
      case SplitBuilderStep.location: return 'تمریناتتو کجا انجام میدی؟';
      case SplitBuilderStep.advanced: return 'تنظیمات پیشرفته (اختیاری)';
      case SplitBuilderStep.review: return 'بررسی نهایی و ذخیره برنامه';
    }
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, SplitBuilderState state) {
    switch (state.currentStep) {
      case SplitBuilderStep.goal: return _GoalStep(onChanged: (g) => ref.read(splitBuilderControllerProvider.notifier).setGoal(g), current: state.goal);
      case SplitBuilderStep.frequency: return _FrequencyStep(onChanged: (f) => ref.read(splitBuilderControllerProvider.notifier).setFrequency(f), current: state.frequency);
      case SplitBuilderStep.days: return _DaysStep(onChanged: (days) => ref.read(splitBuilderControllerProvider.notifier).toggleDay(days.first), current: state.selectedDays);
      case SplitBuilderStep.location: return _LocationStep(onChanged: (l) => ref.read(splitBuilderControllerProvider.notifier).setLocation(l), current: state.location);
      case SplitBuilderStep.advanced: return _AdvancedStep(state: state, onChanged: ref.read(splitBuilderControllerProvider.notifier));
      case SplitBuilderStep.review: return _ReviewStep(state: state, onSave: () => ref.read(splitBuilderControllerProvider.notifier).saveSplit());
    }
  }

  Widget _buildNavigationButtons(BuildContext context, WidgetRef ref, SplitBuilderState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          if (state.currentStep.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => ref.read(splitBuilderControllerProvider.notifier).prevStep(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('قبلی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          if (state.currentStep.index > 0) const SizedBox(width: 12),
          Expanded(
            flex: state.currentStep.index > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: state.currentStep == SplitBuilderStep.review
                  ? () => ref.read(splitBuilderControllerProvider.notifier).saveSplit()
                  : () => ref.read(splitBuilderControllerProvider.notifier).nextStep(),
              style: ElevatedButton.styleFrom(
                backgroundColor: RitmoTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                state.currentStep == SplitBuilderStep.review ? 'ذخیره و شروع ⚡' : 'ادامه ➡️',
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step Widgets
// ──────────────────────────────────────────────────────────────

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.onChanged, required this.current});
  final ValueChanged<WorkoutGoal> onChanged;
  final WorkoutGoal current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: WorkoutGoal.values.map((g) => _GoalCard(goal: g, isSelected: current == g, onTap: () => onChanged(g))).toList(),
    );
  }
}

class _GoalCard extends StatelessWidget {

  const _GoalCard({required this.goal, required this.isSelected, required this.onTap});
  final WorkoutGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  String _icon() => switch (goal) {
    WorkoutGoal.hypertrophy => '💪',
    WorkoutGoal.strength => '🏋️',
    WorkoutGoal.power => '⚡',
    WorkoutGoal.fitness => '🏃',
    WorkoutGoal.fatLoss => '🔥',
  };

  String _desc() => switch (goal) {
    WorkoutGoal.hypertrophy => 'بزرگی عضله و شکل بدن',
    WorkoutGoal.strength => 'قدرت حداکثر و پرس سنگین',
    WorkoutGoal.power => 'قدرت انفجاری و سرعت',
    WorkoutGoal.fitness => 'سلامت عمومی و فیتنس',
    WorkoutGoal.fatLoss => 'سوزاندن چربی + حفظ عضله',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? RitmoTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? RitmoTheme.accent : Colors.white12, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Text(_icon(), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(goal.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? RitmoTheme.accent : Colors.white, fontFamily: 'Vazirmatn')),
                  const SizedBox(height: 4),
                  Text(_desc(), style: const TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Vazirmatn')),
                ]),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: RitmoTheme.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyStep extends StatelessWidget {
  const _FrequencyStep({required this.onChanged, required this.current});
  final ValueChanged<int> onChanged;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [3, 4, 5, 6].map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => onChanged(f),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: current == f ? RitmoTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: current == f ? RitmoTheme.accent : Colors.white12, width: current == f ? 1.5 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$f روز در هفته', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: current == f ? RitmoTheme.accent : Colors.white, fontFamily: 'Vazirmatn')),
                if (current == f) const Icon(Icons.check_circle, color: RitmoTheme.accent, size: 22),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _DaysStep extends StatelessWidget {
  const _DaysStep({required this.onChanged, required this.current});
  final ValueChanged<List<int>> onChanged;
  final List<int> current;

  @override
  Widget build(BuildContext context) {
    const days = [
      (1, 'دوشنبه', 'Mon'),
      (2, 'سه‌شنبه', 'Tue'),
      (3, 'چهارشنبه', 'Wed'),
      (4, 'پنج‌شنبه', 'Thu'),
      (5, 'جمعه', 'Fri'),
      (6, 'شنبه', 'Sat'),
      (7, 'یکشنبه', 'Sun'),
    ];

    return Column(
      children: days.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            final newList = List<int>.from(current);
            if (newList.contains(d.$1)) {
              newList.remove(d.$1);
            } else {
              newList.add(d.$1);
            }
            onChanged(newList);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: current.contains(d.$1) ? RitmoTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: current.contains(d.$1) ? RitmoTheme.accent : Colors.white12, width: current.contains(d.$1) ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Text(d.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: current.contains(d.$1) ? RitmoTheme.accent : Colors.white, fontFamily: 'Vazirmatn')),
                const Spacer(),
                if (current.contains(d.$1)) const Icon(Icons.check_circle, color: RitmoTheme.accent, size: 22),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.onChanged, required this.current});
  final ValueChanged<SportsLocation> onChanged;
  final SportsLocation current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: SportsLocation.values.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => onChanged(l),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: current == l ? RitmoTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: current == l ? RitmoTheme.accent : Colors.white12, width: current == l ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Text(l.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: current == l ? RitmoTheme.accent : Colors.white, fontFamily: 'Vazirmatn')),
                  const SizedBox(height: 2),
                  Text(l == SportsLocation.home ? 'بدون تجهیز، دمبل، باند،TRX' : 'دستگاه، هالتر، دمبل، کابل', style: const TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Vazirmatn')),
                ])),
                if (current == l) const Icon(Icons.check_circle, color: RitmoTheme.accent, size: 24),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _AdvancedStep extends StatelessWidget {
  const _AdvancedStep({required this.state, required this.onChanged});
  final SplitBuilderState state;
  final dynamic onChanged;

  @override
  Widget build(BuildContext context) {
    final notifier = onChanged as dynamic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown('طول مسوسیکل (هفته)', state.mesocycleWeeks, [4, 5, 6, 7, 8], notifier.setMesocycleWeeks),
        const SizedBox(height: 16),
        _buildDropdown('نوع پیشرفت', state.progressionType, ProgressionType.values, notifier.setProgression),
        const SizedBox(height: 16),
        _buildDropdown('فرکانس دیلود (هر چند هفته)', state.deloadFrequency, [3, 4, 5, 6], notifier.setDeloadFreq),
      ],
    );
  }

  Widget _buildDropdown<T>(String label, T current, List<T> options, ValueChanged<T> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: current,
              dropdownColor: const Color(0xFF0D1A15),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: RitmoTheme.accent),
              style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: 14),
              items: options.map((v) => DropdownMenuItem(value: v, child: Text(v.toString().split('.').last))).toList(),
              onChanged: (v) => onChanged(v as T),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.onSave});
  final SplitBuilderState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewCard('هدف', state.goal.label),
        _ReviewCard('فرکانس', '${state.frequency} روز در هفته'),
        _ReviewCard('روزها', state.selectedDays.map(_dayName).join('، ')),
        _ReviewCard('محل', state.location.label),
        _ReviewCard('مسوسیکل', '${state.mesocycleWeeks} هفته'),
        _ReviewCard('پیشرفت', state.progressionType.label),
        _ReviewCard('دیلود', 'هر ${state.deloadFrequency} هفته'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(backgroundColor: RitmoTheme.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: const Text('ذخیره و شروع برنامه ⚡', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String _dayName(int d) => const {1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه', 5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه'}[d]!;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(this.title, this.value);
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Vazirmatn')),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
      ],
    ),
  );
}