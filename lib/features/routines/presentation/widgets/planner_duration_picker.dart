// lib/features/routines/presentation/widgets/planner_duration_picker.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerDurationPicker extends StatelessWidget {

  const PlannerDurationPicker({super.key, required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مدت فعالیت',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 24),
                      onPressed: () => controller.adjustDuration(-15),
                      color: colors.primary,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${toPersianDigits(controller.targetDuration.toString())} دقیقه',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                      onPressed: () => controller.adjustDuration(15),
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preset chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...[15, 30, 45, 60, 90, 120].map((mins) {
                  final isSelected = controller.targetDuration == mins;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${toPersianDigits(mins.toString())} دقیقه',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: isSelected ? Colors.white : colors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      onSelected: (val) {
                        if (val) {
                          controller.targetDuration = mins;
                          controller.notifyListeners();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          if (controller.aiEstimatedDuration != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  controller.targetDuration = controller.aiEstimatedDuration!;
                  controller.notifyListeners();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xff8B5CF6), size: 15),
                      const SizedBox(width: 8),
                      Text(
                        '⚡ پیشنهاد هوشمند: ${toPersianDigits(controller.aiEstimatedDuration.toString())} دقیقه',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
