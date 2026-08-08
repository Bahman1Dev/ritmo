import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:ritmo/features/study/domain/study_review_policy.dart';
import 'package:ritmo/features/study/logic/study_timer_service.dart';

class SessionTimerSheet extends StatefulWidget {
  const SessionTimerSheet({super.key, required this.subject, this.topic});

  final StudySubject subject;
  final StudyTopic? topic;

  static Future<void> show(BuildContext context, {required StudySubject subject, StudyTopic? topic}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SessionTimerSheet(subject: subject, topic: topic),
    );
  }

  @override
  State<SessionTimerSheet> createState() => _SessionTimerSheetState();
}

class _SessionTimerSheetState extends State<SessionTimerSheet> {
  StreamSubscription? _sub;
  ActiveStudySessionState? _state;
  SessionFeedback _feedback = SessionFeedback.understood;

  @override
  void initState() {
    super.initState();
    _sub = StudyTimerService.instance.stream.listen((state) {
      if (mounted) setState(() => _state = state);
    });

    if (!StudyTimerService.instance.hasActiveSession) {
      StudyTimerService.instance.startSession(
        subjectId: widget.subject.id,
        topicId: widget.topic?.id,
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _finishSession() async {
    final curTopic = widget.topic;
    ReviewResult? reviewRes;
    if (curTopic != null) {
      reviewRes = StudyReviewPolicy.evaluate(
        feedback: _feedback,
        currentMastery: curTopic.mastery,
        reviewCount: curTopic.studyCompletedMinutes > 0 ? 1 : 0,
      );
    }

    String? nextReviewDateIso;
    if (reviewRes != null) {
      final nextDt = DateTime.now().add(Duration(days: reviewRes.nextReviewDays));
      nextReviewDateIso = nextDt.toIso8601String().substring(0, 10);
    }

    await StudyTimerService.instance.stopAndSaveSession(
      newMastery: reviewRes?.nextMastery,
      nextReviewDateIso: nextReviewDateIso,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = _state?.elapsedSeconds(nowMs) ?? 0;

    final minutes = elapsedSec ~/ 60;
    final seconds = elapsedSec % 60;
    final timeStr = '${RitmoNumber.faInt(minutes)}:${seconds.toString().padLeft(2, '0')}';

    final isPaused = _state?.isPaused ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.subject.name,
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          if (widget.topic != null)
            Text(
              widget.topic!.name,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
            ),
          const SizedBox(height: 24),
          // Timer Circle Display
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.1),
              border: Border.all(color: colors.primary, width: 4),
            ),
            child: Center(
              child: Text(
                timeStr,
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 32, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Control Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 48,
                icon: Icon(isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled, color: colors.primary),
                onPressed: () {
                  if (isPaused) {
                    StudyTimerService.instance.resumeSession();
                  } else {
                    StudyTimerService.instance.pauseSession();
                  }
                },
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _finishSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: const Text('پایان جلسه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Feedback options
          Text('نتیجه مطالعه:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary)),
          const SizedBox(height: 8),
          SegmentedButton<SessionFeedback>(
            segments: const [
              ButtonSegment(value: SessionFeedback.understood, label: Text('فهمیدم', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11))),
              ButtonSegment(value: SessionFeedback.partial, label: Text('نصفه‌نیمه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11))),
              ButtonSegment(value: SessionFeedback.needAgain, label: Text('دوباره', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11))),
            ],
            selected: {_feedback},
            onSelectionChanged: (set) => setState(() => _feedback = set.first),
          ),
        ],
      ),
    );
  }
}
