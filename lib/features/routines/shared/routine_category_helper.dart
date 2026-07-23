import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RoutineCategoryHelper {
  static String getCategoryTitle(String catId, Map<String, CustomCategory> customCategoriesMap) {
    if (catId.startsWith('custom_')) {
      return customCategoriesMap[catId]?.title ?? 'سفارشی';
    }
    switch (catId) {
      case 'religious': return 'عبادات';
      case 'medical': return 'داروها';
      case 'learning': return 'یادگیری';
      case 'fitness': return 'سلامت';
      case 'work': return 'کار و پروژه‌ها';
      case 'personal': return 'شخصی';
      case 'free': return 'آزاد';
      default: return catId;
    }
  }

  static IconData getCategoryIconData(String catId) {
    if (catId.startsWith('custom_')) {
      return Icons.label;
    }
    switch (catId) {
      case 'religious': return Icons.mosque;
      case 'medical': return CupertinoIcons.capsule_fill;
      case 'learning': return CupertinoIcons.book_fill;
      case 'fitness': return Icons.directions_run;
      case 'work': return CupertinoIcons.briefcase_fill;
      case 'personal': return CupertinoIcons.person_fill;
      case 'free': return CupertinoIcons.heart_fill;
      default: return Icons.circle;
    }
  }

  static Color getCategoryColor(BuildContext context, String catId, Map<String, CustomCategory> customCategoriesMap) {
    if (catId.startsWith('custom_')) {
      final hex = customCategoriesMap[catId]?.color;
      if (hex != null) {
        try {
          return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
        } catch (_) {}
      }
      return context.colors.primary;
    }
    final colors = context.colors;
    switch (catId) {
      case 'religious': return const Color(0xff9B89FF);
      case 'medical': return colors.medicalRed;
      case 'learning': return const Color(0xffA78BFA);
      case 'fitness': return colors.success;
      case 'work': return colors.primary;
      case 'personal': return colors.warning;
      case 'free': return const Color(0xff2DD4BF);
      default: return colors.textSecondary;
    }
  }

  static int calculateStreak(List<Map<String, dynamic>> completions) {
    if (completions.isEmpty) return 0;
    
    final dates = completions
        .map((c) => c['completionDate'] as String)
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    if (dates.first != todayStr && dates.first != yesterdayStr) {
      return 0;
    }

    var streak = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final current = DateTime.parse(dates[i]);
      final next = DateTime.parse(dates[i + 1]);
      final diff = current.difference(next).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  static bool isCategoryModuleEnabled(String category, Map<String, bool> activeModules) {
    if (category == 'religious' && !(activeModules['religion'] ?? false)) return false;
    if (category == 'medical' && !(activeModules['medicine'] ?? false)) return false;
    if (category == 'learning' && !(activeModules['courses'] ?? false)) return false;
    return true;
  }
}
