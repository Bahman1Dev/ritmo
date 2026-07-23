import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_celebration.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_day_arc.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_first_routine.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_focus.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_identity.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_notifications.dart';
import 'package:ritmo/features/onboarding/presentation/steps/step_welcome.dart';
import 'package:sqflite/sqflite.dart';

class OnboardingScreen extends StatefulWidget {

  const OnboardingScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0; // Ranges from 0 to 6 (7 steps total)

  // Shared Onboarding State
  String _userName = '';
  String _selectedGender = 'PREFER_NOT_TO_SAY';
  int _selectedAge = 25;

  String _wakeTime = '07:00';
  String _sleepTime = '23:00';

  final Map<String, bool> _focusAreas = {
    'سلامتی': false,
    'ورزش': false,
    'درس': false,
    'کار': false,
    'کسب درآمد': false,
    'خانواده': false,
    'عبادت': false,
    'خواب': false,
    'کاهش استرس': false,
    'یادگیری مهارت': false,
  };

  final Map<String, bool> _enabledModules = {
    'module_medicine_enabled': false,
    'module_courses_enabled': false,
    'module_konkur_enabled': false,
    'module_goals_enabled': false,
    'module_sports_enabled': false,
    'module_religion_enabled': false,
  };

  String _selectedEnergyProfile = 'MEDIUM';

  String _firstRoutineTitle = '💧 نوشیدن آب';
  int _firstRoutineDuration = 2;
  Category _firstRoutineCategory = Category.fitness;
  TimeOfDay _firstRoutineTime = const TimeOfDay(hour: 8, minute: 0);


