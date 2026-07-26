import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_controller.dart';

import 'package:ritmo/features/onboarding/presentation/steps/step_celebration.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_day_arc.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_first_routine.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_focus.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_identity.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_notifications.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_welcome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDraft();
    });
  }

  Future<void> _checkDraft() async {
    await _controller.checkAndLoadDraft();
    if (_controller.currentIndex > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ادامه آنبوردینگ از گام ${_controller.currentIndex + 1}',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStepWidget() {
    switch (_controller.currentIndex) {
      case 0:
        return StepWelcome(onStart: _controller.next);
      case 1:
        return StepIdentity(
          name: _controller.userName,
          onNameChanged: (val) {
            _controller.userName = val;
            _controller.notifyListeners();
          },
          gender: _controller.gender,
          onGenderChanged: (val) {
            _controller.gender = val;
            _controller.notifyListeners();
          },
          age: _controller.age,
          onAgeChanged: (val) {
            _controller.age = val;
            _controller.notifyListeners();
          },
        );
      case 2:
        return StepDayArc(
          wakeTime: _controller.wakeTime,
          onWakeTimeChanged: (val) {
            _controller.wakeTime = val;
            _controller.notifyListeners();
          },
          sleepTime: _controller.sleepTime,
          onSleepTimeChanged: (val) {
            _controller.sleepTime = val;
            _controller.notifyListeners();
          },
          isInferred: _controller.isDayArcInferred,
          reasonFa: _controller.dayArcReason,
        );
      case 3:
        return StepFocus(
          chosenAreas: _controller.focusAreas,
          onAreaToggled: _controller.toggleFocusArea,
          energyProfile: _controller.energyProfile,
          onEnergyChanged: (val) {
            _controller.energyProfile = val;
            _controller.notifyListeners();
          },
          isFemale: _controller.gender == 'FEMALE',
          enableCycle: _controller.enableCycle,
          onCycleToggled: (val) {
            _controller.enableCycle = val;
            _controller.notifyListeners();
          },
        );
      case 4:
        return StepFirstRoutine(
          suggestedTemplates: _controller.selectedStarterRoutines,
          onTemplateToggled: _controller.toggleStarterRoutine,
        );
      case 5:
        return StepNotifications(
          onFinished: () {
            _controller.notifAsked = true;
            _controller.notifGranted = true;
            _controller.next();
          },
        );
      case 6:
        return StepCelebration(
          name: _controller.userName,
          selectedRoutines: _controller.selectedStarterRoutines,
          onFinish: () => _controller.save(onFinished: widget.onFinished),
          isSaving: _controller.isSaving,
          errorMessage: _controller.errorMessage,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final idx = _controller.currentIndex;
        final isWelcome = idx == 0;
        final isCelebration = idx == 6;

        return PopScope(
          canPop: isWelcome,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _controller.prev();
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: AmbientBackground(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Top Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (idx > 0 && !isCelebration)
                            IconButton(
                              icon: Icon(
                                isRtl ? CupertinoIcons.chevron_forward : CupertinoIcons.chevron_back,
                                color: colors.textSecondary,
                              ),
                              tooltip: 'گام قبلی',
                              onPressed: _controller.prev,
                            )
                          else
                            const SizedBox(width: 48),
                          Text(
                            'ریتمو',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card container
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: FrostedGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 7-segment Progress Bar (Hidden on welcome step)
                                  if (!isWelcome) ...[
                                    Semantics(
                                      label: 'گام ${idx + 1} از 7',
                                      child: Row(
                                        children: List.generate(7, (index) {
                                          final isActive = index <= idx;
                                          return Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? const Color(0xff9B89FF)
                                                    : colors.textPrimary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Main Switcher Step Widget
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    layoutBuilder: (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          ...previousChildren,
                                          if (currentChild != null) currentChild,
                                        ],
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey<int>(idx),
                                      child: _buildStepWidget(),
                                    ),
                                  ),

                                  // Bottom Navigation inside Card
                                  if (idx > 0 && idx < 5) ...[
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: _controller.skipCurrentStep,
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(48, 48),
                                          ),
                                          child: Text(
                                            'بعداً تنظیم می‌کنم',
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 13,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: _controller.next,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xff9B89FF),
                                            disabledBackgroundColor: colors.textPrimary.withValues(alpha: 0.1),
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(120, 48),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'ادامه',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          children: [
            Container(color: colors.bg),
            Positioned(
              top: -120 + (t * 60),
              right: -60 + (t * 120),
              child: _GlowCircle(
                color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                size: 380,
              ),
            ),
            Positioned(
              bottom: -150 + (t * 100),
              left: -100 + (t * 50),
              child: _GlowCircle(
                color: const Color(0xff2DD4BF).withValues(alpha: isDark ? 0.15 : 0.08),
                size: 420,
              ),
            ),
            Positioned(
              top: 320 - (t * 80),
              left: 200 + (t * 60),
              child: _GlowCircle(
                color: colors.energyGradient[1].withValues(alpha: isDark ? 0.18 : 0.1),
                size: 320,
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.01)],
        ),
      ),
    );
  }
}

class FrostedGlassCard extends StatelessWidget {
  const FrostedGlassCard({
    super.key,
    required this.child,
    this.blur = 25,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
