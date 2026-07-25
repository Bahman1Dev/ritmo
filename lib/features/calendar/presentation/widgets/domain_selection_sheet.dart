import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/courses/presentation/widgets/create_course_sheet.dart';
import 'package:ritmo/features/goals/presentation/widgets/create_goal_sheet.dart';
import 'package:ritmo/features/health/presentation/widgets/medication_form_sheet.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_log_sheet.dart';

class DomainSelectionSheet extends StatelessWidget {
  const DomainSelectionSheet({
    super.key,
    required this.slotMinutes,
    required this.timeStr,
  });

  final int slotMinutes;
  final String timeStr;

  static void show(BuildContext context, int slotMinutes, String timeStr) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DomainSelectionSheet(
        slotMinutes: slotMinutes,
        timeStr: timeStr,
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    final parts = str.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prefilledTimeOfDay = _parseTimeOfDay(timeStr);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CalendarTokens.radiusSheet),
          ),
        ),
        padding: const EdgeInsets.all(CalendarTokens.spacingL),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(CalendarTokens.spacingS),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_task_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: CalendarTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'افزودن برنامه جدید',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        Text(
                          'زمان انتخابی: ساعت ${toPersianDigits(timeStr)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'Vazirmatn',
                            fontSize: CalendarTokens.textLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: CalendarTokens.spacingM),
              const Divider(height: 1),
              const SizedBox(height: CalendarTokens.spacingM),
              _buildOptionTile(
                context,
                title: 'روتین جدید',
                subtitle: 'ثبت عادت، وظیفه روزانه یا روتین جدید',
                icon: Icons.repeat_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => UniversalPlannerSheet(
                      onSaved: () {},
                      prefilledTime: prefilledTimeOfDay,
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'جلسهٔ دوره آموزشی',
                subtitle: 'ثبت جلسه مطالعه یا تمرین برای دوره فعال',
                icon: Icons.school_rounded,
                color: Colors.amber.shade800,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CreateCourseSheet(
                      onCourseCreated: () {},
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'گام هدف',
                subtitle: 'افزودن گام اجرایی برای اهداف فعال',
                icon: Icons.flag_rounded,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CreateGoalSheet(
                      activeGoals: const [],
                      routines: const [],
                      onSaved: () {},
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'مطالعهٔ کنکور',
                subtitle: 'برنامه‌ریزی و ثبت پارت مطالعه درس کنکور',
                icon: Icons.menu_book_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  Navigator.of(context).pop();
                  final subjects = await KonkurRepository.instance.getSubjects();
                  final topics = await KonkurRepository.instance.getTopics();
                  if (context.mounted) {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => KonkurStudySheet(
                        subjects: subjects,
                        topics: topics,
                        onSaved: () {},
                      ),
                    );
                  }
                },
              ),
              _buildOptionTile(
                context,
                title: 'فعالیت حرکتی و ورزشی',
                subtitle: 'ثبت تمرین، پیاده‌روی یا جلسه ورزشی',
                icon: Icons.fitness_center_rounded,
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).pop();
                  showMovementLogSheet(context);
                },
              ),
              _buildOptionTile(
                context,
                title: 'یادآور دارو',
                subtitle: 'ثبت زمان و دوز مصرف دارو',
                icon: Icons.medication_rounded,
                color: Colors.orange.shade800,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => MedicationFormSheet(
                      onFormCompleted: (_) {},
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: CalendarTokens.spacingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(CalendarTokens.spacingM),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CalendarTokens.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: CalendarTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: CalendarTokens.textLabel,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
