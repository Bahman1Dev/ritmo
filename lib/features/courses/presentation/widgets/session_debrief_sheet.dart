import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class SessionDebriefSheet extends StatefulWidget {
  const SessionDebriefSheet({
    super.key,
    required this.session,
    required this.course,
    required this.actualDurationMinutes,
    required this.onSaved,
  });

  final CourseSession session;
  final Course course;
  final int actualDurationMinutes;
  final VoidCallback onSaved;

  @override
  State<SessionDebriefSheet> createState() => _SessionDebriefSheetState();
}

class _SessionDebriefSheetState extends State<SessionDebriefSheet> {
  int _understandingScore = 4;
  bool _needsReview = false;
  final _keyTakeawayController = TextEditingController();
  final _openQuestionController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _keyTakeawayController.dispose();
    _openQuestionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitDebrief() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await CoursesRepository.instance.completeSession(
        sessionId: widget.session.id,
        actualDurationMinutes: widget.actualDurationMinutes,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        understandingScore: _understandingScore,
        needsReview: _needsReview,
        keyTakeaway: _keyTakeawayController.text.trim().isEmpty ? null : _keyTakeawayController.text.trim(),
        openQuestion: _openQuestionController.text.trim().isEmpty ? null : _openQuestionController.text.trim(),
      );

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error completing debrief: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'جمع‌بندی جلسه مطالعه (${toPersianDigits(widget.actualDurationMinutes.toString())} دقیقه)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),

                // Rating
                const Text(
                  'میزان درک و تسلط شما در این جلسه:',
                  style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final score = index + 1;
                    final isSelected = score <= _understandingScore;
                    return IconButton(
                      icon: Icon(
                        isSelected ? CupertinoIcons.star_fill : CupertinoIcons.star,
                        color: isSelected ? Colors.amber : Colors.white24,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _understandingScore = score),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Key Takeaway
                TextField(
                  controller: _keyTakeawayController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    labelText: 'نکته کلیدی یا دستاورد اصلی جلسه',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Vazirmatn'),
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Open Question
                TextField(
                  controller: _openQuestionController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    labelText: 'سوال یا ابهام باقی‌مانده (برای مرور بعدی)',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Vazirmatn'),
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Needs Review Switch
                SwitchListTile(
                  title: const Text('علامت‌گذاری برای مرور مجدد (Spaced Repetition)', style: TextStyle(fontSize: 12.5, color: Colors.white, fontFamily: 'Vazirmatn')),
                  subtitle: const Text('جلسه مرور هوشمند در تقویم زمان‌بندی می‌شود.', style: TextStyle(fontSize: 10.5, color: Colors.white54, fontFamily: 'Vazirmatn')),
                  value: _needsReview,
                  onChanged: (val) => setState(() => _needsReview = val),
                  activeThumbColor: colors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _submitDebrief,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ثبت نهایی جلسه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
