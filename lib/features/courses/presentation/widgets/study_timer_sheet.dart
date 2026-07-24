import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/course_timer_service.dart';
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final activeTimer = CourseTimerService.instance.activeTimer;
    if (activeTimer != null && activeTimer.sessionId == widget.session.id) {
      _secondsElapsed = CourseTimerService.instance.currentElapsedSeconds;
      _isRunning = !activeTimer.isPaused;
    } else {
      CourseTimerService.instance.startTimer(widget.course.id, widget.session.id);
      _secondsElapsed = 0;
      _isRunning = true;
    }

    if (_isRunning) {
      _pulseController.repeat(reverse: true);
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _secondsElapsed = CourseTimerService.instance.currentElapsedSeconds;
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
        CourseTimerService.instance.resumeTimer();
        _pulseController.repeat(reverse: true);
      } else {
        CourseTimerService.instance.pauseTimer(_secondsElapsed);
        _pulseController.stop();
      }
    });
  }

  Future<void> _finishSession() async {
    final elapsedMinutes = (_secondsElapsed / 60).ceil();
    final actualDuration = elapsedMinutes > 0 ? elapsedMinutes : 1;

    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ثبت و اتمام جلسه مطالعه',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'مدت زمان مطالعه شما: ${toPersianDigits(actualDuration.toString())} دقیقه',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'یادداشت یا خلاصه جلسه (اختیاری)...',
                      hintStyle: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      fillColor: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تأیید و ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await CourseTimerService.instance.stopTimer();
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
            content: Text('${widget.course.unitLabelResolved} ${widget.session.sessionNumber} با موفقیت تکمیل شد. 🎉'),
            backgroundColor: colors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 30,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.title,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.course.unitLabelResolved} ${widget.session.sessionNumber}',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark_circle_fill, color: colors.textSecondary.withValues(alpha: 0.5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Timer Display
              ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.02).animate(_pulseController),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.2),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: _isRunning ? 0.6 : 0.2),
                      width: 3,
                    ),
                    boxShadow: [
                      if (_isRunning)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        toPersianDigits(_formatTime(_secondsElapsed)),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRunning ? 'در حال مطالعه...' : 'متوقف شده',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: _isRunning ? colors.success : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePlayPause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? Colors.amber.shade700 : colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(_isRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 20, color: Colors.white),
                    label: Text(
                      _isRunning ? 'مکس' : 'ادامه',
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _finishSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(CupertinoIcons.checkmark_alt, size: 20, color: Colors.white),
                    label: const Text(
                      'اتمام جلسه',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
}
