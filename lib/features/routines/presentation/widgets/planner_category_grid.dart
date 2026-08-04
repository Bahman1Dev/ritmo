// lib/features/routines/presentation/widgets/planner_category_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerCategoryGrid extends StatelessWidget {

  const PlannerCategoryGrid({super.key, required this.controller});
  final PlannerController controller;

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'fitness':
        return '🏋️';
      case 'religious':
        return '🕌';
      case 'medical':
        return '💊';
      case 'learning':
        return '🎓';
      case 'free':
        return '📖';
      case 'custom':
        return '🎯';
      default:
        return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {'cat': Category.fitness, 'title': 'ورزش', 'icon': Icons.directions_run_rounded, 'color': const Color(0xff10B981)},
      {'cat': Category.religious, 'title': 'عبادت', 'icon': Icons.mosque_rounded, 'color': const Color(0xffFBBF24)},
      {'cat': Category.medical, 'title': 'دارو', 'icon': Icons.vaccines_rounded, 'color': const Color(0xff06B6D4)},
      {'cat': Category.free, 'title': 'مطالعه', 'icon': Icons.menu_book_rounded, 'color': const Color(0xff3B82F6)},
      {'cat': Category.personal, 'title': 'یادداشت', 'icon': Icons.note_alt_rounded, 'color': const Color(0xff8B5CF6), 'type': 'REFLECT'},
      {'cat': Category.learning, 'title': 'دوره', 'icon': Icons.school_rounded, 'color': const Color(0xff6366F1)},
      {'cat': Category.custom, 'title': 'هدف', 'icon': Icons.track_changes_rounded, 'color': const Color(0xffF97316)},
      {'cat': Category.personal, 'title': 'رویداد', 'icon': Icons.event_note_rounded, 'color': const Color(0xffEF4444), 'type': 'EVENT'},
      {'cat': Category.personal, 'title': 'یادآور ساده', 'icon': Icons.notifications_active_rounded, 'color': const Color(0xff6366F1), 'type': 'REMINDER'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Frequent Stations Quick-Add Row
            if (controller.frequentStations.isNotEmpty && !controller.isEditing && controller.inputController.text.trim().isEmpty) ...[
              Text(
                'ایستگاه‌های پرکاربرد اخیر',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.frequentStations.map((station) {
                    final sTitle = station['title'] as String;
                    final timeStr = station['timeOfDay'] as String;
                    final category = station['category'] as String;
                    
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        label: Text(
                          '${_getCategoryEmoji(category)} $sTitle ${toPersianDigits(timeStr)}',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textPrimary),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          controller.applyFrequentStation(station);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],

            Text(
              'انتخاب دسته‌بندی ایستگاه',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
            itemBuilder: (context, index) {
              final item = categories[index];
              final cat = item['cat']! as Category;
              final title = item['title']! as String;
              final icon = item['icon']! as IconData;
              final color = item['color']! as Color;
              final type = item['type'] as String?;

              var isEnabled = true;
              if (cat == Category.fitness) {
                isEnabled = controller.moduleSportsEnabled;
              } else if (cat == Category.religious) {
                isEnabled = controller.moduleReligionEnabled;
              } else if (cat == Category.medical) {
                isEnabled = controller.moduleMedicineEnabled;
              } else if (cat == Category.learning || cat == Category.free) {
                isEnabled = controller.moduleCoursesEnabled;
              } else if (cat == Category.custom) {
                isEnabled = controller.moduleGoalsEnabled;
              }

              final isSuggested = !controller.hasManuallySelectedCategory && 
                  controller.selectedCategory == cat && 
                  controller.title.trim().isNotEmpty;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.hasManuallySelectedCategory = true;
                  controller.selectCategory(cat, context, type: type);
                },
                child: Opacity(
                  opacity: isEnabled ? 1.0 : 0.55,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSuggested ? colors.goldAccent : color.withValues(alpha: 0.22),
                            width: isSuggested ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSuggested ? colors.goldAccent.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 40, color: color),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSuggested)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: colors.goldAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'پیشنهاد ✨',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (!isEnabled)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: colors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              controller.inputController.text = 'پیشنهاد با AI';
              controller.parseNLPText();
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xff8B5CF6).withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xff8B5CF6), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'پیشنهاد با AI',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
