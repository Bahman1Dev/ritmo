import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/konkur/data/konkur_presets.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurSetupFlow extends StatefulWidget {

  const KonkurSetupFlow({
    super.key,
    required this.onSetupCompleted,
  });
  final VoidCallback onSetupCompleted;

  @override
  State<KonkurSetupFlow> createState() => _KonkurSetupFlowState();
}

class _KonkurSetupFlowState extends State<KonkurSetupFlow> {
  int _currentStep = 0;

  // Selected values
  KonkurField? _selectedField;
  bool _includeGeneral = false;
  DateTime? _selectedExamDate;
  int _dailyTargetMinutes = 180;

  bool _isSaving = false;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveSetup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedExamDate ?? now.add(const Duration(days: 300));
    final pickedDate = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(initialDate),
      firstDate: Jalali.fromDateTime(now),
      lastDate: Jalali.fromDateTime(now.add(const Duration(days: 1000))),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedExamDate = pickedDate.toDateTime();
      });
    }
  }

  Future<void> _saveSetup() async {
    if (_selectedField == null || _selectedExamDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً تمام فیلدها را پر کنید.',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      
      // 1. Seed presets
      await KonkurPresets.seedFieldIntoDb(db, _selectedField!, includeGeneral: _includeGeneral);

      // 2. Write settings to app_settings
      final repo = KonkurRepository.instance;
      final examDateStr = _selectedExamDate!.toIso8601String().substring(0, 10);
      
      await repo.updateAppSetting('konkur_field', _selectedField!.code);
      await repo.updateAppSetting('konkur_exam_date', examDateStr);
      await repo.updateAppSetting('konkur_daily_target_minutes', _dailyTargetMinutes.toString());
      await repo.updateAppSetting('konkur_setup_done', 'true');

      widget.onSetupCompleted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره‌سازی: $e',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'راه‌اندازی ماژول کنکور 📚',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قدم به قدم برای برنامه‌ریزی هوشمند کنکور شما',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Step indicator
              _buildStepIndicator(colors),
              const SizedBox(height: 32),
              // Step Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(colors, isDarkMode),
              ),
              const SizedBox(height: 40),
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSaving ? null : _prevStep,
                      child: Text(
                        'مرحله قبل',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: colors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : (_canGoToNext() ? _nextStep : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.border,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'پایان و راه‌اندازی' : 'مرحله بعد',
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canGoToNext() {
    if (_currentStep == 0) return _selectedField != null;
    if (_currentStep == 1) return _selectedExamDate != null;
    return true;
  }

  Widget _buildStepIndicator(RitmoColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF8B5CF6)
                    : isDone
                        ? const Color(0xFF10B981)
                        : colors.border,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      toPersianDigits(index + 1),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: isActive || isDone ? Colors.white : colors.textSecondary,
                      ),
                    ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 3,
                color: isDone ? const Color(0xFF10B981) : colors.border,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(RitmoColors colors, bool isDarkMode) {
    switch (_currentStep) {
      case 0:
        return _buildFieldSelectionStep(colors, isDarkMode);
      case 1:
        return _buildExamDateStep(colors);
      case 2:
        return _buildTargetStep(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFieldSelectionStep(RitmoColors colors, bool isDarkMode) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'رشته تحصیلی خود را انتخاب کنید:',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...KonkurField.values.map((field) {
          final isSelected = _selectedField == field;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8B5CF6) : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            color: isSelected
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                : colors.card,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedField = field;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFF8B5CF6))
                    else
                      const Icon(Icons.circle_outlined, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExamDateStep(RitmoColors colors) {
    var formattedDate = 'هنوز انتخاب نشده';
    if (_selectedExamDate != null) {
      final jalali = Jalali.fromDateTime(_selectedExamDate!);
      formattedDate = '${jalali.formatter.wN} ${toPersianDigits(jalali.day)} ${jalali.formatter.mN} ${toPersianDigits(jalali.year)}';
    }

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تاریخ برگزاری کنکور سراسری:',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'این تاریخ برای تنظیم روزشمار و بودجه‌بندی برنامه شما استفاده خواهد شد.',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.calendar_today, size: 48, color: Color(0xFF8B5CF6)),
                const SizedBox(height: 16),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedExamDate != null ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: const Text(
                    'انتخاب تاریخ شمسی کنکور',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Switch to toggle general subjects
        Card(
          elevation: 0,
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'افزودن دروس عمومی کنکور؟',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'در نظام جدید دروس عمومی حذف شده‌اند، اما در صورت تمایل می‌توانید آن‌ها را مطالعه کنید.',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _includeGeneral,
                  onChanged: (val) {
                    setState(() {
                      _includeGeneral = val;
                    });
                  },
                  activeThumbColor: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetStep(RitmoColors colors) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سقف مطالعه روزانه (هدف شما):',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'هدف روزانه مطالعه مباحث و تست‌زنی بر حسب دقیقه.',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Text(
                formatDuration(_dailyTargetMinutes),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: _dailyTargetMinutes.toDouble(),
                min: 60,
                max: 720,
                divisions: 22, // 30 minute steps
                activeColor: const Color(0xFF8B5CF6),
                inactiveColor: colors.border,
                onChanged: (val) {
                  setState(() {
                    _dailyTargetMinutes = val.toInt();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '۱ ساعت',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '۱۲ ساعت',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
