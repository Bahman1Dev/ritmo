import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';

class StudyTimerSheet extends StatefulWidget {

  const StudyTimerSheet({
    super.key,
    required this.course,
    required this.session,
    required this.onTimerFinished,
  });
  final Course course;
  final CourseSession session;
  final VoidCallback onTimerFinished;

  @override
  State<StudyTimerSheet> createState() => _StudyTimerSheetState();
}

class _StudyTimerSheetState extends State<StudyTimerSheet> with TickerProviderStateMixin {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isRunning = true;
  final TextEditingController _noteController = TextEditingController();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final hrs = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    final hrsStr = hrs.toString().padLeft(2, '0');
    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = secs.toString().padLeft(2, '0');

    if (hrs > 0) {
      return '$hrsStr:$minsStr:$secsStr';
    }
    return '$minsStr:$secsStr';
  }

  void _togglePlayPause() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    });
  }

  Future<void> _finishSession() async {
    final elapsedMinutes = (_secondsElapsed / 60).ceil();
    final actualDuration = elapsedMinutes > 0 ? elapsedMinutes : 1;

    // Show a dialog to confirm save, input note
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xff12141C) : Colors.white,
          title: Text(
            'ثبت پایان جلسه مطالعه',
            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مدت زمان کل مطالعه: ${toPersianDigits(actualDuration)} دقیقه',
                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                decoration: RitmoTheme.inputDecoration(
                  context,
                  label: 'یادداشت یا خلاصه درس (اختیاری)',
                  icon: CupertinoIcons.doc_text,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'ادامه تایمر',
                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'ثبت و ذخیره',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result ?? false) {
      await CoursesRepository.instance.completeSession(
        sessionId: widget.session.id,
        actualDurationMinutes: actualDuration,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      widget.onTimerFinished();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'جلسه مطالعه با موفقیت ثبت شد! ${toPersianDigits(actualDuration)} دقیقه 💪✨',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: colors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoTheme.glassCardLight(
      borderRadius: 30,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.course.title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.session.sessionTitle ?? '${widget.course.unitLabelResolved} ${widget.session.sessionNumber}',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Timer display
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_isRunning ? _pulseController.value * 0.05 : 0.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff3B82F6).withValues(alpha: 0.1),
                    border: Border.all(
                      color: const Color(0xff3B82F6).withValues(alpha: 0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      if (_isRunning)
                        BoxShadow(
                          color: const Color(0xff3B82F6).withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: _pulseController.value * 10,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      toPersianDigits(_formatTime(_secondsElapsed)),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause / Resume
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    _isRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid,
                    color: colors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Stop / Finish
              GestureDetector(
                onTap: _finishSession,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Use warning/orange color. Avoid RED because of clinical rule!
                    color: colors.warning.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    CupertinoIcons.square_fill,
                    color: colors.warning,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
}
