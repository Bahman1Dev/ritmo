import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';
import 'package:ritmo/core/widgets/ritmo_sheet_scaffold.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/course_formatters.dart';
import 'package:shamsi_date/shamsi_date.dart';

class RecoveryModeSheet extends StatefulWidget {
  const RecoveryModeSheet({
    super.key,
    required this.course,
    required this.sessions,
    this.onApplied,
  });

  final Course course;
  final List<CourseSession> sessions;
  final VoidCallback? onApplied;

  static Future<void> show(
    BuildContext context, {
    required Course course,
    required List<CourseSession> sessions,
    VoidCallback? onApplied,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecoveryModeSheet(
        course: course,
        sessions: sessions,
        onApplied: onApplied,
      ),
    );
  }

  @override
  State<RecoveryModeSheet> createState() => _RecoveryModeSheetState();
}

class _RecoveryModeSheetState extends State<RecoveryModeSheet> {
  int _selectedPlanIndex = 0; // 0: Express (+2 target), 1: Extend Date (+14 days), 2: Prune
  bool _isApplying = false;

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return '${toPersianDigits(j.year)}/${toPersianDigits(j.month.toString().padLeft(2, '0'))}/${toPersianDigits(j.day.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pendingCount = widget.sessions.where((s) => !s.isCompleted && !s.isSkipped).length;
    final now = DateTime.now();

    // Plan 1: Express
    final newWeeklyTarget1 = (widget.course.weeklyTargetSessions + 2).clamp(1, 14);
    final estEnd1 = CourseScheduler.estimatedEndDate(
      remaining: pendingCount,
      weeklyTarget: newWeeklyTarget1,
      from: now,
      preferredDays: widget.course.preferredDays,
    );

    // Plan 2: Extend
    final newWeeklyTarget2 = widget.course.weeklyTargetSessions;
    final estEnd2 = CourseScheduler.estimatedEndDate(
      remaining: pendingCount,
      weeklyTarget: newWeeklyTarget2,
      from: now.add(const Duration(days: 14)),
      preferredDays: widget.course.preferredDays,
    );

    // Plan 3: Prune (skip practice/review sessions)
    final corePending = widget.sessions.where((s) => !s.isCompleted && !s.isSkipped && s.activityKind == CourseActivityKind.learn).length;
    final estEnd3 = CourseScheduler.estimatedEndDate(
      remaining: corePending,
      weeklyTarget: widget.course.weeklyTargetSessions,
      from: now,
      preferredDays: widget.course.preferredDays,
    );

    final plans = [
      {
        'title': '🚀 برنامه فشرده (افزایش سرعت)',
        'description': 'هدف هفتگی از ${toPersianDigits(widget.course.weeklyTargetSessions)} به ${toPersianDigits(newWeeklyTarget1)} جلسه در هفته افزایش می‌یابد.',
        'endDate': estEnd1 != null ? _formatJalali(estEnd1) : 'مشخص نیست',
      },
      {
        'title': '📅 تمدید زمان‌بندی (کاهش فشار)',
        'description': 'بدون تغییر در فشار هفتگی، پایان دوره به میزان ۲ هفته تمدید می‌شود.',
        'endDate': estEnd2 != null ? _formatJalali(estEnd2) : 'مشخص نیست',
      },
      {
        'title': '🎯 تمرکز بر جلسات اصلی (غربال)',
        'description': 'جلسات فرعی و تمرینی حذف یا عبور داده شده و تمرکز روی ${toPersianDigits(corePending)} جلسه اصلی یادگیری قرار می‌گیرد.',
        'endDate': estEnd3 != null ? _formatJalali(estEnd3) : 'مشخص نیست',
      },
    ];

    return RitmoSheetScaffold(
      title: 'حالت جبران (Recovery Mode)',
      subtitle: 'دورهٔ «${widget.course.title}» دچار عقب‌افتادگی شده. یک مسیر جبران انتخاب کنید.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(plans.length, (idx) {
              final plan = plans[idx];
              final isSelected = _selectedPlanIndex == idx;

              return GestureDetector(
                onTap: () => setState(() => _selectedPlanIndex = idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: isSelected ? colors.primary : colors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              plan['title']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['description']!,
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'تاریخ تخمینی پایان: ${plan["endDate"]}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isApplying ? null : () => _applyPlan(newWeeklyTarget1, estEnd2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isApplying
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('اعمال برنامه جبرانی انتخاب‌شده', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPlan(int expressTarget, DateTime? extendEnd) async {
    setState(() => _isApplying = true);
    try {
      if (_selectedPlanIndex == 0) {
        // Express
        final updated = widget.course.copyWith(weeklyTargetSessions: expressTarget);
        await CoursesRepository.instance.updateCourse(updated);
      } else if (_selectedPlanIndex == 1) {
        // Extend
        final targetDateStr = extendEnd != null ? RitmoDate(extendEnd).value : null;
        final updated = widget.course.copyWith(targetEndDate: targetDateStr);
        await CoursesRepository.instance.updateCourse(updated);
      } else if (_selectedPlanIndex == 2) {
        // Prune non-learn sessions
        for (final s in widget.sessions) {
          if (!s.isCompleted && !s.isSkipped && s.activityKind != CourseActivityKind.learn) {
            await CoursesRepository.instance.skipSession(s.id, reason: 'حالت جبران: غربال sessions غیر‌اصلی');
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onApplied?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در اعمال برنامه جبرانی: $e')),
        );
      }
    }
  }
}
