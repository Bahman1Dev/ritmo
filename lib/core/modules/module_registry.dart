import 'package:flutter/material.dart';

@immutable
class ModuleDescriptor {
  const ModuleDescriptor({
    required this.key,
    required this.titleFa,
    required this.oneLineFa,
    required this.icon,
    this.isCore = false,
    this.defaultEnabled = false,
    this.canBeSuggested = true,
  });

  final String key;
  final String titleFa;
  final String oneLineFa;
  final IconData icon;
  final bool isCore;
  final bool defaultEnabled;
  final bool canBeSuggested;
}

class ModuleRegistry {
  ModuleRegistry._();

  static const List<ModuleDescriptor> modules = [
    // Core Modules (Non-disableable)
    ModuleDescriptor(
      key: 'module_today_routines',
      titleFa: 'امروز و روتین‌ها',
      oneLineFa: 'مدیریت روتین‌ها و فعالیت‌های روزانه',
      icon: Icons.today_rounded,
      isCore: true,
      defaultEnabled: true,
      canBeSuggested: false,
    ),
    ModuleDescriptor(
      key: 'module_calendar_journey',
      titleFa: 'تقویم و سفر',
      oneLineFa: 'نمای خط زمانی و برنامه‌ریزی هفته و ماه',
      icon: Icons.calendar_month_rounded,
      isCore: true,
      defaultEnabled: true,
      canBeSuggested: false,
    ),

    // Optional Feature Modules
    ModuleDescriptor(
      key: 'module_assistant_enabled',
      titleFa: 'دستیار هوشمند',
      oneLineFa: 'همراه هوشمند محلی برای پیشنهادهای خودمراقبتی',
      icon: Icons.auto_awesome_rounded,
      defaultEnabled: true,
    ),
    ModuleDescriptor(
      key: 'module_goals_enabled',
      titleFa: 'اهداف و پیشرفت',
      oneLineFa: 'تعریف اهداف کلیدی و شکستن آن‌ها به گام‌های کوچک',
      icon: Icons.flag_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_study_enabled',
      titleFa: 'درس و مطالعه',
      oneLineFa: 'برنامهٔ مطالعه، سرفصل‌ها و مرور',
      icon: Icons.school_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_courses_enabled',
      titleFa: 'دوره‌های آموزشی',
      oneLineFa: 'مدیریت جلسات و پیشرفت دوره‌های یادگیری',
      icon: Icons.menu_book_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_religion_enabled',
      titleFa: 'عبادت و معنویت',
      oneLineFa: 'پیگیری نمازها، ادعیه و برنامه‌های معنوی',
      icon: Icons.mosque_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_sports_enabled',
      titleFa: 'ورزش و تحرک',
      oneLineFa: 'برنامهٔ تمرینی، فعالیت‌های بدنی و ثبت سلامتی',
      icon: Icons.fitness_center_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_medicine_enabled',
      titleFa: 'دارو و سلامت',
      oneLineFa: 'یادآوری مصرف داروها و پیگیری سلامتی',
      icon: Icons.medication_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_sleep_enabled',
      titleFa: 'خواب و ریتم شبانه‌روزی',
      oneLineFa: 'ثبت الگوی خواب و بهینه‌سازی ریتم زیستی',
      icon: Icons.bedtime_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_cycle_enabled',
      titleFa: 'چرخهٔ زیستی',
      oneLineFa: 'پیگیری حریم‌دار چرخهٔ قاعدگی و سلامتی بانوان',
      icon: Icons.water_drop_rounded,
      defaultEnabled: false,
      canBeSuggested: false, // Never auto-suggested (§2.2)
    ),
    ModuleDescriptor(
      key: 'module_energy_enabled',
      titleFa: 'تحلیل انرژی',
      oneLineFa: 'ارزیابی و تحلیل پنجره‌های اوج و فرود انرژی',
      icon: Icons.bolt_rounded,
      defaultEnabled: false,
    ),
    ModuleDescriptor(
      key: 'module_progressive_habits_enabled',
      titleFa: 'عادت‌های پیش‌رونده',
      oneLineFa: 'افزایش تدریجی و خودکار گام‌های روتین',
      icon: Icons.trending_up_rounded,
      defaultEnabled: false,
    ),
  ];

  static ModuleDescriptor? findByKey(String key) {
    for (final m in modules) {
      if (m.key == key) return m;
    }
    return null;
  }
}
