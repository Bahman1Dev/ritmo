import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
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

  // Selected Values (Gender is automatically read from main app settings)
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

  @override
  void initState() {
    super.initState();
    _loadStateFromPreferences();
  }

  // --- State Persistence ---
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
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _saveStateToPreferences();
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _saveStateToPreferences();
    } else {
      Navigator.pop(context);
    }
  }

  // --- Plan & Profile Generation ---
  Future<void> _finishOnboarding() async {
    setState(() {
      _isGeneratingPlan = true;
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

      // Generate plans for all 4 weeks
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 1);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 2);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 3);
      await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: 4);

      await _clearOnboardingPreferences();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SSHomeDashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error finishing onboarding flow: $e');
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
    if (_isGeneratingPlan) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SSLottiePlayer.start(size: 220),
                const SizedBox(height: 8),
                SSLottiePlayer.loading(size: 56),
                const SizedBox(height: 20),
                const Text(
                  'در حال ساخت برنامه تمرینی اختصاصی شما...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF133B26),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'این فرآیند چند ثانیه طول می‌کشد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: Colors.grey[600],
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
          tooltip: 'بازگشت',
        ),
        title: Text(
          toPersianDigits('مرحله $_currentStep از $_totalSteps'),
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            color: Colors.black,
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
                    backgroundColor: const Color(0xFFE8F5E9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _buildStepContent(_currentStep),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  label: _currentStep == _totalSteps ? 'شروع برنامه' : 'ادامه',
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
      case 2:
        return _selectedGoal != null;
      case 3:
        return _selectedLevel != null;
      case 5:
        return _selectedFocusAreas.isNotEmpty;
      case 6:
        return _selectedEquipment.isNotEmpty;
      case 7:
        return _selectedLimitations.isNotEmpty;
      default:
        return true;
    }
  }

  // --- Step 1: BMI Calculator ---
  Widget _buildStep2Bmi() {
    final bmi = _weightKg / ((_heightCm / 100) * (_heightCm / 100));
    var category = 'وزن نرمال';
    var categoryColor = const Color(0xFF2D6A4F);
    if (bmi < 18.5) {
      category = 'کمبود وزن';
      categoryColor = Colors.blue;
    } else if (bmi >= 25 && bmi < 30) {
      category = 'اضافه وزن';
      categoryColor = Colors.orange;
    } else if (bmi >= 30) {
      category = 'چاقی';
      categoryColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مشخصات فیزیکی',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'قد و وزن به ما کمک می‌کنه شاخص توده بدنی (BMI) و کالری مصرفی رو دقیق‌تر حساب کنیم.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F9F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  const Text('شاخص توده بدنی (BMI)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    toPersianDigits(bmi.toStringAsFixed(1)),
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 24, fontWeight: FontWeight.bold, color: categoryColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: categoryColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('قد: ${toPersianDigits(_heightCm.toInt().toString())} سانتی‌متر', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
        Slider(
          value: _heightCm,
          min: 130,
          max: 220,
          divisions: 90,
          activeColor: const Color(0xFF2D6A4F),
          onChanged: (val) => setState(() => _heightCm = val),
        ),
        const SizedBox(height: 16),
        Text('وزن: ${toPersianDigits(_weightKg.toInt().toString())} کیلوگرم', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
        Slider(
          value: _weightKg,
          min: 40,
          max: 160,
          divisions: 120,
          activeColor: const Color(0xFF2D6A4F),
          onChanged: (val) => setState(() => _weightKg = val),
        ),
        const SizedBox(height: 16),
        const Text('جنسیت:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'FEMALE'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'FEMALE' ? const Color(0xFF2D6A4F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedGender == 'FEMALE' ? const Color(0xFF2D6A4F) : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      '👩‍🦰 خانم',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'FEMALE' ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'MALE'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'MALE' ? const Color(0xFF2D6A4F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedGender == 'MALE' ? const Color(0xFF2D6A4F) : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      '👨 آقا',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'MALE' ? Colors.white : Colors.black87,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'هدف اصلی ورزشی شما چیه؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'برنامه بر اساس هدف شما تنظیم می‌شه.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'کاهش وزن و چربی‌سوزی 🎯',
          icon: '🔥',
          isSelected: _selectedGoal == FitnessGoal.fatLoss,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.fatLoss),
        ),
        _buildChoiceItem(
          label: 'عضله‌سازی و افزایش حجم 💪',
          icon: '🏋️‍♂️',
          isSelected: _selectedGoal == FitnessGoal.muscleGain,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.muscleGain),
        ),
        _buildChoiceItem(
          label: 'بازسازی بدنی و تناسب اندام ⚖️',
          icon: '✨',
          isSelected: _selectedGoal == FitnessGoal.bodyRecomposition,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.bodyRecomposition),
        ),
        _buildChoiceItem(
          label: 'افزایش قدرت و سلامت عمومی 🏃‍♂️',
          icon: '❤️',
          isSelected: _selectedGoal == FitnessGoal.strength,
          onTap: () => setState(() => _selectedGoal = FitnessGoal.strength),
        ),
      ],
    );
  }

  // --- Step 3: Experience ---
  Widget _buildStep4Experience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سطح تجربه ورزشی شما چقدره؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'برای جلوگیری از آسیب‌دیدگی و پیشرفت مناسب.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'مبتدی (کمتر از ۶ ماه ورزش)',
          icon: '🌱',
          isSelected: _selectedLevel == ExperienceLevel.beginner,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.beginner),
        ),
        _buildChoiceItem(
          label: 'متوسط (۶ ماه تا ۲ سال)',
          icon: '⚡',
          isSelected: _selectedLevel == ExperienceLevel.intermediate,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.intermediate),
        ),
        _buildChoiceItem(
          label: 'پیشرفته (بیش از ۲ سال)',
          icon: '🏆',
          isSelected: _selectedLevel == ExperienceLevel.advanced,
          onTap: () => setState(() => _selectedLevel = ExperienceLevel.advanced),
        ),
      ],
    );
  }

  // --- Step 4: Location ---
  Widget _buildStep5Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'کجا تمرین می‌کنی؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'در حال حاضر تمرینات تخصصی ویژه محیط خانه فعال می‌باشند.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildChoiceItem(
          label: 'خانه 🏠',
          icon: '🏡',
          isSelected: _selectedLocation == TrainingLocation.home,
          onTap: () => setState(() => _selectedLocation = TrainingLocation.home),
        ),
        _buildChoiceItem(
          label: 'باشگاه (به‌زودی 🔒)',
          icon: '🏋️‍♂️',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
        ),
        _buildChoiceItem(
          label: 'فضای باز / پارک (به‌زودی 🔒)',
          icon: '🏞️',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
        ),
      ],
    );
  }

  // --- Step 5: Focus Areas ---
  Widget _buildStep6FocusAreas() {
    void toggleArea(BodyArea area) {
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
        const Text(
          'کدام بخش‌های بدن برات مهم‌تره؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'می‌تونی چند گزینه رو انتخاب کنی.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'تمام بدن (Full Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.fullBody),
          onTap: () => toggleArea(BodyArea.fullBody),
        ),
        _buildMultiChoiceItem(
          label: 'شکم و پهلو (Core)',
          isSelected: _selectedFocusAreas.contains(BodyArea.core),
          onTap: () => toggleArea(BodyArea.core),
        ),
        _buildMultiChoiceItem(
          label: 'پاها و باسن (Lower Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.legs),
          onTap: () => toggleArea(BodyArea.legs),
        ),
        _buildMultiChoiceItem(
          label: 'سینه و بازوها (Upper Body)',
          isSelected: _selectedFocusAreas.contains(BodyArea.chest),
          onTap: () => toggleArea(BodyArea.chest),
        ),
      ],
    );
  }

  // --- Step 6: Equipment ---
  Widget _buildStep7Equipment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'چه تجهیزاتی در دسترس داری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'در حال حاضر تمرینات بدون وسیله (وزن بدن) فعال می‌باشند.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'بدون وسیله (وزن بدن) 🧘‍♂️',
          isSelected: _selectedEquipment.contains(Equipment.bodyweightOnly),
          onTap: () {
            setState(() {
              _selectedEquipment.clear();
              _selectedEquipment.add(Equipment.bodyweightOnly);
            });
          },
        ),
        _buildMultiChoiceItem(
          label: 'دمبل (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
        ),
        _buildMultiChoiceItem(
          label: 'کش ورزشی (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
        ),
        _buildMultiChoiceItem(
          label: 'مت ورزشی (به‌زودی 🔒)',
          isSelected: false,
          isDisabled: true,
          onTap: () {},
        ),
      ],
    );
  }

  // --- Step 7: Limitations ---
  Widget _buildStep8Limitations() {
    void toggleLimitation(Limitation lim) {
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
        const Text(
          'آسیب‌دیدگی یا محدودیت جسمی داری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'حرکاتی که به این بخش‌ها فشار می‌ارن از برنامه‌ات حذف می‌شن.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildMultiChoiceItem(
          label: 'هیچ محدودیتی ندارم ✅',
          isSelected: _selectedLimitations.contains(Limitation.none),
          onTap: () => toggleLimitation(Limitation.none),
        ),
        _buildMultiChoiceItem(
          label: 'درد زانو 🦵',
          isSelected: _selectedLimitations.contains(Limitation.kneeProblems),
          onTap: () => toggleLimitation(Limitation.kneeProblems),
        ),
        _buildMultiChoiceItem(
          label: 'کمردرد 🦴',
          isSelected: _selectedLimitations.contains(Limitation.backProblems),
          onTap: () => toggleLimitation(Limitation.backProblems),
        ),
        _buildMultiChoiceItem(
          label: 'درد مچ دست / مچ پا 🦴',
          isSelected: _selectedLimitations.contains(Limitation.wristProblems),
          onTap: () => toggleLimitation(Limitation.wristProblems),
        ),
      ],
    );
  }

  // --- Step 8: Days & Duration ---
  Widget _buildStep9DurationAndDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'زمان‌بندی هفته‌گی شما',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133B26)),
        ),
        const SizedBox(height: 8),
        const Text(
          'چند روز در هفته و چقدر زمان می‌تونی وقت بگذاری؟',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Text('تعداد روزهای تمرین در هفته: ${toPersianDigits(_selectedDays.toString())} روز', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [2, 3, 4, 5, 6].map((days) {
            final isSelected = _selectedDays == days;
            return ChoiceChip(
              label: Text(toPersianDigits('$days روز'), style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : Colors.black)),
              selected: isSelected,
              selectedColor: const Color(0xFF2D6A4F),
              onSelected: (val) {
                if (val) setState(() => _selectedDays = days);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text('مدت هر جلسه تمرین: ${toPersianDigits(_selectedMinutes.toString())} دقیقه', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [30, 45, 60].map((mins) {
            final isSelected = _selectedMinutes == mins;
            return ChoiceChip(
              label: Text(toPersianDigits('$mins دقیقه'), style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : Colors.black)),
              selected: isSelected,
              selectedColor: const Color(0xFF2D6A4F),
              onSelected: (val) {
                if (val) setState(() => _selectedMinutes = mins);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceItem({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey[100] 
              : isSelected ? const Color(0xFFE8F5E9) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : isSelected ? const Color(0xFF2D6A4F) : Colors.grey[300]!,
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
                    ? Colors.grey[400]
                    : isSelected ? const Color(0xFF133B26) : Colors.black,
              ),
            ),
            Text(icon, style: TextStyle(fontSize: 20, color: isDisabled ? Colors.grey[400] : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiChoiceItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey[100] 
              : isSelected ? const Color(0xFFE8F5E9) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : isSelected ? const Color(0xFF2D6A4F) : Colors.grey[300]!,
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
                    ? Colors.grey[400]
                    : isSelected ? const Color(0xFF133B26) : Colors.black,
              ),
            ),
            Icon(
              isSelected && !isDisabled ? Icons.check_box : Icons.check_box_outline_blank,
              color: isDisabled
                  ? Colors.grey[300]
                  : isSelected ? const Color(0xFF2D6A4F) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
