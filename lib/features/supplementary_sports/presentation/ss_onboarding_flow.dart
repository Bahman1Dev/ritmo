import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SSOnboardingFlow extends StatefulWidget {
  const SSOnboardingFlow({super.key});

  @override
  State<SSOnboardingFlow> createState() => _SSOnboardingFlowState();
}

class _SSOnboardingFlowState extends State<SSOnboardingFlow> {
  int _currentStep = 1;
  final int _totalSteps = 8;
  late final PageController _pageController;

  // Selected Values
  String _selectedGender = 'MALE';
  double _heightCm = 175;
  double _weightKg = 70;
  FitnessGoal? _selectedGoal = FitnessGoal.bodyRecomposition;
  ExperienceLevel? _selectedLevel = ExperienceLevel.beginner;
  TrainingLocation _selectedLocation = TrainingLocation.home;
  final Set<Equipment> _selectedEquipment = {Equipment.bodyweightOnly};
  final Set<BodyArea> _selectedFocusAreas = {BodyArea.fullBody};
  final Set<Limitation> _selectedLimitations = {Limitation.none};
  int _selectedDays = 3;
  int _selectedMinutes = 45;

  bool _isGeneratingPlan = false;
  int _generationStage = 0; // 0 to 4

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadStateFromPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- State Persistence & Gender Sync ---
  Future<void> _loadStateFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Auto-fetch gender from main app settings & SQLite tables
      try {
        final g = await DatabaseHelper.instance.getUserGender();
        if (g == 'FEMALE' || g == 'MALE') {
          _selectedGender = g;
        }
      } catch (_) {}

