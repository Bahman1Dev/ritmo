// lib/features/routines/presentation/widgets/planner_advanced_section.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerAdvancedSection extends StatelessWidget {

  const PlannerAdvancedSection({super.key, required this.controller});
  final PlannerController controller;

  Widget _buildPrioritySegment(double value, String label, RitmoColors colors) {
    final isSelected = controller.priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.priority = value;
          controller.notifyListeners();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
  Widget _buildCogSegment(String? value, String label, RitmoColors colors) {
    final isSelected = controller.cognitiveLoad == value;
    return GestureDetector(
      onTap: () {
        controller.cognitiveLoad = value;
        controller.notifyListeners();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              controller.isAdvancedExpanded = !controller.isAdvancedExpanded;
              controller.notifyListeners();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تنظیمات پیشرفته',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  AnimatedRotation(
                    turns: controller.isAdvancedExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: controller.description,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'توضیحات یا یادداشت‌ها',
                      labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) => controller.description = val,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'اولویت',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPrioritySegment(0.5, 'پایین', colors),
                      const SizedBox(width: 8),
                      _buildPrioritySegment(1, 'متوسط', colors),
                      const SizedBox(width: 8),
                      _buildPrioritySegment(1.5, 'بالا', colors),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نوع بار شناختی (برای مسیریابی زمان)',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCogSegment(null, 'خالی', colors),
                        const SizedBox(width: 6),
                        _buildCogSegment('ANALYTICAL', 'تحلیلی', colors),
                        const SizedBox(width: 6),
                        _buildCogSegment('ADMINISTRATIVE', 'اداری', colors),
                        const SizedBox(width: 6),
                        _buildCogSegment('CREATIVE', 'خلاق', colors),
                        const SizedBox(width: 6),
                        _buildCogSegment('PHYSICAL', 'بدنی', colors),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: controller.isAdvancedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
