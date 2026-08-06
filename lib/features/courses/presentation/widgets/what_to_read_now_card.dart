import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/course_energy_engine.dart';
import 'package:ritmo/features/courses/logic/course_timer_service.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';
import 'package:ritmo/features/courses/presentation/widgets/focus_mode_screen.dart';

class WhatToReadNowCard extends StatelessWidget {
  const WhatToReadNowCard({
    super.key,
    required this.courses,
    required this.sessionsMap,
    required this.currentEnergyLevel,
    required this.todayStr,
    this.onStartSession,
  });

  final List<Course> courses;
  final Map<String, List<CourseSession>> sessionsMap;
  final String currentEnergyLevel;
  final String todayStr;
  final VoidCallback? onStartSession;

  CourseSession? _pickRecommendedSession(Map<String, Course> coursesMap) {
    final candidateSessions = <CourseSession>[];

    for (final c in courses) {
      if (c.status != CourseStatus.active || c.isArchived) continue;
      final sessions = sessionsMap[c.id] ?? [];
      final pending = sessions.where((s) => !s.isCompleted && !s.isSkipped).toList();
      if (pending.isNotEmpty) {
        // Prioritize overdue or today scheduled or first pending
        final overdueOrToday = pending.where((s) => s.plannedDate == todayStr || s.isOverdue(todayStr)).toList();
        if (overdueOrToday.isNotEmpty) {
          candidateSessions.add(overdueOrToday.first);
        } else {
          candidateSessions.add(pending.first);
        }
      }
    }

    if (candidateSessions.isEmpty) return null;

    final ranked = CourseEnergyEngine.filterAndRankForEnergy(
      candidateSessions: candidateSessions,
      coursesMap: coursesMap,
      currentEnergyLevel: currentEnergyLevel,
    );

    return ranked.isNotEmpty ? ranked.first : candidateSessions.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final coursesMap = <String, Course>{for (final c in courses) c.id: c};
    final session = _pickRecommendedSession(coursesMap);

    if (session == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تمامی جلسات برنامه‌ریزی‌شده تکمیل یا عبور داده شده‌اند! 🎉',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final course = coursesMap[session.courseId];
    if (course == null) return const SizedBox.shrink();

    final isOverdue = session.isOverdue(todayStr);
    final duration = session.estimatedDurationMinutes ?? course.sessionDurationMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.sparkles,
                      size: 14,
                      color: isOverdue ? Colors.red : colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue ? 'پیشنهاد هوشمند (عقب‌افتاده)' : 'پیشنهاد الان چی بخونم؟',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${toPersianDigits(duration)} دقیقه',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(course.emojiResolved, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionTitle ?? '${course.unitLabelResolved} ${toPersianDigits(session.sessionNumber)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      course.title,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                await CourseTimerService.instance.startTimer(course.id, session.id);
                if (context.mounted) {
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FocusModeScreen(
                          course: course,
                          session: session,
                        ),
                      ),
                    ),
                  );
                }
                onStartSession?.call();
              },
              icon: const Icon(CupertinoIcons.play_circle_fill, size: 20),
              label: const Text(
                'شروع تمرکز روی این جلسه',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
