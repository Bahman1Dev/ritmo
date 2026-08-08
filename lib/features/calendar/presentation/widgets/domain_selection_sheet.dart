import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_time_range.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';
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
    required this.presetTime,
    required this.dateStr,
    required this.onCreated,
  });

  final TimeOfDay presetTime;
  final String dateStr;
  final VoidCallback onCreated;

  static void show(
    BuildContext context, {
    required TimeOfDay presetTime,
    required String dateStr,
    required VoidCallback onCreated,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DomainSelectionSheet(
        presetTime: presetTime,
        dateStr: dateStr,
        onCreated: onCreated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalMinutes = (presetTime.hour * 60) + presetTime.minute;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
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
                      color: colors.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_task_rounded, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: CalendarTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'افزودن برنامه جدید',
                          style: RitmoTextStyles.cardTitle(colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'زمان انتخابی: ',
                              style: RitmoTextStyles.caption(colors.textSecondary),
                            ),
                            RitmoTimeRange(
                              startMinutes: totalMinutes,
                              style: RitmoTextStyles.caption(colors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: CalendarTokens.spacingM),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: CalendarTokens.spacingM),
              _buildOptionTile(
                context,
                title: 'روتین جدید',
                subtitle: 'ثبت عادت، وظیفه روزانه یا روتین جدید',
                icon: Icons.repeat_rounded,
                color: colors.primary,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => UniversalPlannerSheet(
                      onSaved: () {
                        DayAgendaService.instance.invalidateDate(dateStr);
                        onCreated();
                      },
                      prefilledTime: presetTime,
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'جلسهٔ دوره آموزشی',
                subtitle: 'ثبت جلسه مطالعه یا تمرین برای دوره فعال',
                icon: Icons.school_rounded,
                color: colors.accent,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CreateCourseSheet(
                      onCourseCreated: () {
                        DayAgendaService.instance.invalidateDate(dateStr);
                        onCreated();
                      },
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'گام هدف',
                subtitle: 'افزودن گام اجرایی برای اهداف فعال',
                icon: Icons.flag_rounded,
                color: colors.primary,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CreateGoalSheet(
                      activeGoals: const [],
                      routines: const [],
                      onSaved: () {
                        DayAgendaService.instance.invalidateDate(dateStr);
                        onCreated();
                      },
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                title: 'مطالعهٔ کنکور',
                subtitle: 'برنامه‌ریزی و ثبت پارت مطالعه درس کنکور',
                icon: Icons.menu_book_rounded,
                color: colors.warning,
                onTap: () async {
                  Navigator.of(context).pop();
                  final subjects = await KonkurRepository.instance.getSubjects();
                  final topics = await KonkurRepository.instance.getTopics();
                  if (context.mounted) {
                    unawaited(
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => KonkurStudySheet(
                          subjects: subjects,
                          topics: topics,
                          onSaved: () {
                            DayAgendaService.instance.invalidateDate(dateStr);
                            onCreated();
                          },
                        ),
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
                color: colors.success,
                onTap: () async {
                  Navigator.of(context).pop();
                  await showMovementLogSheet(context);
                  DayAgendaService.instance.invalidateDate(dateStr);
                  onCreated();
                },
              ),
              _buildOptionTile(
                context,
                title: 'مصرف دارو',
                subtitle: 'ثبت نوبت یادآوری یا مصرف داروی جدید',
                icon: Icons.medication_rounded,
                color: colors.cautionAccent,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => MedicationFormSheet(
                      onFormCompleted: (_) {
                        DayAgendaService.instance.invalidateDate(dateStr);
                        onCreated();
                      },
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
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: CalendarTokens.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          child: Container(
            padding: const EdgeInsets.all(CalendarTokens.spacingM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CalendarTokens.spacingS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: CalendarTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: RitmoTextStyles.label(colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: RitmoTextStyles.caption(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
