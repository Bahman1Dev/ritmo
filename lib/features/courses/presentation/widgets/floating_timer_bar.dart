import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/course_timer_service.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';
import 'package:ritmo/features/courses/presentation/widgets/focus_mode_screen.dart';
import 'package:ritmo/features/courses/presentation/widgets/session_debrief_sheet.dart';

class FloatingTimerBar extends StatefulWidget {
  const FloatingTimerBar({super.key});

  @override
  State<FloatingTimerBar> createState() => _FloatingTimerBarState();
}

class _FloatingTimerBarState extends State<FloatingTimerBar> {
  Course? _course;
  CourseSession? _session;

  @override
  void initState() {
    super.initState();
    CourseTimerService.instance.addListener(_onTimerUpdated);
    _loadTimerData();
  }

  @override
  void dispose() {
    CourseTimerService.instance.removeListener(_onTimerUpdated);
    super.dispose();
  }

  void _onTimerUpdated() {
    if (mounted) {
      _loadTimerData();
      setState(() {});
    }
  }

  Future<void> _loadTimerData() async {
    final timer = CourseTimerService.instance.activeTimer;
    if (timer == null) {
      if (_course != null || _session != null) {
        setState(() {
          _course = null;
          _session = null;
        });
      }
      return;
    }

    if (_session?.id != timer.sessionId) {
      final c = await CoursesRepository.instance.getCourseById(timer.courseId);
      final sessions = await CoursesRepository.instance.getSessionsForCourse(timer.courseId);
      final s = sessions.firstWhere((element) => element.id == timer.sessionId, orElse: () => sessions.first);
      if (mounted) {
        setState(() {
          _course = c;
          _session = s;
        });
      }
    }
  }

  String _formatTimer(int elapsedSec) {
    final m = elapsedSec ~/ 60;
    final s = elapsedSec % 60;
    return '${toPersianDigits(m.toString().padLeft(2, "0"))}:${toPersianDigits(s.toString().padLeft(2, "0"))}';
  }

  @override
  Widget build(BuildContext context) {
    final timerService = CourseTimerService.instance;
    if (!timerService.hasActiveTimer || _course == null || _session == null) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final timer = timerService.activeTimer!;
    final elapsedSec = timerService.currentElapsedSeconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FocusModeScreen(
                  course: _course!,
                  session: _session!,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Animated pulse indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: timer.isPaused ? Colors.amber : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),

                Text(_course!.emojiResolved, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _session!.sessionTitle ?? '${_course!.unitLabelResolved} ${toPersianDigits(_session!.sessionNumber)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _course!.title,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Timer Display
                Text(
                  _formatTimer(elapsedSec),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 8),

                // Pause / Resume
                IconButton(
                  icon: Icon(
                    timer.isPaused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
                    size: 20,
                    color: colors.textPrimary,
                  ),
                  onPressed: () {
                    if (timer.isPaused) {
                      timerService.resumeTimer();
                    } else {
                      timerService.pauseTimer(elapsedSec);
                    }
                  },
                ),

                // Finish button
                IconButton(
                  icon: const Icon(CupertinoIcons.checkmark_circle_fill, size: 22, color: Colors.green),
                  onPressed: () async {
                    final elapsedMin = (elapsedSec / 60).ceil().clamp(1, 480);
                    await timerService.stopTimer();
                    if (context.mounted && _session != null) {
                      unawaited(
                        SessionDebriefSheet.show(
                          context,
                          session: _session!,
                          actualDurationMinutes: elapsedMin,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
