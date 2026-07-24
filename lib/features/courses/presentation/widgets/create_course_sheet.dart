import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/courses/logic/course_validation.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class CreateCourseSheet extends StatefulWidget {
  const CreateCourseSheet({
    super.key,
    this.editingCourse,
    this.initialValues,
    required this.onCourseCreated,
  });

  final Course? editingCourse;
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
  bool _isSaving = false;

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

    final c = widget.editingCourse;
    final iv = widget.initialValues;

    _titleController = TextEditingController(text: c?.title ?? (iv?['title'] as String?) ?? '');
    _totalSessionsController = TextEditingController(text: c?.totalSessions.toString() ?? iv?['totalSessions']?.toString() ?? '10');
    _durationController = TextEditingController(text: c?.sessionDurationMinutes.toString() ?? iv?['sessionDurationMinutes']?.toString() ?? '45');
    _unitLabelController = TextEditingController(text: c?.unitLabel ?? (iv?['unitLabel'] as String?) ?? '');
    _providerController = TextEditingController(text: c?.provider ?? (iv?['provider'] as String?) ?? '');

    if (c != null) {
      _selectedType = c.courseType;
      _weeklyTarget = c.weeklyTargetSessions;
      _energyRule = c.energyRule;
      _preferredDays.addAll(c.preferredDays);
      _reminderEnabled = c.reminderEnabled;
      if (c.preferredTime != null && c.preferredTime!.contains(':')) {
        final parts = c.preferredTime!.split(':');
        final h = int.tryParse(parts[0]) ?? 16;
        final m = int.tryParse(parts[1]) ?? 30;
        _preferredTime = TimeOfDay(hour: h, minute: m);
      }
      _linkedGoalId = c.linkedGoalId;
    } else {
      if (iv?['courseType'] != null) {
        _selectedType = CourseTypeExtension.fromString(iv?['courseType'] as String);
      }
      if (iv?['weeklyTargetSessions'] != null) {
        _weeklyTarget = iv?['weeklyTargetSessions'] as int;
      }
      if (iv?['energyRule'] != null) {
        _energyRule = iv?['energyRule'] as String;
      }
      if (iv?['preferredDays'] != null) {
        final days = iv?['preferredDays'] as List<dynamic>;
        _preferredDays.addAll(days.cast<int>());
      } else {
        _preferredDays.addAll([6, 1, 3]); // Saturday, Monday, Wednesday default
      }
      if (iv?['reminderEnabled'] != null) {
        _reminderEnabled = iv?['reminderEnabled'] as bool;
      }
      if (iv?['linkedGoalId'] != null) {
        _linkedGoalId = iv?['linkedGoalId'] as String;
      }
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
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final totalSessions = int.tryParse(_totalSessionsController.text) ?? 10;
    final duration = int.tryParse(_durationController.text) ?? 45;
    final unitLabel = _unitLabelController.text.trim().isEmpty ? null : _unitLabelController.text.trim();
    final provider = _providerController.text.trim().isEmpty ? null : _providerController.text.trim();

    final isEditing = widget.editingCourse != null;
    final now = DateTime.now();

    final timeStr = _reminderEnabled
        ? '${_preferredTime.hour.toString().padLeft(2, '0')}:${_preferredTime.minute.toString().padLeft(2, '0')}'
        : null;

    final Course courseToSave;
    if (isEditing) {
      final old = widget.editingCourse!;
      final needsReschedule = old.weeklyTargetSessions != _weeklyTarget ||
          !listEquals(old.preferredDays, _preferredDays) ||
          old.totalSessions != totalSessions ||
          old.preferredTime != timeStr ||
          old.reminderEnabled != _reminderEnabled;

      if (needsReschedule) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xff1C1F2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'تغییر ریتم برنامه‌ریزی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            content: const Text(
              'تغییر هدف هفتگی، روزها یا تعداد جلسات باعث زمان‌بندی مجدد جلسات آینده می‌شود. آیا ادامه می‌دهید؟',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B8AF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأیید و ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }

      courseToSave = old.copyWith(
        title: title,
        totalSessions: totalSessions,
        sessionDurationMinutes: duration,
        courseType: _selectedType,
        unitLabel: unitLabel,
        provider: provider,
        weeklyTargetSessions: _weeklyTarget,
        energyRule: _energyRule,
        preferredDays: _preferredDays.isEmpty ? [6, 1, 3] : _preferredDays,
        reminderEnabled: _reminderEnabled,
        preferredTime: timeStr,
        linkedGoalId: _linkedGoalId,
        updatedAt: now.millisecondsSinceEpoch,
      );
    } else {
      courseToSave = Course(
        id: 'course_${now.millisecondsSinceEpoch}_${title.hashCode}',
        title: title,
        totalSessions: totalSessions,
        sessionDurationMinutes: duration,
        courseType: _selectedType,
        unitLabel: unitLabel,
        provider: provider,
        weeklyTargetSessions: _weeklyTarget,
        energyRule: _energyRule,
        preferredDays: _preferredDays.isEmpty ? [6, 1, 3] : _preferredDays,
        reminderEnabled: _reminderEnabled,
        preferredTime: timeStr,
        linkedGoalId: _linkedGoalId,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await CoursesRepository.instance.saveCourse(courseToSave, isNew: !isEditing);
      widget.onCourseCreated();
      if (mounted) {
        RitmoToast.show(
          context,
          isEditing ? 'تغییرات دوره "$title" ذخیره شد.' : 'دوره "$title" با موفقیت ثبت شد.',
          iconColor: const Color(0xff10B981),
        );
        Navigator.pop(context);
      }
    } on CourseValidationException catch (e) {
      if (mounted) {
        RitmoToast.show(
          context,
          e.messageFa,
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber,
        );
      }
    } catch (e) {
      debugPrint('Error saving course: $e');
      if (mounted) {
        RitmoToast.show(
          context,
          'خطایی در ذخیره دوره رخ داد. لطفاً مجدداً تلاش کنید.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
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
    final isEditing = widget.editingCourse != null;

    return RitmoTheme.glassCardLight(
      borderRadius: 30,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'ویرایش دوره آموزشی' : 'ایجاد دوره آموزشی جدید',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.xmark_circle_fill, color: colors.textSecondary.withValues(alpha: 0.5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Course Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                      decoration: RitmoTheme.inputDecoration(
                        context,
                        label: 'عنوان دوره آموزشی *',
                        icon: CupertinoIcons.book,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'لطفاً عنوان دوره را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Course Type Selector
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.minus_circle, size: 20),
                              onPressed: _weeklyTarget > 1
                                  ? () => setState(() => _weeklyTarget--)
                                  : null,
                            ),
                            Text(
                              toPersianDigits('$_weeklyTarget جلسه'),
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.plus_circle, size: 20),
                              onPressed: _weeklyTarget < 14
                                  ? () => setState(() => _weeklyTarget++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preferred Days Selector
                    Text(
                      'روزهای ترجیحی مطالعه:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _dayOptions.map((opt) {
                        final val = opt['value'] as int;
                        final name = opt['name'] as String;
                        final isSelected = _preferredDays.contains(val);
                        return _WeekdayChip(
                          label: name,
                          isSelected: isSelected,
                          onTap: () => _toggleDay(val),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Advanced Settings Expansion
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'تنظیمات پیشرفته (اختیاری)',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        leading: Icon(CupertinoIcons.gear_alt, color: colors.primary, size: 20),
                        initiallyExpanded: _isAdvancedExpanded,
                        onExpansionChanged: (exp) => setState(() => _isAdvancedExpanded = exp),
                        children: [
                          if (_selectedType == CourseType.custom) ...[
                            TextFormField(
                              controller: _unitLabelController,
                              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                              decoration: RitmoTheme.inputDecoration(
                                context,
                                label: 'نام واحد سفارشی (مثلاً: پودمان، مبحث)',
                                icon: CupertinoIcons.tag,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Provider
                          TextFormField(
                            controller: _providerController,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'پلتفرم / استاد (مثلاً: یوتیوب، استاد رضایی)',
                              icon: CupertinoIcons.person_2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Energy Match Rule
                          Text(
                            'قانون تطابق انرژی با مود:',
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
                                  if (val != null) setState(() => _energyRule = val);
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
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'ذخیره تغییرات' : 'ذخیره و ایجاد دوره',
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