  void _nextPage() {
    if (_currentIndex < 6) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _toggleFocusArea(String area) {
    setState(() {
      final newVal = !(_focusAreas[area] ?? false);
      _focusAreas[area] = newVal;

      // Map to suggested modules by default
      if (area == 'سلامتی') {
        _enabledModules['module_medicine_enabled'] = newVal;
      }
      if (area == 'درس' || area == 'یادگیری مهارت') {
        final hasStudy = (_focusAreas['درس'] ?? false) || (_focusAreas['یادگیری مهارت'] ?? false);
        _enabledModules['module_courses_enabled'] = hasStudy;
      }
      if (area == 'کار' || area == 'کسب درآمد') {
        final hasWork = (_focusAreas['کار'] ?? false) || (_focusAreas['کسب درآمد'] ?? false);
        _enabledModules['module_goals_enabled'] = hasWork;
      }
      if (area == 'ورزش') {
        _enabledModules['module_sports_enabled'] = newVal;
      }
      if (area == 'عبادت') {
        _enabledModules['module_religion_enabled'] = newVal;
      }
    });
  }

  void _toggleModule(String key) {
    setState(() {
      _enabledModules[key] = !(_enabledModules[key] ?? false);
    });
  }

  bool get _isNextButtonEnabled {
    switch (_currentIndex) {
      case 1: // Identity
        return _userName.trim().isNotEmpty;
      case 3: // Focus
        return _focusAreas.values.any((v) => v);
      case 4: // First Routine
        return _firstRoutineTitle.trim().isNotEmpty;
      default:
        return true;
    }
  }

  bool get _canSkip {
    // Steps 1 to 4 (Identity, Day Arc, Focus, First Routine) can be skipped
    return _currentIndex >= 1 && _currentIndex <= 4;
  }

  void _skipCurrentPage() {
    HapticFeedback.mediumImpact();
    setState(() {
      switch (_currentIndex) {
        case 1: // Identity
          _userName = 'کاربر ریتمو';
          _selectedGender = 'PREFER_NOT_TO_SAY';
          _selectedAge = 25;
        case 2: // Day Arc
          _wakeTime = '07:00';
          _sleepTime = '23:00';
        case 3: // Focus
          _focusAreas.forEach((k, v) => _focusAreas[k] = (k == 'سلامتی'));
          _enabledModules.forEach((k, v) => _enabledModules[k] = (k == 'module_medicine_enabled'));
          _selectedEnergyProfile = 'MEDIUM';
        case 4: // First Routine
          _firstRoutineTitle = '💧 نوشیدن آب';
          _firstRoutineDuration = 2;
          _firstRoutineCategory = Category.fitness;
          _firstRoutineTime = const TimeOfDay(hour: 8, minute: 0);
      }
      _currentIndex++;
    });
  }

  Future<void> _saveAndFinish() async {
    HapticFeedback.heavyImpact();

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Check if onboarding was already completed once
      final onboardingCompletedSetting = await db.query(
        'app_settings',
        where: "key = 'onboarding_completed'",
      );
      final isFirstOnboarding = onboardingCompletedSetting.isEmpty;

      // 2. Save settings map
      final settingsMap = {
        'user_name': _userName.isNotEmpty ? _userName : 'کاربر ریتمو',
        'user_gender': _selectedGender,
        'user_age': _selectedAge.toString(),
        'wake_time': _wakeTime,
        'sleep_time': _sleepTime,
        'primary_focus_areas': jsonEncode(_focusAreas.entries.where((e) => e.value).map((e) => e.key).toList()),
        'energy_profile': _selectedEnergyProfile,
        'default_energy_level': _selectedEnergyProfile,
        'smart_suggestions_enabled': 'true',
        'module_assistant_enabled': 'true',
        'module_religion_enabled': (_enabledModules['module_religion_enabled'] ?? false).toString(),
        'module_medicine_enabled': (_enabledModules['module_medicine_enabled'] ?? false).toString(),
        'module_courses_enabled': (_enabledModules['module_courses_enabled'] ?? false).toString(),
        'module_konkur_enabled': (_enabledModules['module_konkur_enabled'] ?? false).toString(),
        'module_goals_enabled': (_enabledModules['module_goals_enabled'] ?? false).toString(),
        'module_sports_enabled': (_enabledModules['module_sports_enabled'] ?? false).toString(),
        'module_cycle_enabled': 'false',
        'notif_permission_asked': 'true',
      };

      final settingsBatch = db.batch();
      settingsMap.forEach((key, value) {
        settingsBatch.insert(
          'app_settings',
          {'key': key, 'value': value, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      await settingsBatch.commit(noResult: true);

      // 3. Clear database tables ONLY on first onboarding to prevent wiping existing user data
      if (isFirstOnboarding) {
        await db.delete('zones');
        await db.delete('zone_schedules');
        await db.delete('routines');
        await db.delete('routine_schedules');
      }

      await db.insert(
        'app_settings',
        {'key': 'onboarding_completed', 'value': 'true', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Save first routine (Generate unique IDs)
      final routineId = 'routine_$now';
      final scheduleId = 'sched_$routineId';

      // Insert routine
      await db.insert('routines', {
        'id': routineId,
        'title': _firstRoutineTitle,
        'description': 'اولین روتین ثبت‌شده در آنبوردینگ',
        'category': _firstRoutineCategory.name,
        'routineType': RoutineType.timeBased.name,
        'notificationLevel': NotificationLevel.normal.name,
        'isEssential': _firstRoutineCategory == Category.medical ? 1 : 0,
        'energyRule': EnergyRule.none.name,
        'priority': 1.0,
        'targetDurationMinutes': _firstRoutineDuration,
        'displayOrder': 1,
        'createdAt': now,
        'updatedAt': now,
      });

      // Insert schedule
      final rHourStr = _firstRoutineTime.hour.toString().padLeft(2, '0');
      final rMinStr = _firstRoutineTime.minute.toString().padLeft(2, '0');
      await db.insert('routine_schedules', {
        'id': scheduleId,
        'routineId': routineId,
        'scheduleType': _firstRoutineCategory == Category.religious ? 'PRAYER_TIME' : 'DAILY',
        'timeOfDay': '$rHourStr:$rMinStr',
        'anchorEvent': _firstRoutineCategory == Category.religious ? 'FAJR' : null,
        'anchorOffsetMinutes': 0,
        'createdAt': now,
        'updatedAt': now,
      });

      // Update widget snapshots & alarm configurations
      await SnapshotHelper.updateWidgetSnapshot(
        nextActionTitle: _firstRoutineTitle,
        rhythmScore: 0,
        currentEnergyLevel: 'MEDIUM',
      );

      await AlarmSchedulerService.scheduleNextAlarms();

      widget.onFinished();
    } catch (e, stack) {
      debugPrint('CRITICAL ERROR IN ONBOARDING SAVE: $e\n$stack');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا در ثبت اطلاعات', style: TextStyle(fontFamily: 'Vazirmatn')),
            content: SingleChildScrollView(
              child: Text(
                'متاسفانه خطایی در ذخیره اطلاعات رخ داد:\n$e',
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                textDirection: TextDirection.rtl,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      }

  }
}

  Widget _buildStepWidget() {
    switch (_currentIndex) {
      case 0:
        return StepWelcome(onStart: _nextPage);
      case 1:
        return StepIdentity(
          name: _userName,
          onNameChanged: (val) => setState(() => _userName = val),
          gender: _selectedGender,
          onGenderChanged: (val) => setState(() => _selectedGender = val),
          age: _selectedAge,
          onAgeChanged: (val) => setState(() => _selectedAge = val),
        );
      case 2:
        return StepDayArc(
          wakeTime: _wakeTime,
          onWakeTimeChanged: (val) => setState(() => _wakeTime = val),
          sleepTime: _sleepTime,
          onSleepTimeChanged: (val) => setState(() => _sleepTime = val),
        );
      case 3:
        return StepFocus(
          focusAreas: _focusAreas,
          onFocusAreaToggled: _toggleFocusArea,
          enabledModules: _enabledModules,
          onModuleToggled: _toggleModule,
          energyProfile: _selectedEnergyProfile,
          onEnergyProfileChanged: (val) => setState(() => _selectedEnergyProfile = val),
        );
      case 4:
        return StepFirstRoutine(
          wakeTime: _wakeTime,
          sleepTime: _sleepTime,
          firstRoutineTitle: _firstRoutineTitle,
          onTitleChanged: (val) => setState(() => _firstRoutineTitle = val),
          duration: _firstRoutineDuration,
          onDurationChanged: (val) => setState(() => _firstRoutineDuration = val),
          category: _firstRoutineCategory,
          onCategoryChanged: (val) => setState(() => _firstRoutineCategory = val),
          routineTime: _firstRoutineTime,
          onTimeChanged: (val) => setState(() => _firstRoutineTime = val),
        );
      case 5:
        return StepNotifications(onFinished: _nextPage);
      case 6:
        return StepCelebration(
          name: _userName,
          enabledSystemsCount: _enabledModules.values.where((v) => v).length,
          onFinish: _saveAndFinish,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (Farsi text style)
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer to balance back button
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
                    if (_currentIndex > 0 && _currentIndex < 6)
                      IconButton(
                        icon: Icon(CupertinoIcons.right_chevron, color: colors.textSecondary),
                        onPressed: _prevPage,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),

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
                            // 7-segment Progress Bar
                            Row(
                              children: List.generate(7, (index) {
                                final isActive = index <= _currentIndex;
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
                            const SizedBox(height: 24),

                            // Main Switcher Step Widget
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: KeyedSubtree(
                                key: ValueKey<int>(_currentIndex),
                                child: _buildStepWidget(),
                              ),
                            ),

                            // Bottom Navigation inside Card (if welcome / celebration steps are not active)
                            if (_currentIndex > 0 && _currentIndex < 6) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Skip Button
                                  if (_canSkip)
                                    TextButton(
                                      onPressed: _skipCurrentPage,
                                      child: Text(
                                        'رد کردن',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 14,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 48),

                                  // Next / Continue Button
                                  if (_currentIndex != 5) // Step 5 has its own custom button triggers
                                    ElevatedButton(
                                      onPressed: _isNextButtonEnabled ? _nextPage : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xff9B89FF),
                                        disabledBackgroundColor: colors.textPrimary.withValues(alpha: 0.1),
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: colors.textPrimary.withValues(alpha: 0.3),
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
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

            // Ice Blue Glow
            Positioned(
              top: -120 + (t * 60),
              right: -60 + (t * 120),
              child: _GlowCircle(
                color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                size: 380,
              ),
            ),

            // Soft Turquoise Glow
            Positioned(
              bottom: -150 + (t * 100),
              left: -100 + (t * 50),
              child: _GlowCircle(
                color: const Color(0xff2DD4BF).withValues(alpha: isDark ? 0.15 : 0.08),
                size: 420,
              ),
            ),

            // Lavender Glow
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
