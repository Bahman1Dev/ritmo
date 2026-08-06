import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/course_timer_service.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';
import 'package:ritmo/features/courses/presentation/widgets/session_debrief_sheet.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({
    super.key,
    required this.course,
    required this.session,
  });

  final Course course;
  final CourseSession session;

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Listen to timer service updates
    CourseTimerService.instance.addListener(_onTimerUpdated);
  }

  @override
  void dispose() {
    CourseTimerService.instance.removeListener(_onTimerUpdated);
    _breathingController.dispose();
    super.dispose();
  }

  void _onTimerUpdated() {
    if (mounted) setState(() {});
  }

  String _formatTimer(int elapsedSec) {
    final m = elapsedSec ~/ 60;
    final s = elapsedSec % 60;
    return '${toPersianDigits(m.toString().padLeft(2, "0"))}:${toPersianDigits(s.toString().padLeft(2, "0"))}';
  }

  Future<void> _finishTimer() async {
    final elapsedSec = CourseTimerService.instance.currentElapsedSeconds;
    final elapsedMin = (elapsedSec / 60).ceil().clamp(1, 480);
    await CourseTimerService.instance.stopTimer();

    if (mounted) {
      Navigator.pop(context);
      unawaited(
        SessionDebriefSheet.show(
          context,
          session: widget.session,
          actualDurationMinutes: elapsedMin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerService = CourseTimerService.instance;
    final timer = timerService.activeTimer;
    final elapsedSec = timerService.currentElapsedSeconds;
    final targetSec = (widget.session.estimatedDurationMinutes ?? widget.course.sessionDurationMinutes) * 60;
    final progress = (elapsedSec / targetSec).clamp(0.0, 1.0);
    final isPaused = timer?.isPaused ?? false;

    final bgColor = isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'حالت تمرکز عمیق',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Course & Session Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.course.emojiResolved, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          widget.course.title,
                          style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.session.sessionTitle ?? '${widget.course.unitLabelResolved} ${toPersianDigits(widget.session.sessionNumber)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Breathing Visual Ring & Big Display
            ScaleTransition(
              scale: _breathingAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: colors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPaused ? Colors.amber : colors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimer(elapsedSec),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPaused ? 'در حال مکث' : 'زمان گذشته',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Controls: Pause / Resume / Finish
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pause / Resume
                  ElevatedButton.icon(
                    onPressed: () {
                      if (isPaused) {
                        timerService.resumeTimer();
                      } else {
                        timerService.pauseTimer(elapsedSec);
                      }
                    },
                    icon: Icon(isPaused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill),
                    label: Text(isPaused ? 'ادامه' : 'مکث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaused ? Colors.amber : colors.surface,
                      foregroundColor: isPaused ? Colors.black : colors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  // Finish / Debrief
                  ElevatedButton.icon(
                    onPressed: _finishTimer,
                    icon: const Icon(CupertinoIcons.checkmark_circle_fill),
                    label: const Text('پایان و بازخورد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
