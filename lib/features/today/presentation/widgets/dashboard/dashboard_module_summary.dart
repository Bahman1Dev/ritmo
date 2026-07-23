import 'package:flutter/widgets.dart';

/// خلاصهی یک ماژولِ فعال برای نمایش در گرید «سیستمهای فعال» داشبورد.
class DashboardModuleSummary { // مسیر دارایی تصویر پس‌زمینه (اختیاری)

  const DashboardModuleSummary({
    required this.moduleId,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.primary,
    required this.secondary,
    this.backgroundImage,
  });
  final String moduleId;   // 'sleep','sports','energy','medicine','worship','cycle','goals','courses','konkur'
  final String title;
  final IconData icon;
  final Color accentColor;
  final String primary;    // متریک اصلی — از قبل با ارقام فارسی
  final String secondary;  // متریک فرعی — از قبل با ارقام فارسی
  final String? backgroundImage;
}
