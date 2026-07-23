// lib/features/routines/presentation/widgets/planner_header.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerHeader extends StatelessWidget {

  const PlannerHeader({super.key, required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close/Back Button (Mockup placement: Left side)
          GestureDetector(
            onTap: () {
              if (controller.isEditing) {
                Navigator.pop(context);
              } else if (controller.currentPage > 0) {
                // Medical skips step 2 — going back from preview goes straight to category selection
                final prevPage = (controller.selectedCategory == Category.medical && controller.currentPage == 2)
                    ? 0
                    : controller.currentPage - 1;
                controller.updatePage(prevPage);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                (!controller.isEditing && controller.currentPage > 0) ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
                size: 20,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Title & Subtitle Centered (Mockup style)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.currentPage == 0
                      ? (controller.isEditing ? '✏️ ویرایش ایستگاه' : '✨ ایجاد ایستگاه جدید')
                      : (controller.currentPage == 1 ? '📅 زمان‌بندی' : (controller.isEditing ? '👁️ پیش‌نمایش ویرایش' : '👁️ پیش‌نمایش ایستگاه')),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.currentPage == 0
                      ? (controller.isEditing ? 'تغییر جزئیات این ایستگاه رشد' : 'چه چیزی می‌خواهی به مسیر زندگیت اضافه کنی؟')
                      : (controller.currentPage == 1 ? 'زمان مناسب را روی مسیر انتخاب کن' : (controller.isEditing ? 'تغییرات این ایستگاه روی مسیر اعمال می‌شود' : 'این ایستگاه در مسیر اضافه می‌شود')),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textSecondary.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
