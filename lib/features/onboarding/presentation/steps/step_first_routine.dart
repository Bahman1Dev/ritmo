import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class StepFirstRoutine extends StatefulWidget {

  const StepFirstRoutine({
    super.key,
    required this.wakeTime,
    required this.sleepTime,
    required this.firstRoutineTitle,
    required this.onTitleChanged,
    required this.duration,
    required this.onDurationChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.routineTime,
    required this.onTimeChanged,
  });
  final String wakeTime;
  final String sleepTime;
  final String firstRoutineTitle;
  final ValueChanged<String> onTitleChanged;
  final int duration;
  final ValueChanged<int> onDurationChanged;
  final Category category;
  final ValueChanged<Category> onCategoryChanged;
  final TimeOfDay routineTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  State<StepFirstRoutine> createState() => _StepFirstRoutineState();
}

class _StepFirstRoutineState extends State<StepFirstRoutine> {
  bool _isManual = false;
  final TextEditingController _customTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customTitleController.text = widget.firstRoutineTitle;
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  double _parseTimeToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return double.parse(parts[0]) + double.parse(parts[1]) / 60.0;
    } catch (_) {
      return 7;
    }
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  Color _getCategoryColor(Category cat) {
    switch (cat) {
      case Category.medical:
        return const Color(0xffEF4444);
      case Category.religious:
        return const Color(0xffF59E0B);
      case Category.fitness:
        return const Color(0xff10B981);
      case Category.work:
        return const Color(0xff3B82F6);
      case Category.learning:
        return const Color(0xff8B5CF6);
      default:
        return const Color(0xff9B89FF);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.routineTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff9B89FF),
              onPrimary: Colors.white,
              surface: Color(0xff1A1D26),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wakeDouble = _parseTimeToDouble(widget.wakeTime);
    var sleepDouble = _parseTimeToDouble(widget.sleepTime);
    if (sleepDouble < wakeDouble) {
      sleepDouble += 24.0;
    }
    final routineDouble = widget.routineTime.hour + widget.routineTime.minute / 60.0;
    var routineWakingOffset = routineDouble;
    if (routineDouble < wakeDouble && (routineDouble + 24.0) < sleepDouble) {
      routineWakingOffset += 24.0;
    }

    final totalWakingHours = sleepDouble - wakeDouble;
    // Calculate fraction position of routine in waking day
    var positionFraction = (routineWakingOffset - wakeDouble) / totalWakingHours;
    positionFraction = positionFraction.clamp(0.0, 1.0);

    final catColor = _getCategoryColor(widget.category);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اولین عادت ریتمیک شما',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'یک فعالیت ساده برای شروع روز ریتمیک خود انتخاب کنید.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 16),
        // Choice chip switcher (Quick pick vs Manual input)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('انتخاب سریع'),
              selected: !_isManual,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _isManual = false;
                    widget.onTitleChanged('💧 نوشیدن آب');
                    widget.onDurationChanged(2);
                    widget.onCategoryChanged(Category.fitness);
                  });
                }
              },
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('ثبت دستی'),
              selected: _isManual,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _isManual = true;
                    widget.onTitleChanged(_customTitleController.text);
                    widget.onCategoryChanged(Category.personal);
                  });
                }
              },
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_isManual)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              {'title': '💧 نوشیدن آب', 'duration': 2, 'cat': Category.fitness},
              {'title': '📚 ۲۰ دقیقه مطالعه', 'duration': 20, 'cat': Category.learning},
              {'title': '🚶 پیاده‌روی کوتاه', 'duration': 15, 'cat': Category.fitness},
              {'title': '💊 مصرف ویتامین / قرص', 'duration': 5, 'cat': Category.medical},
              {'title': '🧘 ۵ دقیقه تنفس عمیق', 'duration': 5, 'cat': Category.personal},
            ].map((routine) {
              final isSelected = widget.firstRoutineTitle == routine['title'] && !_isManual;
              return ActionChip(
                label: Text(routine['title']! as String),
                backgroundColor: isSelected ? const Color(0xff9B89FF).withValues(alpha: 0.25) : colors.textPrimary.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xff9B89FF) : colors.border.withValues(alpha: 0.15),
                  ),
                ),
                labelStyle: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onTitleChanged(routine['title']! as String);
                  widget.onDurationChanged(routine['duration']! as int);
                  widget.onCategoryChanged(routine['cat']! as Category);
                },
              );
            }).toList(),
          )
        else ...[
          TextField(
            controller: _customTitleController,
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              hintText: 'عنوان عادت (مثلاً: مدیتیشن صبحگاهی)',
              hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4), fontFamily: 'Vazirmatn'),
              filled: true,
              fillColor: colors.textPrimary.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border.withValues(alpha: 0.15)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: widget.onTitleChanged,
          ),
          const SizedBox(height: 12),
          // Category selection in manual mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategorySelectButton(Category.personal, 'فردی'),
              _buildCategorySelectButton(Category.fitness, 'سلامتی'),
              _buildCategorySelectButton(Category.work, 'کاری'),
              _buildCategorySelectButton(Category.religious, 'عبادی'),
            ],
          ),
        ],
        const SizedBox(height: 24),
        // Live Preview Title
        Text(
          'پیش‌نمایش زمان‌بندی روزانه:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        // Daily timeline slider and card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 38,
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.firstRoutineTitle.isNotEmpty ? widget.firstRoutineTitle : 'عادت جدید',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _toPersianDigits('مدت زمان: ${widget.duration} دقیقه'),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Clickable time selector
                    InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _toPersianDigits('${widget.routineTime.hour.toString().padLeft(2, '0')}:${widget.routineTime.minute.toString().padLeft(2, '0')}'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Horizontal Timeline Bar
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Positioned(
                        left: 218 * positionFraction, // Dynamic calculation estimation
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 6,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _toPersianDigits(widget.wakeTime),
                        style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.6), fontFamily: 'Vazirmatn'),
                      ),
                      Text(
                        'روز بیداری شما',
                        style: TextStyle(fontSize: 9, color: colors.textSecondary.withValues(alpha: 0.5), fontFamily: 'Vazirmatn'),
                      ),
                      Text(
                        _toPersianDigits(widget.sleepTime),
                        style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.6), fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelectButton(Category cat, String label) {
    final colors = context.colors;
    final isSelected = widget.category == cat;
    final color = _getCategoryColor(cat);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onCategoryChanged(cat);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : colors.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colors.border.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: isSelected ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
