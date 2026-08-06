import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo_sheet_scaffold.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class SessionDebriefSheet extends StatefulWidget {
  const SessionDebriefSheet({
    super.key,
    required this.session,
    required this.actualDurationMinutes,
    this.initialNote,
    this.onCompleted,
  });

  final CourseSession session;
  final int actualDurationMinutes;
  final String? initialNote;
  final VoidCallback? onCompleted;

  static Future<void> show(
    BuildContext context, {
    required CourseSession session,
    required int actualDurationMinutes,
    String? initialNote,
    VoidCallback? onCompleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDebriefSheet(
        session: session,
        actualDurationMinutes: actualDurationMinutes,
        initialNote: initialNote,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<SessionDebriefSheet> createState() => _SessionDebriefSheetState();
}

class _SessionDebriefSheetState extends State<SessionDebriefSheet> {
  int _understandingScore = 4;
  bool _needsReview = false;
  late TextEditingController _noteController;
  late TextEditingController _takeawayController;
  late TextEditingController _questionController;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _understandingOptions = [
    {'score': 1, 'label': 'خیلی سخت', 'emoji': '❌'},
    {'score': 2, 'label': 'ابهام‌دار', 'emoji': '⚠️'},
    {'score': 3, 'label': 'متوسط', 'emoji': '😐'},
    {'score': 4, 'label': 'خوب', 'emoji': '👍'},
    {'score': 5, 'label': 'مسلط', 'emoji': '🌟'},
  ];

  @override
  void initState() {
    super.initState();
    _understandingScore = widget.session.understandingScore ?? 4;
    _needsReview = widget.session.needsReview;
    _noteController = TextEditingController(text: widget.initialNote ?? widget.session.note ?? '');
    _takeawayController = TextEditingController(text: widget.session.keyTakeaway ?? '');
    _questionController = TextEditingController(text: widget.session.openQuestion ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _takeawayController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await CoursesRepository.instance.completeSession(
        sessionId: widget.session.id,
        actualDurationMinutes: widget.actualDurationMinutes,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        understandingScore: _understandingScore,
        needsReview: _needsReview || _understandingScore <= 2,
        keyTakeaway: _takeawayController.text.trim().isEmpty ? null : _takeawayController.text.trim(),
        openQuestion: _questionController.text.trim().isEmpty ? null : _questionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت جلسه: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoSheetScaffold(
      title: 'بازخورد و سنجش درک (${widget.session.sessionTitle ?? "جلسه"})',
      subtitle: 'با ۳ لمس سریع میزان تسلط و نکتهٔ کلیدی را ثبت کنید',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'میزان درک و تسلط شما:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Understanding Rating Row (3-tap rating)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _understandingOptions.map((opt) {
                final score = opt['score'] as int;
                final isSelected = _understandingScore == score;
                return GestureDetector(
                  onTap: () => setState(() => _understandingScore = score),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(opt['emoji'] as String, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colors.primary : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 2. Needs Review Checkbox
            CheckboxListTile(
              value: _needsReview,
              onChanged: (val) => setState(() => _needsReview = val ?? false),
              title: Text(
                'علامت‌گذاری برای مرور مجدد (مرور فضادار)',
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
              subtitle: Text(
                'در صورت تیک زدن، این جلسه در یادآوری‌های مرور دوره‌ای پیشنهادی قرار می‌گیرد.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              contentPadding: EdgeInsets.zero,
              activeColor: colors.primary,
            ),

            const SizedBox(height: 12),

            // 3. Key Takeaway (نکته کلیدی)
            TextField(
              controller: _takeawayController,
              decoration: InputDecoration(
                labelText: 'نکته کلیدی یا برداشت اصلی (اختیاری)',
                hintText: 'مثلاً: مفهوم اصلی این بخش...',
                prefixIcon: Icon(CupertinoIcons.lightbulb, color: colors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // 4. Open Question (سوال یا ابهام باقی‌مانده)
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'سوال یا ابهام باقی‌مانده (اختیاری)',
                hintText: 'چیزی که باید بعداً پرسیده یا تحقیق شود...',
                prefixIcon: const Icon(CupertinoIcons.question_diamond, color: Colors.orange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // 5. General Study Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'یادداشت مطالعه (اختیاری)',
                prefixIcon: const Icon(CupertinoIcons.doc_text, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'ثبت نهایی جلسه و تکمیل',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
