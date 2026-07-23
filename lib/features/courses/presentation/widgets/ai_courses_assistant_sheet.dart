import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/courses_ai_helper.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class AiCoursesAssistantSheet extends StatefulWidget {

  const AiCoursesAssistantSheet({
    super.key,
    required this.activeCourses,
    required this.onScheduleSuggested,
  });
  final List<Course> activeCourses;
  final Function(Map<String, dynamic>) onScheduleSuggested;

  @override
  State<AiCoursesAssistantSheet> createState() => _AiCoursesAssistantSheetState();
}

class _AiCoursesAssistantSheetState extends State<AiCoursesAssistantSheet> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _suggestion;

  final List<String> _quickPrompts = [
    'تقسیم کتاب برنامه‌نویسی به واحدهای درسی',
    'زمان‌بندی دوره ویدیویی آموزش زبان انگلیسی',
    'بودجه‌بندی تمرین‌های مهارت عملی خوش‌نویسی',
  ];

  Future<void> _generateSuggestion(String promptText) async {
    if (promptText.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _suggestion = null;
    });

    try {
      final result = await CoursesAiHelper.getCourseSuggestion(promptText);
      setState(() {
        _suggestion = result;
      });
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('متأسفانه پاسخی دریافت نشد. لطفاً دوباره تلاش کنید.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating course suggestion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFarsiWeekdayNames(List<dynamic> days) {
    if (days.isEmpty) return 'زوج (شنبه، دوشنبه، چهارشنبه)';
    final names = days.map((d) {
      switch (d) {
        case 6: return 'شنبه';
        case 0: return 'یکشنبه';
        case 1: return 'دوشنبه';
        case 2: return 'سه‌شنبه';
        case 3: return 'چهارشنبه';
        case 4: return 'پنجشنبه';
        case 5: return 'جمعه';
        default: return '';
      }
    }).where((n) => n.isNotEmpty).join('، ');
    return names;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.sparkles, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'دستیار هوشمند دوره‌های آموزشی',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سلام! چه کتاب یا موضوع جدیدی می‌خواهی یاد بگیری؟ نام یا سرفصل‌های آن را بنویس تا برایت ساختاربندی و زمان‌بندی کنم 👇',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prompt input
                  TextField(
                    controller: _inputController,
                    maxLines: 3,
                    style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                    decoration: RitmoTheme.inputDecoration(
                      context,
                      label: 'مثال: تقسیم سرفصل‌های کتاب فلاتر پیشرفته به واحدهای درسی کوتاه',
                      icon: CupertinoIcons.chat_bubble_text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _generateSuggestion(_inputController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'برنامه‌ریزی هوشمند 🪄',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick prompts list
                  if (!_isLoading && _suggestion == null) ...[
                    Text(
                      'پیشنهادهای آماده:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quickPrompts.length,
                      itemBuilder: (context, index) {
                        final text = _quickPrompts[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              _inputController.text = text;
                              _generateSuggestion(text);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.textPrimary.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.chevron_left_2, size: 12, color: colors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 11.5,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // AI Result Preview Card
                  if (_suggestion != null) ...[
                    Text(
                      'طرح پیشنهادی هوش مصنوعی:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RitmoTheme.glassCardLight(
                      borderRadius: 20,
                      color: colors.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('🪄', style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _suggestion!['title'] ?? 'دوره پیشنهادی',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _suggestion!['courseType'] ?? 'CUSTOM',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Details
                            _buildPreviewRow('تعداد کل جلسات پیشنهادی', '${toPersianDigits(_suggestion!['totalSessions'])} ${_suggestion!['unitLabel'] ?? 'جلسه'}', colors),
                            const SizedBox(height: 10),
                            _buildPreviewRow('مدت زمان هر جلسه', '${toPersianDigits(_suggestion!['sessionDurationMinutes'])} دقیقه', colors),
                            const SizedBox(height: 10),
                            _buildPreviewRow('هدف مطالعه هفتگی', '${toPersianDigits(_suggestion!['weeklyTargetSessions'])} جلسه در هفته', colors),
                            const SizedBox(height: 10),
                            _buildPreviewRow('روزهای ترجیحی', _getFarsiWeekdayNames(_suggestion!['preferredDays'] ?? []), colors),
                            if (_suggestion!['provider'] != null) ...[
                              const SizedBox(height: 10),
                              _buildPreviewRow('منبع/ارائه‌دهنده', _suggestion!['provider'], colors),
                            ],
                            const Divider(height: 24),
                            // Explanation
                            Text(
                              'تحلیل دستیار هوشمند:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _suggestion!['explanation'] ?? 'این ساختار بهینه‌ترین حالت برای توزیع متعادل بار یادگیری شماست.',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                height: 1.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Apply button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onScheduleSuggested(_suggestion!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'اعمال و شخصی‌سازی نهایی طرح',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPreviewRow(String label, String value, RitmoColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, color: colors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
      ],
    );
  }
}
