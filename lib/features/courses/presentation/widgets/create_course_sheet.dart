import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class CreateCourseSheet extends StatefulWidget {

  const CreateCourseSheet({
    super.key,
    this.initialValues,
    required this.onCourseCreated,
  });
  final Map<String, dynamic>? initialValues;
  final VoidCallback onCourseCreated;

  @override
  State<CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<CreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _totalSessionsController;
  late TextEditingController _durationController;
  late TextEditingController _unitLabelController;
  late TextEditingController _providerController;

  CourseType _selectedType = CourseType.video;
  int _weeklyTarget = 3;
  String _energyRule = 'NONE';
  
  // Saturday=6, Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5
  final List<int> _preferredDays = [];
  
  bool _reminderEnabled = false;
  TimeOfDay _preferredTime = const TimeOfDay(hour: 16, minute: 30);
  
  String? _linkedGoalId;
  List<Map<String, dynamic>> _activeGoals = [];
  bool _isAdvancedExpanded = false;

  final List<Map<String, dynamic>> _dayOptions = [
    {'name': 'شنبه', 'value': 6},
    {'name': 'یکشنبه', 'value': 0},
    {'name': 'دوشنبه', 'value': 1},
    {'name': 'سه‌شنبه', 'value': 2},
    {'name': 'چهارشنبه', 'value': 3},
    {'name': 'پنجشنبه', 'value': 4},
    {'name': 'جمعه', 'value': 5},
  ];

  final List<Map<String, String>> _energyRules = [
    {'label': 'بدون قانون خاص', 'value': 'NONE'},
    {'label': 'رد کردن در انرژی پایین', 'value': 'skip'},
    {'label': 'پیشنهاد نسخه سبک در انرژی پایین', 'value': 'offerLight'},
    {'label': 'فقط در انرژی بالا انجام شود', 'value': 'highEnergyOnly'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: (widget.initialValues?['title'] as String?) ?? '');
    _totalSessionsController = TextEditingController(text: widget.initialValues?['totalSessions']?.toString() ?? '10');
    _durationController = TextEditingController(text: widget.initialValues?['sessionDurationMinutes']?.toString() ?? '45');
    _unitLabelController = TextEditingController(text: (widget.initialValues?['unitLabel'] as String?) ?? '');
    _providerController = TextEditingController(text: (widget.initialValues?['provider'] as String?) ?? '');

    if (widget.initialValues?['courseType'] != null) {
      _selectedType = CourseTypeExtension.fromString(widget.initialValues?['courseType'] as String);
    }
    if (widget.initialValues?['weeklyTargetSessions'] != null) {
      _weeklyTarget = widget.initialValues?['weeklyTargetSessions'] as int;
    }
    if (widget.initialValues?['energyRule'] != null) {
      _energyRule = widget.initialValues?['energyRule'] as String;
    }
    if (widget.initialValues?['preferredDays'] != null) {
      final days = widget.initialValues?['preferredDays'] as List<dynamic>;
      _preferredDays.addAll(days.cast<int>());
    } else {
      _preferredDays.addAll([6, 1, 3]); // Saturday, Monday, Wednesday default
    }

    _unitLabelController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadActiveGoals();
  }

  Future<void> _loadActiveGoals() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final goals = await db.query(
        'goals',
        where: 'status = ?',
        whereArgs: ['ACTIVE'],
      );
      setState(() {
        _activeGoals = goals;
      });
    } catch (e) {
      debugPrint('Error loading active goals: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalSessionsController.dispose();
    _durationController.dispose();
    _unitLabelController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  String get _currentUnitLabel {
    if (_selectedType == CourseType.custom) {
      final text = _unitLabelController.text.trim();
      return text.isNotEmpty ? text : 'واحد';
    }
    return _selectedType.defaultUnitLabel;
  }

  void _toggleDay(int val) {
    setState(() {
      if (_preferredDays.contains(val)) {
        _preferredDays.remove(val);
      } else {
        _preferredDays.add(val);
      }
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              helpTextStyle: TextStyle(fontFamily: 'Vazirmatn'),
              hourMinuteTextStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 24),
              dayPeriodTextStyle: TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _preferredTime = picked;
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final totalSessions = int.tryParse(_totalSessionsController.text) ?? 10;
    final duration = int.tryParse(_durationController.text) ?? 45;
    final unitLabel = _unitLabelController.text.trim().isEmpty ? null : _unitLabelController.text.trim();
    final provider = _providerController.text.trim().isEmpty ? null : _providerController.text.trim();

    final now = DateTime.now();

    final course = Course(
      id: 'course_${now.millisecondsSinceEpoch}_${title.hashCode}',
      title: title,
      totalSessions: totalSessions,
      sessionDurationMinutes: duration,
      courseType: _selectedType,
      unitLabel: unitLabel,
      provider: provider,
      weeklyTargetSessions: _weeklyTarget,
      energyRule: _energyRule,
      preferredDays: _preferredDays.isEmpty ? [6, 1, 3] : _preferredDays, // Saturday, Monday, Wednesday default
      reminderEnabled: _reminderEnabled,
      preferredTime: _reminderEnabled
          ? '${_preferredTime.hour.toString().padLeft(2, '0')}:${_preferredTime.minute.toString().padLeft(2, '0')}'
          : null,
      linkedGoalId: _linkedGoalId,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    try {
      await CoursesRepository.instance.createCourse(course);
      widget.onCourseCreated();
      if (mounted) {
        RitmoToast.show(
          context,
          'دوره "$title" با موفقیت ثبت شد.',
          iconColor: const Color(0xff10B981),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving course: $e');
      if (mounted) {
        RitmoToast.show(
          context,
          'خطایی در ثبت دوره رخ داد. لطفاً مجدداً تلاش کنید.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RitmoTheme.glassCardLight(
      borderRadius: 30,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.initialValues != null ? 'تأیید و ویرایش برنامه پیشنهادی' : 'ساخت دوره آموزشی جدید',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                      decoration: RitmoTheme.inputDecoration(
                        context,
                        label: 'نام دوره / موضوع آموزش',
                        icon: CupertinoIcons.book,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'لطفاً نام دوره را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Course Type
                    Text(
                      'نوع دوره:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CourseType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(
                            '${type.defaultEmoji} ${type.label}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : colors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: colors.primary,
                          backgroundColor: colors.card,
                          side: BorderSide(
                            color: isSelected ? colors.primary : colors.border,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedType = type;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),



                    // Total units & Duration
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalSessionsController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'تعداد کل $_currentUnitLabel‌ها',
                              icon: CupertinoIcons.number,
                            ),
                            validator: (value) {
                              if (value == null || int.tryParse(value) == null || (int.tryParse(value) ?? 0) <= 0) {
                                return 'عدد بزرگتر از ۰ وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'مدت هر $_currentUnitLabel (دقیقه)',
                              icon: CupertinoIcons.time,
                            ),
                            validator: (value) {
                              if (value == null || int.tryParse(value) == null || (int.tryParse(value) ?? 0) <= 0) {
                                  return 'عدد بزرگتر از ۰ وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weekly Target
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تعداد جلسات در هفته:',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary.withValues(alpha: 0.85),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_weeklyTarget > 1) {
                                    setState(() => _weeklyTarget--);
                                  }
                                },
                                icon: const Icon(CupertinoIcons.minus_circle),
                                color: colors.primary,
                              ),
                              Text(
                                toPersianDigits(_weeklyTarget),
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_weeklyTarget < 7) {
                                    setState(() => _weeklyTarget++);
                                  }
                                },
                                icon: const Icon(CupertinoIcons.plus_circle),
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Preferred Days
                    Text(
                      'روزهای ترجیحی برای مطالعه:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dayOptions.map((opt) {
                        final val = opt['value'] as int;
                        final isSelected = _preferredDays.contains(val);
                        return _WeekdayChip(
                          label: opt['name'] as String,
                          isSelected: isSelected,
                          onTap: () => _toggleDay(val),
                        );
                      }).toList(),
                    ),
                    
                    // Logic mismatch warning text
                    if (_preferredDays.length != _weeklyTarget) ...[
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ تعداد روزهای ترجیحی انتخاب‌شده (${toPersianDigits(_preferredDays.length)}) با تعداد جلسات در هفته (${toPersianDigits(_weeklyTarget)}) همخوانی ندارد.',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.warning,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Advanced Expandable Accordion
                    GestureDetector(
                      onTap: () => setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(CupertinoIcons.settings, size: 18, color: colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'تنظیمات پیشرفته و اختیاری',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isAdvancedExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isAdvancedExpanded) ...[
                      const SizedBox(height: 12),
                      
                      // Provider
                      TextFormField(
                        controller: _providerController,
                        style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                        decoration: RitmoTheme.inputDecoration(
                          context,
                          label: 'نام ارائه‌دهنده یا پلتفرم (اختیاری)',
                          icon: CupertinoIcons.person_2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Energy Rule
                      Text(
                        'تنظیم هوشمند سطح انرژی:',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _energyRule,
                            isExpanded: true,
                            dropdownColor: isDarkMode ? const Color(0xff1A1D29) : Colors.white,
                            items: _energyRules.map((rule) {
                              return DropdownMenuItem<String>(
                                value: rule['value'],
                                child: Text(
                                  rule['label']!,
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _energyRule = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link to Goal
                      Text(
                        'اتصال یک‌طرفه به هدف (اختیاری):',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _linkedGoalId,
                            isExpanded: true,
                            hint: Text(
                              'انتخاب هدف برای ارسال درصد پیشرفت...',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textSecondary),
                            ),
                            dropdownColor: isDarkMode ? const Color(0xff1A1D29) : Colors.white,
                            items: [
                              DropdownMenuItem<String?>(
                                child: Text(
                                  'بدون اتصال به هدف',
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textSecondary),
                                ),
                              ),
                              ..._activeGoals.map((goal) {
                                return DropdownMenuItem<String?>(
                                  value: goal['id'] as String,
                                  child: Text(
                                    goal['title'] as String,
                                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textPrimary),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _linkedGoalId = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reminders Switch
                      SwitchListTile(
                        title: Text(
                          'فعال‌سازی یادآور مطالعه',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          'ارسال نوتیفیکیشن در ساعت تعیین‌شده',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.textSecondary),
                        ),
                        value: _reminderEnabled,
                        onChanged: (val) {
                          setState(() {
                            _reminderEnabled = val;
                          });
                        },
                        activeThumbColor: colors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_reminderEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ساعت یادآوری:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: colors.textPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(CupertinoIcons.clock, size: 16),
                              label: Text(
                                toPersianDigits('${_preferredTime.hour.toString().padLeft(2, '0')}:${_preferredTime.minute.toString().padLeft(2, '0')}'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.initialValues != null ? 'تأیید و ذخیره نهایی' : 'ایجاد دوره آموزشی',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _WeekdayChip extends StatelessWidget {

  const _WeekdayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xff8B5CF6), Color(0xffEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : colors.border.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : colors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
