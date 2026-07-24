import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class AiSyllabusSheet extends StatefulWidget {
  const AiSyllabusSheet({
    super.key,
    required this.onImported,
  });

  final VoidCallback onImported;

  @override
  State<AiSyllabusSheet> createState() => _AiSyllabusSheetState();
}

class _AiSyllabusSheetState extends State<AiSyllabusSheet> {
  final _titleController = TextEditingController(text: 'دوره جدید با سرفصل AI');
  final _inputController = TextEditingController();

  List<CourseSession> _draftSessions = [];
  bool _isParsed = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _parseSyllabusText() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      RitmoToast.show(context, 'لطفاً متن سرفصل یا JSON را وارد کنید.', iconColor: Colors.amber);
      return;
    }

    final drafts = <CourseSession>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      // Try parsing as JSON array
      final decoded = jsonDecode(text);
      if (decoded is List) {
        for (var i = 0; i < decoded.length; i++) {
          final item = decoded[i] as Map<String, dynamic>;
          drafts.add(CourseSession(
            id: 'draft_$i',
            courseId: '',
            sessionNumber: i + 1,
            sessionTitle: item['title']?.toString() ?? 'جلسه ${i + 1}',
            sectionTitle: item['section']?.toString(),
            learningObjective: item['objective']?.toString(),
            estimatedDurationMinutes: int.tryParse(item['duration']?.toString() ?? '45') ?? 45,
            difficulty: int.tryParse(item['difficulty']?.toString() ?? '3') ?? 3,
            createdAt: nowMs,
            updatedAt: nowMs,
          ));
        }
      }
    } catch (_) {
      // Fallback line-by-line parsing
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      for (var i = 0; i < lines.length; i++) {
        drafts.add(CourseSession(
          id: 'draft_$i',
          courseId: '',
          sessionNumber: i + 1,
          sessionTitle: lines[i].trim(),
          estimatedDurationMinutes: 45,
          createdAt: nowMs,
          updatedAt: nowMs,
        ));
      }
    }

    if (drafts.isEmpty) {
      RitmoToast.show(context, 'امکان استخراج سرفصل از متن وارد شده وجود نداشت.', iconColor: Colors.amber);
      return;
    }

    setState(() {
      _draftSessions = drafts;
      _isParsed = true;
    });
  }

  Future<void> _saveCourseAndSessions() async {
    if (_draftSessions.isEmpty || _isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      RitmoToast.show(context, 'عنوان دوره را وارد کنید.', iconColor: Colors.amber);
      return;
    }

    setState(() => _isSaving = true);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      final course = Course(
        id: 'course_${nowMs}_${title.hashCode}',
        title: title,
        totalSessions: _draftSessions.length,
        sessionDurationMinutes: 45,
        courseType: CourseType.video,
        preferredDays: const [6, 1, 3],
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      await CoursesRepository.instance.createCourseWithSessions(course, _draftSessions);

      widget.onImported();
      if (mounted) {
        RitmoToast.show(context, 'دوره "$title" با ${_draftSessions.length} جلسه ثبت شد! 🎉', iconColor: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving AI syllabus: $e');
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
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ایجاد دوره با سرفصل AI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                if (!_isParsed) ...[
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                    decoration: const InputDecoration(
                      labelText: 'عنوان دوره آموزشی',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'متن سرفصل، فهرست عناوین، یا فرمت JSON تولیدشده توسط AI را اینجا پیست کنید...\nمثال:\nجلسه ۱: مقدمه و نصب فلاتر\nجلسه ۲: متغیرها و انواع داده\nجلسه ۳: ساخت اولین ویجت',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5, fontFamily: 'Vazirmatn'),
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _parseSyllabusText,
                    icon: const Icon(CupertinoIcons.sparkles, size: 18),
                    label: const Text('استخراج سرفصل‌ها و پیش‌نمایش', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'پیش‌نمایش ${_draftSessions.length} جلسه استخراج‌شده:',
                        style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Vazirmatn'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isParsed = false),
                        child: const Text('ویرایش متن ورودی', style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: _draftSessions.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _draftSessions.removeAt(oldIndex);
                          _draftSessions.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final session = _draftSessions[index];
                        return Container(
                          key: ValueKey(session.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Text('${index + 1}. ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  session.sessionTitle ?? 'جلسه ${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _draftSessions.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _saveCourseAndSessions,
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تأیید و ساخت دوره آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