      final savedStep = prefs.getInt('ss_onboarding_step');
      if (savedStep != null && savedStep > 0 && savedStep <= _totalSteps) {
        setState(() {
          _currentStep = savedStep;
          _heightCm = prefs.getDouble('ss_onboarding_height') ?? 175;
          _weightKg = prefs.getDouble('ss_onboarding_weight') ?? 70;

          final savedGoal = prefs.getString('ss_onboarding_goal');
          if (savedGoal != null) {
            _selectedGoal = FitnessGoal.values.firstWhere(
              (e) => e.toString() == savedGoal,
              orElse: () => FitnessGoal.bodyRecomposition,
            );
          }

          final savedExp = prefs.getString('ss_onboarding_experience');
          if (savedExp != null) {
            _selectedLevel = ExperienceLevel.values.firstWhere(
              (e) => e.toString() == savedExp,
              orElse: () => ExperienceLevel.beginner,
            );
          }

          final savedLoc = prefs.getString('ss_onboarding_location');
          if (savedLoc != null) {
            _selectedLocation = TrainingLocation.values.firstWhere(
              (e) => e.toString() == savedLoc,
              orElse: () => TrainingLocation.home,
            );
          }

          _selectedDays = prefs.getInt('ss_onboarding_days') ?? 3;
          _selectedMinutes = prefs.getInt('ss_onboarding_duration_minutes') ?? 45;

          final savedEquip = prefs.getStringList('ss_onboarding_equipment');
          if (savedEquip != null) {
            _selectedEquipment.clear();
            for (final eqStr in savedEquip) {
              final eq = Equipment.values.firstWhere(
                (e) => e.toString() == eqStr,
                orElse: () => Equipment.bodyweightOnly,
              );
              _selectedEquipment.add(eq);
            }
          }

          final savedFocus = prefs.getStringList('ss_onboarding_focus_areas');
          if (savedFocus != null) {
            _selectedFocusAreas.clear();
            for (final arStr in savedFocus) {
              final ar = BodyArea.values.firstWhere(
                (e) => e.toString() == arStr,
                orElse: () => BodyArea.fullBody,
              );
              _selectedFocusAreas.add(ar);
            }
          }

          final savedLimit = prefs.getStringList('ss_onboarding_limitations');
          if (savedLimit != null) {
            _selectedLimitations.clear();
            for (final limStr in savedLimit) {
              final lim = Limitation.values.firstWhere(
                (e) => e.toString() == limStr,
                orElse: () => Limitation.none,
              );
              _selectedLimitations.add(lim);
            }
          }
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentStep - 1);
        }
      }
    } catch (e) {
      debugPrint('Error loading state from preferences: $e');
    }
  }

  Future<void> _saveStateToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ss_onboarding_step', _currentStep);
      await prefs.setDouble('ss_onboarding_height', _heightCm);
      await prefs.setDouble('ss_onboarding_weight', _weightKg);
      if (_selectedGoal != null) {
        await prefs.setString('ss_onboarding_goal', _selectedGoal.toString());
      }
      if (_selectedLevel != null) {
        await prefs.setString('ss_onboarding_experience', _selectedLevel.toString());
      }
      await prefs.setString('ss_onboarding_location', _selectedLocation.toString());
      await prefs.setInt('ss_onboarding_days', _selectedDays);
      await prefs.setInt('ss_onboarding_duration_minutes', _selectedMinutes);
      await prefs.setStringList(
        'ss_onboarding_equipment',
        _selectedEquipment.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        'ss_onboarding_focus_areas',
        _selectedFocusAreas.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        'ss_onboarding_limitations',
        _selectedLimitations.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving state to preferences: $e');
    }
  }

  Future<void> _clearOnboardingPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ss_onboarding_step');
      await prefs.remove('ss_onboarding_height');
      await prefs.remove('ss_onboarding_weight');
      await prefs.remove('ss_onboarding_goal');
      await prefs.remove('ss_onboarding_experience');
      await prefs.remove('ss_onboarding_location');
      await prefs.remove('ss_onboarding_days');
      await prefs.remove('ss_onboarding_duration_minutes');
      await prefs.remove('ss_onboarding_equipment');
      await prefs.remove('ss_onboarding_focus_areas');
      await prefs.remove('ss_onboarding_limitations');
    } catch (e) {
      debugPrint('Error clearing onboarding prefs: $e');
    }
  }

  void _nextStep() {
    RitmoHaptics.selection();
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _saveStateToPreferences();
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    RitmoHaptics.selection();
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _saveStateToPreferences();
    } else {
      Navigator.pop(context);
    }
  }

  // --- Plan & Profile Generation ---
  Future<void> _finishOnboarding() async {
    RitmoHaptics.confirm();
    setState(() {
      _isGeneratingPlan = true;
      _generationStage = 1;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final profile = SsUserProfile(
        goal: _selectedGoal ?? FitnessGoal.bodyRecomposition,
        experienceLevel: _selectedLevel ?? ExperienceLevel.beginner,
        trainingLocation: _selectedLocation,
        availableEquipment: _selectedEquipment.toList(),
        daysPerWeek: _selectedDays,
        focusAreas: _selectedFocusAreas.toList(),
        physicalLimitations: _selectedLimitations.toList(),
        sessionDuration: _selectedMinutes == 30 
            ? SessionDuration.short30 
            : _selectedMinutes == 60 
                ? SessionDuration.long60 
                : SessionDuration.medium45,
        gender: _selectedGender,
        onboardingCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      // Save Profile
      await db.insert(
        'ss_user_profile',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Also sync gender with main app user_settings
      try {
        await db.insert(
          'app_settings',
          {'key': 'user_gender', 'value': _selectedGender},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}

      // Interactive 4-week generation with stage updates
      setState(() => _generationStage = 1);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 1);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      setState(() => _generationStage = 2);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 2);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      setState(() => _generationStage = 3);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 3);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      setState(() => _generationStage = 4);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 4);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await _clearOnboardingPreferences();

      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SSHomeDashboardScreen()),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error finishing onboarding flow: $e');
      if (mounted) {
        RitmoToast.show(context, 'خطا در ساخت برنامه: $e', icon: Icons.error_outline);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPlan = false;
        });
      }
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return _buildStep2Bmi();
      case 2:
        return _buildStep3Goal();
      case 3:
        return _buildStep4Experience();
      case 4:
        return _buildStep5Location();
      case 5:
        return _buildStep6FocusAreas();
      case 6:
        return _buildStep7Equipment();
      case 7:
        return _buildStep8Limitations();
      case 8:
        return _buildStep9DurationAndDays();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isGeneratingPlan) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Center(
              child: _AiPlanBuildingProgressView(
                currentStage: _generationStage,
                colors: colors,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: _prevStep,
          tooltip: 'بازگشت',
        ),
        title: Text(
          toPersianDigits('مرحله $_currentStep از $_totalSteps'),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentStep / _totalSteps,
                    backgroundColor: colors.card,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _totalSteps,
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: _buildStepContent(index + 1),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  label: _currentStep == _totalSteps ? 'شروع برنامه اختصاصی ✨' : 'ادامه',
                  onPressed: _isStepValid() ? _nextStep : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 1:
        return true;
      case 2:
        return _selectedGoal != null;
      case 3:
        return _selectedLevel != null;
      case 4:
        return true;
      case 5:
        return _selectedFocusAreas.isNotEmpty;
      case 6:
        return _selectedEquipment.isNotEmpty;
      case 7:
        return _selectedLimitations.isNotEmpty;
      case 8:
        return true;
      default:
        return true;
    }
  }

  // --- Step 1: Physical Specs & BMI Spectrum ---
  Widget _buildStep2Bmi() {
    final colors = context.colors;
    final bmi = _weightKg / ((_heightCm / 100) * (_heightCm / 100));
    var category = 'وزن نرمال';
    var categoryColor = colors.success;
    if (bmi < 18.5) {
      category = 'کمبود وزن';
      categoryColor = colors.primary;
    } else if (bmi >= 25 && bmi < 30) {
      category = 'اضافه وزن';
      categoryColor = colors.warning;
    } else if (bmi >= 30) {
      category = 'چاقی';
      categoryColor = colors.medicalRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مشخصات فیزیکی',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'قد و وزن به ما کمک می‌کنه شاخص توده بدنی (BMI) و کالری مصرفی رو دقیق‌تر حساب کنیم.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        
        // BMI Gauge & Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.rtl,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text('شاخص توده بدنی (BMI)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        toPersianDigits(bmi.toStringAsFixed(1)),
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 28, fontWeight: FontWeight.bold, color: categoryColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: categoryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Interactive Spectrum Gauge
              _BmiSpectrumGauge(bmi: bmi, colors: colors),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('قد: ${toPersianDigits(_heightCm.toInt().toString())} سانتی‌متر', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        Slider(
          value: _heightCm,
          min: 130,
          max: 220,
          divisions: 90,
          activeColor: colors.primary,
          onChanged: (val) {
            RitmoHaptics.selection();
            setState(() => _heightCm = val);
          },
        ),
        const SizedBox(height: 16),
        Text('وزن: ${toPersianDigits(_weightKg.toInt().toString())} کیلوگرم', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        Slider(
          value: _weightKg,
          min: 40,
          max: 160,
          divisions: 120,
          activeColor: colors.primary,
          onChanged: (val) {
            RitmoHaptics.selection();
            setState(() => _weightKg = val);
          },
        ),
        const SizedBox(height: 16),
        Text('جنسیت:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  RitmoHaptics.selection();
                  setState(() => _selectedGender = 'FEMALE');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'FEMALE' ? colors.primary : colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _selectedGender == 'FEMALE' ? colors.primary : colors.border),
                  ),
                  child: Center(
                    child: Text(
                      '👩‍🦰 خانم',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'FEMALE' ? Colors.white : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  RitmoHaptics.selection();
                  setState(() => _selectedGender = 'MALE');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'MALE' ? colors.primary : colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _selectedGender == 'MALE' ? colors.primary : colors.border),
                  ),
                  child: Center(
                    child: Text(
                      '👨 آقا',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'MALE' ? Colors.white : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 2: Goal ---
  Widget _buildStep3Goal() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'هدف اصلی ورزشی شما چیه؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'برنامه بر اساس هدف شما تنظیم می‌شه.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'کاهش وزن و چربی‌سوزی 🎯',
          icon: '🔥',
          isSelected: _selectedGoal == FitnessGoal.fatLoss,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.fatLoss),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'عضله‌سازی و افزایش حجم 💪',
          icon: '🏋️‍♂️',
          isSelected: _selectedGoal == FitnessGoal.muscleGain,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.muscleGain),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'بازسازی بدنی و تناسب اندام ⚖️',
          icon: '✨',
          isSelected: _selectedGoal == FitnessGoal.bodyRecomposition,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.bodyRecomposition),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'افزایش قدرت و سلامت عمومی 🏃‍♂️',
          icon: '❤️',
          isSelected: _selectedGoal == FitnessGoal.strength,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.strength),
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 3: Experience ---
  Widget _buildStep4Experience() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سطح تجربه ورزشی شما چقدره؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'برای جلوگیری از آسیب‌دیدگی و پیشرفت مناسب.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'مبتدی (کمتر از ۶ ماه ورزش)',
          icon: '🌱',
          isSelected: _selectedLevel == ExperienceLevel.beginner,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.beginner),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'متوسط (۶ ماه تا ۲ سال)',
          icon: '⚡',
          isSelected: _selectedLevel == ExperienceLevel.intermediate,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.intermediate),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'پیشرفته (بیش از ۲ سال)',
          icon: '🏆',
          isSelected: _selectedLevel == ExperienceLevel.advanced,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.advanced),
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 4: Location ---
  Widget _buildStep5Location() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'کجا تمرین می‌کنی؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'در حال حاضر تمرینات تخصصی ویژه محیط خانه فعال می‌باشند.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'خانه 🏠',
          icon: '🏡',
          isSelected: _selectedLocation == TrainingLocation.home,
          onTap: () => setState(() => _selectedLocation = TrainingLocation.home),
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'باشگاه (به‌زودی 🔒)',
          icon: '🏋️‍♂️',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
          colors: colors,
        ),
        _buildChoiceItem(
          label: 'فضای باز / پارک (به‌زودی 🔒)',
          icon: '🏞️',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 5: Focus Areas ---
  Widget _buildStep6FocusAreas() {
    final colors = context.colors;
    void toggleArea(BodyArea area) {
      RitmoHaptics.selection();
      setState(() {
        if (_selectedFocusAreas.contains(area)) {
          if (_selectedFocusAreas.length > 1) {
            _selectedFocusAreas.remove(area);
          }
        } else {
          _selectedFocusAreas.add(area);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'کدام بخش‌های بدن برات مهم‌تره؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'می‌تونی چند گزینه رو انتخاب کنی.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'تمام بدن (Full Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.fullBody),
          onTap: () => toggleArea(BodyArea.fullBody),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'شکم و پهلو (Core)',
          isSelected: _selectedFocusAreas.contains(BodyArea.core),
          onTap: () => toggleArea(BodyArea.core),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'پاها و باسن (Lower Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.legs),
          onTap: () => toggleArea(BodyArea.legs),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'سینه و بازوها (Upper Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.chest),
          onTap: () => toggleArea(BodyArea.chest),
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 6: Equipment ---
  Widget _buildStep7Equipment() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'چه تجهیزاتی در دسترس داری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'در حال حاضر تمرینات بدون وسیله (وزن بدن) فعال می‌باشند.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'بدون وسیله (وزن بدن) 🧘‍♂️',
          isSelected: _selectedEquipment.contains(Equipment.bodyweightOnly),
          onTap: () {
            RitmoHaptics.selection();
            setState(() {
              _selectedEquipment.clear();
              _selectedEquipment.add(Equipment.bodyweightOnly);
            });
          },
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'دمبل (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'کش ورزشی (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'مت ورزشی (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 7: Limitations ---
  Widget _buildStep8Limitations() {
    final colors = context.colors;
    void toggleLimitation(Limitation lim) {
      RitmoHaptics.selection();
      setState(() {
        if (lim == Limitation.none) {
          _selectedLimitations.clear();
          _selectedLimitations.add(Limitation.none);
        } else {
          _selectedLimitations.remove(Limitation.none);
          if (_selectedLimitations.contains(lim)) {
            _selectedLimitations.remove(lim);
            if (_selectedLimitations.isEmpty) {
              _selectedLimitations.add(Limitation.none);
            }
          } else {
            _selectedLimitations.add(lim);
          }
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'آسیب‌دیدگی یا محدودیت جسمی داری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'حرکاتی که به این بخش‌ها فشار می‌ارن از برنامه‌ات حذف می‌شن.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'هیچ محدودیتی ندارم ✅',
          isSelected: _selectedLimitations.contains(Limitation.none),
          onTap: () => toggleLimitation(Limitation.none),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'درد زانو 🦵',
          isSelected: _selectedLimitations.contains(Limitation.kneeProblems),
          onTap: () => toggleLimitation(Limitation.kneeProblems),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'کمردرد 🦴',
          isSelected: _selectedLimitations.contains(Limitation.backProblems),
          onTap: () => toggleLimitation(Limitation.backProblems),
          colors: colors,
        ),
        _buildMultiChoiceItem(
          label: 'درد مچ دست / مچ پا 🦴',
          isSelected: _selectedLimitations.contains(Limitation.wristProblems),
          onTap: () => toggleLimitation(Limitation.wristProblems),
          colors: colors,
        ),
      ],
    );
  }

  // --- Step 8: Days, Duration & Persona Blueprint ---
  Widget _buildStep9DurationAndDays() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'زمان‌بندی هفتگی شما',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'چند روز در هفته و چقدر زمان می‌تونی وقت بگذاری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text('تعداد روزهای تمرین در هفته: ${toPersianDigits(_selectedDays.toString())} روز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [2, 3, 4, 5, 6].map((days) {
            final isSelected = _selectedDays == days;
            return ChoiceChip(
              label: Text(toPersianDigits('$days روز'), style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.textPrimary)),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.card,
              onSelected: (val) {
                if (val) {
                  RitmoHaptics.selection();
                  setState(() => _selectedDays = days);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('مدت هر جلسه تمرین: ${toPersianDigits(_selectedMinutes.toString())} دقیقه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [30, 45, 60].map((mins) {
            final isSelected = _selectedMinutes == mins;
            return ChoiceChip(
              label: Text(toPersianDigits('$mins دقیقه'), style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.textPrimary)),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.card,
              onSelected: (val) {
                if (val) {
                  RitmoHaptics.selection();
                  setState(() => _selectedMinutes = mins);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Live Workout Persona Blueprint Card
        _WorkoutPersonaCard(
          gender: _selectedGender,
          goal: _selectedGoal,
          experience: _selectedLevel,
          days: _selectedDays,
          durationMins: _selectedMinutes,
          limitationsCount: _selectedLimitations.contains(Limitation.none) ? 0 : _selectedLimitations.length,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildChoiceItem({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
    required RitmoColors colors,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              RitmoHaptics.selection();
              onTap();
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? colors.card.withValues(alpha: 0.4)
              : isSelected ? colors.primary.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? colors.border.withValues(alpha: 0.3)
                : isSelected ? colors.primary : colors.border,
            width: isSelected && !isDisabled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: isSelected && !isDisabled ? FontWeight.bold : FontWeight.normal,
                color: isDisabled
                    ? colors.textSecondary.withValues(alpha: 0.5)
                    : isSelected ? colors.primary : colors.textPrimary,
              ),
            ),
            Text(icon, style: TextStyle(fontSize: 20, color: isDisabled ? colors.textSecondary.withValues(alpha: 0.4) : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiChoiceItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required RitmoColors colors,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? colors.card.withValues(alpha: 0.4)
              : isSelected ? colors.primary.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? colors.border.withValues(alpha: 0.3)
                : isSelected ? colors.primary : colors.border,
            width: isSelected && !isDisabled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: isSelected && !isDisabled ? FontWeight.bold : FontWeight.normal,
                color: isDisabled
                    ? colors.textSecondary.withValues(alpha: 0.5)
                    : isSelected ? colors.primary : colors.textPrimary,
              ),
            ),
            Icon(
              isSelected && !isDisabled ? Icons.check_box : Icons.check_box_outline_blank,
              color: isDisabled
                  ? colors.textSecondary.withValues(alpha: 0.3)
                  : isSelected ? colors.primary : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Interactive BMI Spectrum Gauge ---
class _BmiSpectrumGauge extends StatelessWidget {
  const _BmiSpectrumGauge({required this.bmi, required this.colors});
  final double bmi;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    // Clamp BMI between 15 and 35 for gauge positioning (0.0 to 1.0)
    final clampedBmi = bmi.clamp(15.0, 35.0);
    final percent = (clampedBmi - 15.0) / (35.0 - 15.0);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Gauge Bar Gradient
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6), // Underweight Blue
                    Color(0xFF10B981), // Normal Green
                    Color(0xFFF59E0B), // Overweight Amber
                    Color(0xFFEF4444), // Obese Red
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            // Pin Indicator
            Positioned(
              right: null,
              left: (MediaQuery.of(context).size.width - 92) * percent.clamp(0.02, 0.95),
              top: -6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('کمبود', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
            Text('نرمال', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
            Text('اضافه وزن', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
            Text('چاقی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// --- Live Workout Persona Blueprint Card ---
class _WorkoutPersonaCard extends StatelessWidget {
  const _WorkoutPersonaCard({
    required this.gender,
    required this.goal,
    required this.experience,
    required this.days,
    required this.durationMins,
    required this.limitationsCount,
    required this.colors,
  });

  final String gender;
  final FitnessGoal? goal;
  final ExperienceLevel? experience;
  final int days;
  final int durationMins;
  final int limitationsCount;
  final RitmoColors colors;

  String _getGoalTitle() {
    switch (goal) {
      case FitnessGoal.fatLoss:
        return 'چربی‌سوزی';
      case FitnessGoal.muscleGain:
        return 'عضله‌سازی';
      case FitnessGoal.bodyRecomposition:
        return 'تناسب اندام';
      case FitnessGoal.strength:
        return 'افزایش قدرت';
      default:
        return 'عمومی';
    }
  }

  String _getExpTitle() {
    switch (experience) {
      case ExperienceLevel.beginner:
        return 'مبتدی';
      case ExperienceLevel.intermediate:
        return 'متوسط';
      case ExperienceLevel.advanced:
        return 'پیشرفته';
      default:
        return 'مبتدی';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'شناسنامه ورزشی اختصاصی شما',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPersonaChip('هدف', _getGoalTitle(), colors),
              _buildPersonaChip('سطح', _getExpTitle(), colors),
              _buildPersonaChip('زمان', toPersianDigits('$days روز × $durationMins دقیقه'), colors),
            ],
          ),
          if (limitationsCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: colors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    toPersianDigits('محافظت از $limitationsCount ناحیه حساس بدن فعال شد'),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaChip(String label, String value, RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// --- Interactive 4-Stage AI Construction Screen ---
class _AiPlanBuildingProgressView extends StatelessWidget {
  const _AiPlanBuildingProgressView({
    required this.currentStage,
    required this.colors,
  });

  final int currentStage;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    final stages = [
      'تحلیل شاخص توده بدنی (BMI) و آناتومی...',
      'اعمال محدودیت‌ها و محافظت از مفاصل...',
      'تنظیم سیستم باردهی و الگوی روزها...',
      'تولید ۴ هفته برنامه اختصاصی تمرین...',
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SSLottiePlayer.start(size: 180),
          const SizedBox(height: 12),
          SSLottiePlayer.loading(size: 48),
          const SizedBox(height: 24),
          Text(
            'در حال طراحی هوشمند برنامه تمرینی...',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 28),

          // Stage Checklist
          Column(
            children: List.generate(4, (index) {
              final stageNum = index + 1;
              final isDone = currentStage > stageNum;
              final isCurrent = currentStage == stageNum;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? colors.success
                            : isCurrent ? colors.primary : colors.card,
                        border: Border.all(
                          color: isDone
                              ? colors.success
                              : isCurrent ? colors.primary : colors.border,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : isCurrent
                              ? Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        stages[index],
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                          color: isDone
                              ? colors.success
                              : isCurrent ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
