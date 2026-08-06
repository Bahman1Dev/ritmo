import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

Color domainColor(BuildContext context, AgendaDomain domain) {
  final modules = context.modules;
  switch (domain) {
    case AgendaDomain.routine:
      return modules.byModuleId('routines');
    case AgendaDomain.prayer:
    case AgendaDomain.mustahab:
    case AgendaDomain.worshipDebt:
      return modules.byModuleId('worship');
    case AgendaDomain.course:
    case AgendaDomain.konkur:
      return modules.byModuleId('study');
    case AgendaDomain.goalStep:
      return modules.byModuleId('goals');
    case AgendaDomain.cycle:
    case AgendaDomain.medicine:
      return modules.byModuleId('health');
    case AgendaDomain.sport:
      return modules.byModuleId('sports');
    case AgendaDomain.event:
      return modules.byModuleId('planner');
  }
}

Color domainContainerColor(BuildContext context, AgendaDomain domain) {
  final baseColor = domainColor(context, domain);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final alpha = isDark ? 0.16 : 0.10;
  return baseColor.withValues(alpha: alpha);
}

IconData domainIcon(AgendaDomain domain) {
  switch (domain) {
    case AgendaDomain.routine:
      return Icons.repeat_rounded;
    case AgendaDomain.prayer:
      return Icons.mosque_rounded;
    case AgendaDomain.mustahab:
      return Icons.auto_awesome_rounded;
    case AgendaDomain.worshipDebt:
      return Icons.history_edu_rounded;
    case AgendaDomain.course:
      return Icons.school_rounded;
    case AgendaDomain.konkur:
      return Icons.menu_book_rounded;
    case AgendaDomain.goalStep:
      return Icons.flag_rounded;
    case AgendaDomain.cycle:
      return Icons.water_drop_rounded;
    case AgendaDomain.sport:
      return Icons.fitness_center_rounded;
    case AgendaDomain.medicine:
      return Icons.medication_rounded;
    case AgendaDomain.event:
      return Icons.event_rounded;
  }
}

String domainLabelFa(AgendaDomain domain) {
  switch (domain) {
    case AgendaDomain.routine:
      return 'روتین';
    case AgendaDomain.prayer:
      return 'نماز';
    case AgendaDomain.mustahab:
      return 'مستحب';
    case AgendaDomain.worshipDebt:
      return 'قضا';
    case AgendaDomain.course:
      return 'دوره آموزشی';
    case AgendaDomain.konkur:
      return 'کنکور';
    case AgendaDomain.goalStep:
      return 'گام هدف';
    case AgendaDomain.cycle:
      return 'چرخهٔ سلامتی';
    case AgendaDomain.sport:
      return 'ورزش';
    case AgendaDomain.medicine:
      return 'دارو';
    case AgendaDomain.event:
      return 'رویداد';
  }
}
