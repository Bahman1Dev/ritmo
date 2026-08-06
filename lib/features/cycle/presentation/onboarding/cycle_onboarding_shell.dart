import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/steps/step_1_privacy_lock.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/steps/step_2_cycle_status.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/steps/step_3_rhythm_params.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/steps/step_4_consents.dart';
import 'package:ritmo/features/cycle/presentation/onboarding/steps/step_5_confirmation.dart';

class CycleOnboardingShell extends StatefulWidget {
  const CycleOnboardingShell({
    super.key,
    required this.onCompleted,
    required this.onNavigateToPregnancy,
    this.isEditMode = false,
  });

  final VoidCallback onCompleted;
  final VoidCallback onNavigateToPregnancy;
  final bool isEditMode;

  @override
  State<CycleOnboardingShell> createState() => _CycleOnboardingShellState();
}

class _CycleOnboardingShellState extends State<CycleOnboardingShell> {
  int _currentStep = 1;
  bool _isLoadingInitial = true;
  bool _isSaving = false;
  String? _errorMessage;

  late CycleOnboardingData _data;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      _data = await CycleOnboardingController.instance.loadInitialData();
    } catch (e) {
      _errorMessage = 'خطا در بارگذاری اولیه: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await CycleOnboardingController.instance.saveOnboarding(_data, isEditMode: widget.isEditMode);
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      // Dedicated Error State (Bug چ-۲ resolution)
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'خطا در ذخیره‌سازی راه‌اندازی: $e';
        });
      }
    }
  }

  Future<bool> _confirmExit() async {
    if (_currentStep == 1 && !widget.isEditMode) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xff1A1D29)
              : Colors.white,
          title: const Text(
            'خروج از راه‌اندازی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
          ),
          content: const Text(
            'آیا از خروج از راه‌اندازی اطمینان دارید؟ اطلاعات واردشده تا قبل از ثبت نهایی ذخیره نخواهند شد.',
            style: TextStyle(fontSize: 13, height: 1.5, fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ادامه راه‌اندازی', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );

    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    // Dedicated Error State Screen (Bug چ-۲ resolution)
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RitmoTheme.glassCardLight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orange, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'خطا در ذخیره‌سازی داده‌ها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _handleSave,
                      icon: const Icon(CupertinoIcons.refresh, size: 18),
                      label: const Text('تلاش مجدد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentStep > 1) {
          setState(() {
            _currentStep--;
          });
        } else {
          final exitConfirmed = await _confirmExit();
          if (exitConfirmed && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Wizard Progress Header (§۵ & Bug چ-۱۲)
              _buildProgressHeader(colors, isDark),
              const SizedBox(height: 16),
              // Step Card Body
              RitmoTheme.glassCardLight(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.2, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _buildCurrentStepWidget(colors, isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(RitmoColors colors, bool isDark) {
    final primaryColor = colors.primary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(CupertinoIcons.xmark_circle_fill, color: colors.textSecondary.withValues(alpha: 0.7)),
              onPressed: () async {
                final confirm = await _confirmExit();
                if (confirm && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            Text(
              widget.isEditMode
                  ? 'بازبینی راه‌اندازی چرخه بدن'
                  : 'راه‌اندازی چرخه بدن',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'گام ${_toPersianDigits(_currentStep.toString())} از ۵',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Segmented Progress Bar
        Row(
          children: List.generate(5, (index) {
            final stepNum = index + 1;
            final isCompleted = stepNum < _currentStep;
            final isCurrent = stepNum == _currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isCurrent || isCompleted
                      ? primaryColor
                      : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStepWidget(RitmoColors colors, bool isDark) {
    switch (_currentStep) {
      case 1:
        return Step1PrivacyLock(
          data: _data,
          onDataChanged: (d) => setState(() => _data = d),
          onNext: () => setState(() => _currentStep = 2),
          colors: colors,
          isDark: isDark,
        );
      case 2:
        return Step2CycleStatus(
          data: _data,
          onDataChanged: (d) => setState(() => _data = d),
          onNext: () {
            if (_data.periodStatus == CyclePeriodStatusChoice.currentlyPregnant) {
              widget.onNavigateToPregnancy();
            } else {
              setState(() => _currentStep = 3);
            }
          },
          onBack: () => setState(() => _currentStep = 1),
          onNavigateToPregnancy: widget.onNavigateToPregnancy,
          colors: colors,
          isDark: isDark,
        );
      case 3:
        return Step3RhythmParams(
          data: _data,
          onDataChanged: (d) => setState(() => _data = d),
          onNext: () => setState(() => _currentStep = 4),
          onBack: () => setState(() => _currentStep = 2),
          colors: colors,
          isDark: isDark,
        );
      case 4:
        return Step4Consents(
          data: _data,
          onDataChanged: (d) => setState(() => _data = d),
          onNext: () => setState(() => _currentStep = 5),
          onBack: () => setState(() => _currentStep = 3),
          colors: colors,
          isDark: isDark,
        );
      case 5:
        return Step5Confirmation(
          data: _data,
          onSave: _handleSave,
          onBack: () => setState(() => _currentStep = 4),
          isSaving: _isSaving,
          colors: colors,
          isDark: isDark,
        );
      default:
        return Container();
    }
  }

  String _toPersianDigits(String input) {
    return RitmoNumber.fa(input);
  }
}
