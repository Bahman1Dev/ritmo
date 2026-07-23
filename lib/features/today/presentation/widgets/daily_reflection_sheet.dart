import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

class DailyReflectionSheet extends StatefulWidget {

  const DailyReflectionSheet({super.key, required this.onSaved, this.date});
  final VoidCallback onSaved;
  final String? date;

  @override
  State<DailyReflectionSheet> createState() => _DailyReflectionSheetState();
}

class _DailyReflectionSheetState extends State<DailyReflectionSheet> {
  int _moodScore = 3;
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _learningsController = TextEditingController();
  final TextEditingController _winsController = TextEditingController();
  final TextEditingController _gratitudeController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();
  final TextEditingController _tomorrowFocusController = TextEditingController();
  bool _isSaving = false;
  bool _isPrivate = false;

  final List<Map<String, dynamic>> _moodOptions = [
    {
      'score': 1,
      'emoji': '😫',
      'label': 'خیلی بد',
      'color': Colors.redAccent,
    },
    {
      'score': 2,
      'emoji': '🙁',
      'label': 'بد',
      'color': Colors.orangeAccent,
    },
    {
      'score': 3,
      'emoji': '😐',
      'label': 'معمولی',
      'color': Colors.blueAccent,
    },
    {
      'score': 4,
      'emoji': '🙂',
      'label': 'خوب',
      'color': Colors.lightGreen,
    },
    {
      'score': 5,
      'emoji': '🤩',
      'label': 'عالی',
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _learningsController.dispose();
    _winsController.dispose();
    _gratitudeController.dispose();
    _challengesController.dispose();
    _tomorrowFocusController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final targetDate = widget.date ?? DateTime.now().toIso8601String().substring(0, 10);
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'daily_reflections',
        where: 'date = ?',
        whereArgs: [targetDate],
      );
      if (maps.isNotEmpty && mounted) {
        final entry = ReflectionEntry.fromMap(maps.first);
        setState(() {
          _moodScore = entry.moodScore;
          _reflectionController.text = entry.reflectionText ?? '';
          _learningsController.text = entry.learnings ?? '';
          _winsController.text = entry.wins ?? '';
          _gratitudeController.text = entry.gratitude ?? '';
          _challengesController.text = entry.challenges ?? '';
          _tomorrowFocusController.text = entry.tomorrowFocus ?? '';
          _isPrivate = entry.isPrivate == 1;
        });
      }
    } catch (e) {
      debugPrint('Error loading existing reflection: $e');
    }
  }

  Future<void> _saveReflection() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = widget.date ?? DateTime.now().toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final entry = ReflectionEntry(
        date: todayStr,
        moodScore: _moodScore,
        reflectionText: _reflectionController.text.trim().isNotEmpty ? _reflectionController.text.trim() : null,
        learnings: _learningsController.text.trim().isNotEmpty ? _learningsController.text.trim() : null,
        gratitude: _gratitudeController.text.trim().isNotEmpty ? _gratitudeController.text.trim() : null,
        wins: _winsController.text.trim().isNotEmpty ? _winsController.text.trim() : null,
        challenges: _challengesController.text.trim().isNotEmpty ? _challengesController.text.trim() : null,
        tomorrowFocus: _tomorrowFocusController.text.trim().isNotEmpty ? _tomorrowFocusController.text.trim() : null,
        isPrivate: _isPrivate ? 1 : 0,
        createdAt: nowMs,
      );

      await db.insert(
        'daily_reflections',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      HapticFeedback.mediumImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأمل روزانه شما با موفقیت ثبت شد 🌙', style: TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: Color(0xff10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving daily reflection: $e');
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getJalaliMonthName(int month) {
    const months = [
      'فروردین', 'اردیبهشت', 'خرداد',
      'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر',
      'دی', 'بهمن', 'اسفند'
    ];
    return months[month - 1];
  }

  String _getDayOfWeekName(int weekday) {
    const days = [
      'دوشنبه', 'سه‌شنبه', 'چهارشنبه',
      'پنج‌شنبه', 'جمعه', 'شنبه', 'یک‌شنبه'
    ];
    return days[weekday - 1];
  }

  String _getHeaderDate() {
    final dateStr = widget.date ?? DateTime.now().toIso8601String().substring(0, 10);
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final jalali = Jalali.fromDateTime(dt);
    return '${_getDayOfWeekName(dt.weekday)}، ${jalali.day} ${_getJalaliMonthName(jalali.month)} ${jalali.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تأمل و ارزیابی روزانه 🌙',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  _getHeaderDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mood Rating Score
                        Text(
                          'حالت روحی امروز شما چطور بود؟',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _moodOptions.map((opt) {
                            final score = opt['score'] as int;
                            final isSelected = _moodScore == score;
                            final optColor = opt['color'] as Color;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _moodScore = score;
                                });
                              },
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? optColor.withValues(alpha: 0.15)
                                          : colors.card.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? optColor.withValues(alpha: 0.6)
                                            : colors.border.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      opt['emoji'] as String,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Wins Note
                        _buildInputField(
                          controller: _winsController,
                          label: '🏆 بردها و دستاوردهای امروز (چه کارهایی خوب پیش رفت؟)',
                          hint: 'مثال: اتمام فاز اول پروژه، ورزش کردن، تمرکز خوب...',
                          maxLines: 2,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Gratitude Note
                        _buildInputField(
                          controller: _gratitudeController,
                          label: '💖 شکرگزاری (بابت چه چیزهایی در امروز سپاس‌گزارید؟)',
                          hint: 'مثال: صحبت با یک دوست قدیمی، هوای خوب، سلامتی...',
                          maxLines: 2,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Challenges Note
                        _buildInputField(
                          controller: _challengesController,
                          label: '⚡ چالش‌ها و دشواری‌ها (چه چیزهایی سخت بود؟)',
                          hint: 'مثال: حواس‌پرتی، کمبود خواب، بحث با همکار...',
                          maxLines: 2,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Learnings Note
                        _buildInputField(
                          controller: _learningsController,
                          label: '📚 درس‌های آموخته‌شده (امروز چه چیزی یاد گرفتید؟)',
                          hint: 'مثال: نیاز به استراحت منظم دارم، برنامه‌ریزی واقع‌بینانه‌تر...',
                          maxLines: 2,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Tomorrow Focus Note
                        _buildInputField(
                          controller: _tomorrowFocusController,
                          label: '🎯 تمرکز اصلی فردا (مهم‌ترین کار برای فردا چیست؟)',
                          hint: 'مثال: حل مسئله پیچیده الگوریتم، خواب زودتر...',
                          maxLines: 2,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Reflection Note
                        _buildInputField(
                          controller: _reflectionController,
                          label: '📝 یادداشت و بازتاب آزاد (هر چیزی که دوست دارید بنویسید)',
                          hint: 'مثال: جریان کلی روز، احساسات و تحلیل شخصی...',
                          maxLines: 4,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text('پنهان کردن از دستیار هوش مصنوعی (خصوصی)', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                          subtitle: Text('با فعال کردن این گزینه، اطلاعات این بازتاب هرگز به دستیار هوشمند ابری فرستاده نخواهد شد.', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                          value: _isPrivate,
                          onChanged: (val) => setState(() => _isPrivate = val),
                          activeThumbColor: colors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveReflection,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'تایید و ثبت تأمل روزانه',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    required RitmoColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            fillColor: colors.card.withValues(alpha: 0.1),
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }
}
