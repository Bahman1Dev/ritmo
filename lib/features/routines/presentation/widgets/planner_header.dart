// lib/features/routines/presentation/widgets/planner_header.dart

import 'package:flutter/material.dart';
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
              Navigator.pop(context);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 22,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Title & Subtitle Centered
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.isEditing ? '✏️ ویرایش کار' : '✨ کار جدید',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.isEditing ? 'تغییر جزئیات این کار' : 'ایجاد مستقیم کار جدید در مسیر زندگی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textSecondary.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
